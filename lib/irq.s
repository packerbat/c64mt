;----------------------
; Przerwanie może być generowane przez:
;   1. CIA#1 IRQ out line
;      a) licznik A doliczył do zera
;      b) licznik B doliczył od zera
;      c) TOD wygenerował ALARM
;      d) Serial Port umieścił odebrany bajt w SDR albo Serial Port "wypchnął" cały bajt na linię DATA
;      e) na wejściu FLAG pojawiło się opadające zbocze (SRQ IN w SERIALBUS lub Cassete Read).
;   2. VIC-II IRQ out line
;   3. przerwanie od instrukcji BRK
;
; Timer A jest użyty do przełączania zadań (o ile są włączone)
;
; Jeśli są dwa zadania (lub więcej) to ta procedura obsługi przerwania IRQ niszczy na stosie
; ewntualny adres powrotu z obsługi przerwania IRQ lub NMI, które zdarzyło się chwilę wcześniej
; ale jego obsługa się jeszcze nie zakończyła. Z tego względu NMI nie jest dobrym pomysłem na
; przełączanie zadań bo może wypaść w połowie obsługi przerwania IRQ. Teoretycznie można by
; zrobić przełączanie zadań w NMI ale trzeba by zadbać, żeby przerwanie od zegara CIA#2
; (który generuje NMI) było w tym czasie zamaskowane.
;
; Przerwanie NMI ma prawo się zdarzyć w trakcie przełączania zadania i niczym to nie grozi.

.include "globals.inc"

.export IRQ, CIA1IRQMask, CIA1IRQState, VICIRQMask, VICIRQState, JiffyClock
.export CURRTASK, TASK_REGPCL, TASK_REGPCH, TASK_REGA, TASK_REGX, TASK_REGY, TASK_REGPS, TASK_REGSP, TASK_STATE
.import COLDSTART

.segment "DATA"
CIA1IRQMask:   .byte $7F        ;wstaw 0 do wszytkich masek przerwania CIA#2
CIA1IRQState:  .byte 0          ;ostatnie przyczyny IRQ w CIA#2
VICIRQMask:    .byte 0          ;wstaw 0 do wszytkich masek przerwania VIC-II
VICIRQState:   .byte 0          ;ostatnie przyczyny IRQ w VIC-II

.segment "DATA"
TASK_REGPCL:  .res MAXTASKS,0
TASK_REGPCH:  .res MAXTASKS,0
TASK_REGA:    .res MAXTASKS,0
TASK_REGX:    .res MAXTASKS,0
TASK_REGY:    .res MAXTASKS,0
TASK_REGPS:   .res MAXTASKS,0
TASK_REGSP:   .res MAXTASKS,$FF
TASK_STATE:   .byte $80           ; STATE: b7=1 active, b7=0 empty, zerowe zadanie nigdy nie może być puste i nie można go zakończyć
              .res MAXTASKS-1,0
CURRTASK:     .byte 0             ;numer bieżącego zadania w zakresie 0..3 (na razie)


.segment "BSS"
JiffyClock:    .res 4           ;32-bitowy licznik przerwań IRQ

.segment "CODE"

.proc IRQ
    sei                ; dzięki temu IRQ nie przerwie obecnego IRQ
    pha                ; save A

    lda $D019               ; get source of interrupts in VIC-II
    bpl moze_przerwanie_od_CIA1

przerwanie_od_VICII:
    sta VICIRQState
    ;txa                ; copy X
    ;pha                ; save X
    ;tya                ; copy Y
    ;pha                ; save Y

    ; tu można zrobić obsługę przerwania od VIC-II z zablokowanymi przerwaniami VIC-II, przerwania VIC_II odblokuje dobiero wpisanie 0 do $D019

    ;pla                ; pull Y
    ;tay                ; restore Y
    ;pla                ; pull X
    ;tax                ; restore X
    lda #0
    sta $D019           ; manual IRQ flag clear

moze_przerwanie_od_CIA1:
    lda $DC0D                ; get source of interrupts in CIA#2 and clear interrupts flags
    bmi przerwanie_od_CIA1
    
    ; nie znana przyczyna przerwania będzie kwitowana COLD START-em
    jmp COLDSTART

przerwanie_od_CIA1:
    sta CIA1IRQState
    ;lda #$7F
    ;sta $DC0D          ; dzięki temu CIA#1 nie spowoduje przerwania IRQ w trakcie obsługi IRQ

    ; tu można zrobić obsługę przerwania CIA#1 z zablokowanymi przerwaniami IRQ i CIA#2
    inc JiffyClock
    bne :+
    inc JiffyClock+1
    bne :+
    inc JiffyClock+2
    bne :+
    inc JiffyClock+3

:   inc $6000
    ;inc $6401
    ;inc $6002
    ;inc $A003

    ; --- spawdzam czy w ogóle przełączanie zdań jest potrzebne
    txa
    pha

    lda TASK_STATE+(MAXTASKS-1)
    ldx #MAXTASKS-2
:   ora TASK_STATE,x
    dex
    bne :-
    and #$80
    bne sa_inne_zadania
    pla                 ;nie ma zadań 1..6, jest tylko 0, które jest zawsze włączone
    tax
    ;lda CIA1IRQMask
    ;sta $DC0D          ; restore CIA#1 IRQ Mask
    pla
    rti

sa_inne_zadania:
    tya
    pha
    tsx         ;Y=$101,x  X=$102,x  A=$103,x  PS=$104,x  PCL=$105,x  PCH=$106,x

    ; --- zapamiętanie starego zadania
    ldy CURRTASK
    lda $105,x          ; pobranie PCL
    sta TASK_REGPCL,y
    lda $106,x          ; pobranie PCH
    sta TASK_REGPCH,y
    lda $103,x          ; pobranie A
    sta TASK_REGA,y
    lda $102,x          ; pobranie X
    sta TASK_REGX,y
    lda $101,x          ; pobranie Y
    sta TASK_REGY,y
    lda $104,x          ; pobranie PS
    sta TASK_REGPS,y
    txa
    clc
    adc #6
    sta TASK_REGSP,y    ; SP wskazuje na adres przed skokiem dlatego podnoszę o 6

    ; --- zwolnienie miejsca na stosie
    ; tu mogłoby być 6 x PLA ale to zajmuje aż 24 cykle a poniższe rozwiązanie zajmujące też 6 bajtów - tylko 10 cykli
    txa
    clc
    adc #6          ;A, X, Y, PS, PC
    tax
    txs

    ; --- przełączenie zadań
    ; Z wcześniejszego testu wiem, że mam conajmniej 2 niepuste sloty
:   iny
    cpy #MAXTASKS
    bcc :+
    ldy #0
:   lda TASK_STATE,y
    bpl :--

    ; --- uruchomienie nowego zdania, Y = numer nowego zadania
    ldx TASK_REGSP,y
    txs                 ;od tej pory działamy na stosie nowego zadania
    lda TASK_REGPCH,y
    pha
    lda TASK_REGPCL,y
    pha
    lda TASK_REGPS,y
    pha
    lda TASK_REGA,y     ;tu muszę użyć stosu bo inaczej nie odczytam A
    pha
    ldx TASK_REGX,y
    lda TASK_REGY,y
    sty CURRTASK
    tay
    ;lda CIA1IRQMask
    ;sta $DC0D          ; restore CIA#1 IRQ Mask
    pla                 ; restore A
    rti
.endproc