;---------------------------------------------------------- 
; sekwencja inicjująca rozszerzenie basica

.export INITT, START_MULTITASKING, TSACTIVE
.import NRM, TXTPAGE, CLST, CIA2IRQMask, CIA1IRQMask, VICIRQMask, IRQ, NMI, COLDSTART
.import CURRTASK, TASK_REGPCL, TASK_REGPCH, TASK_REGA, TASK_REGX, TASK_REGY, TASK_REGPS, TASK_REGSP, TASK_STATE

.segment "DATA"
IRQPRESC:   .byte 30
TSACTIVE:   .byte 0

.segment "ZEROPAGE":zeropage
SRCPTR:   .res 2
DSTPTR:   .res 2

.segment "CODE"
.proc INITT
    sei
    lda #0
    sta CURRTASK        ;po przenieseniu do DATA już nie jest potrzebne ale niech zostanie
    lda #$7F
    sta CIA2IRQMask
    sta $DD0D
    sta CIA1IRQMask
    sta $DC0D
    lda #0
    sta VICIRQMask
    sta $D01A        ; disable all VIC-II interrupts

    lda #$33         ;turn on CHARACTER ROM at address $D000-DFFF
    sta $01
    lda #$D8
    ldy #$40
    ldx #16          ;=2KB
    jsr copy_pages
    lda #$35         ;turn off KERNAL ROM and BASIC ROM and CHRACTER ROM, do not remove I/O at $D000-$DFFF
    sta $01
    lda #<NMI
    sta $FFFA        ;Hardware NMI Interrupt Vector
    lda #>NMI
    sta $FFFB
    lda #<COLDSTART
    sta $FFFC        ;Hardware COLD START Vector
    lda #>COLDSTART
    sta $FFFD
    lda #<IRQ
    sta $FFFE        ;Hardware IRQ Interrupt Vector
    lda #>IRQ
    sta $FFFF
    cli

    lda #$08
    sta $DC0E     ; CIA#1 Control Register, TOD 60Hz, Serial Port input, Timer A system clock, no force load timer A, timer A one shot, Timer A on PB6 Pulse, Timer A disabled on PB6, Timer A stop
    sta $DD0E     ; CIA#2 Control Register, TOD 60Hz, Serial Port input, Timer A system clock, no force load timer A, timer A one shot, Timer A on PB6 Pulse, Timer A disabled on PB6, Timer A stop
    sta $DC0F     ; CIA#1 Control Register, TOD in clock mode, Timer B system clock, no force load timer B, timer B one shot, Timer B on PB7 Pulse, Timer B disabled on PB7, Timer B stop
    sta $DD0F     ; CIA#2 Control Register, TOD in clock mode, Timer B system clock, no force load timer B, timer B one shot, Timer B on PB7 Pulse, Timer B disabled on PB7, Timer B stop
    sta $D016     ; VIC Control Register: multi-color disabled, 40 column, scroll X=0
    ldx #$00
    stx $DC03     ; CIA#1 Port B all input
    stx $DD03     ; CIA#2 Port B all input
    stx $D418     ; SID all filters off, master volume mute
    sta $D015     ; disable all sprites
    dex           ; X=$FF
    sta $DC00     ; keyboar column $FF=none 
    stx $DC02     ; CIA#1 Port A all output
    lda #$07
    sta $DD00     ; CIA#2 Data Port A, disk serial bus all 0, VIC bank 0, PA2 out=1
    lda #$3F
    sta $DD02     ; CIA@2 Port A Direction: Serial data input i serial bus clock na input, reszta na output.

    lda #$95      ; PAL=$4025 dla NTSC=$4295  - to jest 60 Hz
    sta $DC04     ; CIA#1 Timer A  (Kernal-IRQ, Tape)
    lda #$42
    sta $DC05

    lda #$81
    sta CIA1IRQMask
    sta $DC0D     ; CIA#1, enable Timer A interrupt
    lda $DC0E     ; CIA#1: Control Register A
    and #$80      ; zostaw tylko TOD freq.
    ora #$11      ; ustaw: force reload Timer A i start Time A
    sta $DC0E     ; CIA#1: Control Register A
    lda $DD00     ; CIA#2: Data Port A (Serial Bus, RS232, VIC Base Mem.)
    ora #$10      ; Serial Bus Clock Pulse Output = 1
    sta $DD00 

    lda #$64
    sta TXTPAGE
    lda #$FE          ;domyślne kolory C64 po włączeniu
    jsr CLST
    lda #$60
    sta TXTPAGE
    lda #$FE          ;domyślne kolory C64 po włączeniu
    jsr CLST

    jsr NRM

    rts
.endproc

;----------------------------
; Copy X pages pointed by A to pages pointed by Y
; modified: A,X,Y,P,SRCPTR,DSTPTR
;
.proc copy_pages
    sta SRCPTR+1
    sty DSTPTR+1
    ldy #0              ;niepotrzebne ciągłe ustawianie
    sty SRCPTR
    sty DSTPTR

:   lda (SRCPTR),y
    sta (DSTPTR),y
    dey
    bne :-
    inc SRCPTR+1
    inc DSTPTR+1
    dex
    bne :-
    rts
.endproc

;----------------------------
; A=hi,X=lo = adres kontynuacji zadania 1 (tak na prawdę to początku zadania)
; Ta procedura udaje przełączanie zadań podobne jak w NMI tylko, że na stosie jest
; jedynie adres powrotu, który tu jest nazywany adresem kontynuacji zadania.
; trzeba zapamiętać stan procesora w bieżącym deskrytorze (czyli 0)
; a następnie zainicjować deskryptor nowego zadania
; po zainicjowaniu nowego zadania robimy skok do nowego zadania (czyli 1), a NMI
; je potem przerwie i wznowi zadanie 0.
;
; adres kontynuacji zadania 0 jest dostępny jako lda $105,x (low) i lda $106,x (hi)
; adres kontynuacji zadania 1 jest dostępny jako lda $102,x (low) i lda $103,x (hi)
;
; Ta procedura uruchomi także 32-bitowy zegar przydzielający kwanty czasu
; poszczególnym zadanim (CIA#2 Timer A i CIA#2 Timer B)

.proc START_MULTITASKING
    php                 ; PS dostępne jako lda $104,x
    pha                 ; A dostępne jako lda $103,x
    txa
    pha                 ; X dostępne jako lda $102,x
    tya
    pha                 ; Y dostępne jako lda $101,x
    tsx

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
    lda #$80
    sta TASK_STATE,y    ; deskryptor 0 nie jest pusty

    ; --- zapamiętanie nowego zadania
    iny
    lda $102,x          ; pobranie PCL
    sta TASK_REGPCL,y
    lda $103,x          ; pobranie PCH
    sta TASK_REGPCH,y
    lda #0              ; rejestry A, X, Y będą 0 na starcie
    sta TASK_REGA,y
    sta TASK_REGX,y
    sta TASK_REGY,y
    lda $104,x          ; PS będzie równe staremu zadaniu
    sta TASK_REGPS,y
    lda #($FF-$40)      ; zadanie 0 jest uprzywilejowane i dostaje większy stos (64 bajty)
    sta TASK_REGSP,y    ; pozostałe zadania (max 6 sztuk) dostaną po 32 bajty
    lda #$80
    sta TASK_STATE,y    ; deskryptor 1 nie jest pusty

    ; --- zwolnienie miejsca na stosie
    txa
    clc
    adc #6          ;A, X, Y, PS, PC
    tax
    txs

    ; uruchomienie nowego zdania, Y = numer nowego zadania (czyli 1)
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
    lda #1
    sta TSACTIVE
    pla
    rti
.endproc

.proc INIT_NMI_TIMER
    ; --- ten fragment nie niszczy rejestru Y
    lda #$95      ; 1 sekunda dla NTSC to 1022700=$000F9AEC, 60 razy na sekundę $4295
    sta $DD04     ; CIA#1 Timer A
    lda #$00
    sta $DD05
    lda #$42
    sta $DD06     ; CIA#2 Timer B
    lda #$00
    sta $DD07
    lda #$82
    sta CIA2IRQMask
    sta $DD0D     ; CIA#2, enable Timer B interrupt
    lda $DD0E     ; CIA#2: Control Register A
    and #$80      ; zostaw tylko TOD freq.
    ora #$11      ; ustaw: force reload Timer A i start Time A, Continuous
    sta $DD0E     ; CIA#2: Control Register A
    lda $DD0F     ; CIA#2: Control Register A
    and #$80      ; zostaw tylko Alarm/TOD mode
    ora #$51      ; ustaw: Count Timer A Underflow Pulses, force reload Timer A i start Time A, Continuous
    sta $DD0F     ; CIA#2: Control Register A
    rts
.endproc
