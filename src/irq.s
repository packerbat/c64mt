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

.include "../lib/globals.inc"

.export IRQ, CIA1IRQMask, CIA1IRQState, VICIRQMask, VICIRQState, JiffyClock
.import COLDSTART

.segment "DATA"
CIA1IRQMask:   .byte $7F        ;wstaw 0 do wszytkich masek przerwania CIA#2
CIA1IRQState:  .byte 0          ;ostatnie przyczyny IRQ w CIA#2
VICIRQMask:    .byte 0          ;wstaw 0 do wszytkich masek przerwania VIC-II
VICIRQState:   .byte 0          ;ostatnie przyczyny IRQ w VIC-II

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

    lda $6001
    clc
    adc #1
    and #63
    sta $6001
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
    inc JiffyClock+1     ; na razie nie używam dlatego zakomentowane
    bne :+
    inc JiffyClock+2
    bne :+
    inc JiffyClock+3

:   lda $6000
    clc
    adc #1
    and #63
    sta $6000
    ;inc $6401
    ;inc $6002
    ;inc $A003

    pla                ; restore A
    rti
.endproc