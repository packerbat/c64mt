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

.include "../../lib/globals.inc"

.export IRQ, CIA1IRQMask, CIA1IRQState, VICIRQMask, VICIRQState, JiffyClock, EVENTS
.export CURRTASK, TASK_REGPCL, TASK_REGPCH, TASK_REGA, TASK_REGX, TASK_REGY, TASK_REGPS, TASK_REGSP, TASK_STATE, TASK_EVENTS
.import COLDSTART, TIMERS_RELOAD, TIMERS, NEWKEYS, LASTKEYS

.segment "DATA"
CIA1IRQMask:   .byte $7F        ;wstaw 0 do wszytkich masek przerwania CIA#2
CIA1IRQState:  .byte 0          ;ostatnie przyczyny IRQ w CIA#2
VICIRQMask:    .byte 0          ;wstaw 0 do wszytkich masek przerwania VIC-II
VICIRQState:   .byte 0          ;ostatnie przyczyny IRQ w VIC-II
EVENTS:        .byte 0          ;b0-raster, b1-sprite to background, b2-sprite to sprite, b3-keyboard, b4-timer 1, b5-timer 2, b6-timer 3, b7-timer 4
EVENTSMask:    .byte 0          ;ostatnie przyczyny IRQ w VIC-II

TASK_REGPCL:  .res MAXTASKS,0
TASK_REGPCH:  .res MAXTASKS,0
TASK_REGA:    .res MAXTASKS,0
TASK_REGX:    .res MAXTASKS,0
TASK_REGY:    .res MAXTASKS,0
TASK_REGPS:   .res MAXTASKS,0
TASK_REGSP:   .res MAXTASKS,$FF
TASK_STATE:   .byte $80           ; STATE: b7=1 active, b7=0 empty, zerowe zadanie nigdy nie może być puste i nie można go zakończyć
              .res MAXTASKS-1,0   ;        b6=1 request for stop
                                  ;        b5=1 task terminated
TASK_EVENTS:  .res MAXTASKS,0     ;watość różna od 0 oznacza, że proces jest zawieszony do czasu zajścia wskazanych tu zdarzeń

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

    ; --- analiza trzech rodzajów przerwań i ustawienie flags w Events
    lda #1
    bit VICIRQState
    beq :+
    ora EVENTS
    sta EVENTS

:   lda #2
    bit VICIRQState
    beq :+
    ora EVENTS
    sta EVENTS

:   lda #4
    bit VICIRQState
    beq :+
    ora EVENTS
    sta EVENTS

    ; --- zwiększenie licznika na pasku stanu
:   lda $6001
    clc
    adc #1
    and #63
    sta $6001
    ; tu można zrobić obsługę przerwania od VIC-II z zablokowanymi przerwaniami VIC-II, przerwania VIC_II odblokuje dobiero wpisanie 0 do $D019

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
;    bne :+
;    inc JiffyClock+1     ; na razie nie używam dlatego zakomentowane
;    bne :+
;    inc JiffyClock+2
;    bne :+
;    inc JiffyClock+3
;:

    lda TIMERS_RELOAD
    beq :+
    dec TIMERS
    bne :+
    sta TIMERS
    lda #$10
    ora EVENTS
    sta EVENTS
    lda $6002
    clc
    adc #1
    and #63
    sta $6002

:   lda TIMERS_RELOAD+1
    beq :+
    dec TIMERS+1
    bne :+
    sta TIMERS+1
    lda #$20
    ora EVENTS
    sta EVENTS
    lda $6003
    clc
    adc #1
    and #63
    sta $6003

:   lda TIMERS_RELOAD+2
    beq :+
    dec TIMERS+2
    bne :+
    sta TIMERS+2
    lda #$40
    ora EVENTS
    sta EVENTS
    lda $6004
    clc
    adc #1
    and #63
    sta $6004

:   lda TIMERS_RELOAD+3
    beq :+
    dec TIMERS+3
    bne :+
    sta TIMERS+3
    lda #$80
    ora EVENTS
    sta EVENTS
    lda $6005
    clc
    adc #1
    and #63
    sta $6005

    ; --- zapamiętanie starego stanu klawiatury
:   lda NEWKEYS+0
    sta LASTKEYS+0
    lda NEWKEYS+1
    sta LASTKEYS+1
    lda NEWKEYS+2
    sta LASTKEYS+2
    lda NEWKEYS+3
    sta LASTKEYS+3
    lda NEWKEYS+4
    sta LASTKEYS+4
    lda NEWKEYS+5
    sta LASTKEYS+5
    lda NEWKEYS+6
    sta LASTKEYS+6
    lda NEWKEYS+7
    sta LASTKEYS+7

    ; --- skanowanie poszczególnych wierszy i kolumna klawiatury
    lda #$FE
    sta $DC00
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta NEWKEYS+0

    lda #$FD
    sta $DC00
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta NEWKEYS+1

    lda #$FB
    sta $DC00
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta NEWKEYS+2

    lda #$F7
    sta $DC00
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta NEWKEYS+3

    lda #$EF
    sta $DC00
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta NEWKEYS+4

    lda #$DF
    sta $DC00
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta NEWKEYS+5

    lda #$BF
    sta $DC00
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta NEWKEYS+6

    lda #$7F
    sta $DC00
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta NEWKEYS+7

    lda #$FF
    sta $DC00                  ;wyłączenie wszystkich wierszy

    ; --- ustawienie flagi w Events jeśli były zmiany
    lda NEWKEYS+0
    cmp LASTKEYS+0
    bne :+
    lda NEWKEYS+1
    cmp LASTKEYS+1
    bne :+
    lda NEWKEYS+2
    cmp LASTKEYS+2
    bne :+
    lda NEWKEYS+3
    cmp LASTKEYS+3
    bne :+
    lda NEWKEYS+4
    cmp LASTKEYS+4
    bne :+
    lda NEWKEYS+5
    cmp LASTKEYS+5
    bne :+
    lda NEWKEYS+6
    cmp LASTKEYS+6
    bne :+
    lda NEWKEYS+7
    cmp LASTKEYS+7
    beq :++
:   lda #$08
    ora EVENTS
    sta EVENTS

    ; --- zwiększenie licznika na pasku stanu
:   lda $6000
    clc
    adc #1
    and #63
    sta $6000

    txa
    pha
    tya
    pha

    ; --- najpierw zamykam zadania, które potwierdziły swóje zamknięcie
    ldy #MAXTASKS-1
:   lda TASK_STATE,y
    bpl :+              ;pomijam puste sloty
    and #$20
    beq :+
    lda #0
    sta TASK_STATE,y
:   dey
    bne :--

    ; --- poszukiwanie zdania, które czeka na zdarzenia (nie pomijam T0 żeby wyjść z pętli ale je ignoruję)
    ldy CURRTASK
:   iny
    cpy #MAXTASKS
    bcc :+
    ldy #0
:   cpy CURRTASK
    beq :+              ;wróciłem do CURRTASK i nic nie znalazłem czyli koniec poszukiwania
    lda TASK_STATE,y
    bpl :--             ;pomijam puste sloty
    lda TASK_EVENTS,y
    beq :--             ;to zadanie pomijam bo nie czeka w SELECT
    and EVENTS
    beq :--
    sta TASK_REGA,y     ; A = tylko zdarzenia, na które czekał ten proces bo to jest pobudka z SELECT
    eor EVENTS          ; w EVENTS neguję bit, który się zdarzył
    sta EVENTS
    lda #0
    sta TASK_EVENTS,y   ; ale TASK_EVENTS zeruję całe bo już nie jestem w SELECT
    jmp activate_task_in_y

    ; --- teraz szukam zadania aktywnego (pomijam T0)
:   cpy #0
    beq activate_task_in_y      ;byłem w IDLE i żadne zadanie się nie doczekało na zdarzenie więc wracam do IDLE
    ldy CURRTASK
:   iny
    cpy #MAXTASKS
    bcc :+
    ldy #1
:   cpy CURRTASK
    beq :+
    lda TASK_STATE,y
    bpl :--
    lda TASK_EVENTS,y
    bne :--                 ;to zadanie na coś czeka w SELECT więc nie jest aktywne
    beq activate_task_in_y

    ; --- nie znalazłem więc skacze do IDLE (to chyba można w przyszłości uprościć)
:   ldy #0

activate_task_in_y:
    cpy CURRTASK
    bne :+              ;czy zmiana zadania jest konieczna
    pla
    tay
    pla
    tax
    pla
    rti

    ; --- zapamiętanie starego zadania
:   lda CURRTASK
    sty CURRTASK
    tay
    tsx                 ;Y=$101,x  X=$102,x  A=$103,x  PS=$104,x  PCL=$105,x  PCH=$106,x
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

    ; --- wznowienie znalezionego zdania
    ldy CURRTASK
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
    tay
    ;lda CIA1IRQMask
    ;sta $DC0D          ; restore CIA#1 IRQ Mask
    pla                 ; restore A
    rti
.endproc
