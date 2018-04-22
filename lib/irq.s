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

.export IRQ, CIA1IRQMask, CIA1IRQState, VICIRQMask, VICIRQState, JiffyClock
.export CURRTASK, TASK_REGPCL, TASK_REGPCH, TASK_REGA, TASK_REGX, TASK_REGY, TASK_REGPS, TASK_REGSP, TASK_STATE
.import COLDSTART, TSACTIVE

.segment "DATA"
CIA1IRQMask:   .byte $7F        ;wstaw 0 do wszytkich masek przerwania CIA#2
CIA1IRQState:  .byte 0          ;ostatnie przyczyny IRQ w CIA#2
VICIRQMask:    .byte 0          ;wstaw 0 do wszytkich masek przerwania VIC-II
VICIRQState:   .byte 0          ;ostatnie przyczyny IRQ w VIC-II

.segment "DATA"
TASK_REGPCL:  .byte 0,0,0,0     ;na razie dopuszczam tylko 4 jednoczesne zadania
TASK_REGPCH:  .byte 0,0,0,0
TASK_REGA:    .byte 0,0,0,0
TASK_REGX:    .byte 0,0,0,0
TASK_REGY:    .byte 0,0,0,0
TASK_REGPS:   .byte 0,0,0,0
TASK_REGSP:   .byte 0,0,0,0
TASK_STATE:   .byte 0,0,0,0     ; STATE: b7=1 active, b7=0 empty
CURRTASK:     .byte 0           ;numer bieżącego zadania w zakresie 0..3 (na razie)


.segment "BSS"
JiffyClock:    .res 4           ;32-bitowy licznik przerwań IRQ

.segment "CODE"

.proc IRQ
    sei                ; dzięki temu IRQ nie przerwie NMI
    pha                ; save A
    lda $DC0D                ; get source of interrupts in CIA#2 and clear interrupts flags
    bmi przerwanie_od_CIA1
    
    lda $D019               ; get source of interrupts in VIC-II
    bmi przerwanie_od_VICII

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

    lda TSACTIVE
    beq :+
    txa
    pha
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
    txa
    clc
    adc #6          ;A, X, Y, PS, PC
    tax
    txs             ;zajmuje tyle samo bajtów co 6xPLA ale jest zajmuje 10 cykli a nie 24 cykle

    ; --- przełączenie zadań
    tya
    eor #1              ;na razie przełączam się tylko miedzy zadaniem 1 a 0
    tay

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

:   ;lda CIA1IRQMask
    ;sta $DC0D          ; restore CIA#1 IRQ Mask
    pla                 ; restore A
    rti

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
    pla
    rti
.endproc