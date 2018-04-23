;---------------------------------------------------------- 
; sekwencja inicjująca rozszerzenie basica

.export INITT
.import NRM, TXTPAGE, CLST, FILLCT, CIA2IRQMask, CIA1IRQMask, VICIRQMask, IRQ, NMI, COLDSTART

.segment "ZEROPAGE":zeropage
SRCPTR:   .res 2
DSTPTR:   .res 2

.segment "CODE"
.proc INITT
    sei
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

    lda #$95      ; PAL=$4025 dla NTSC=$4295  - to jest 60 Hz, zegar NTSC to 1022727 Hz, a PAL to 985248 Hz
    sta $DC04     ; CIA#1 Timer A  (Kernal-IRQ, Tape)
    lda #$42      ; PAL 985248/60=16420.8 ($4025), NTSC=1022727/60=17045.45 ($4295)
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
    lda #$20          ;wypełniaczem jest spacja
    jsr CLST
    lda #$60
    sta TXTPAGE
    lda #$20          ;wypełniaczem jest spacja
    jsr CLST
    lda #$FE          ;domyślne kolory C64 po włączeniu
    jsr FILLCT

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
