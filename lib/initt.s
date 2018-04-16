;---------------------------------------------------------- 
; sekwencja inicjująca rozszerzenie basica

.export INITT
.import NRM, TXTPAGE, CLST

.segment "DATA"
IRQPRESC: .byte 30

.segment "ZEROPAGE"
SRCPTR:   .res 2
DSTPTR:   .res 2

.segment "CODE"
.proc INITT
    ;--- copy KERNAL from $E000 in ROM to $E000 in RAM
    lda #$E0
    ldy #$E0
    ldx #64         ;=8KB
    jsr copy_pages

    sei
    lda #$33         ;turn on CHARACTER ROM at address $D000-DFFF
    sta $01
    lda #$D8
    ldy #$40
    ldx #16         ;=2KB
    jsr copy_pages
    lda #$35         ;turn off KERNAL ROM and BASIC ROM and CHRACTER ROM, do not remove I/O at $D000-$DFFF
    sta $01
    cli

    lda #$40
    ldy #$80
    ldx #16         ;=2KB
    jsr copy_pages

    jsr NRM
    lda #$60
    sta TXTPAGE
    lda #$FE          ;białe litery na czarnym tle
    jsr CLST
    lda #$A0
    sta TXTPAGE
    lda #$FE          ;białe litery na czarnym tle
    jsr CLST

    lda #<IRQ
    ldy #>IRQ
    sei          ;podmiana przerwania na moją procedurę
    sta $0314    ;Hardware IRQ Interrupt Vector
    sty $0315
    cli

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
; Copy X pages pointed by A to pages pointed by Y
; modified: A,X,Y,P,SRCPTR,DSTPTR
;
.proc IRQ
    dec IRQPRESC
    bne :+
    lda #30
    sta IRQPRESC
    inc $6000
    inc $A000
:   jmp $EA31       ;build-in request handler
.endproc
