;-----------------------------------------------------------
; Trzy procedury związane z obsługo sotwarowego kursora.
; 

.export CRSROFF, CRSRON, CRSRNEG, CRSRPOS, BLINKCNT

.segment "BSS"
CRSRPOS:  .res 1
BLINKCNT: .res 1

.segment "CODE"
.proc CRSROFF
    lda #20
    sta BLINKCNT
    ldx CRSRPOS
    lda $6000+24*40+1,x
    and #$BF
    sta $6000+24*40+1,x
    lda #5
    sta $D800+24*40+1,x
    rts
.endproc

.proc CRSRON
    lda #20
    sta BLINKCNT
    ldx CRSRPOS
    lda $6000+24*40+1,x
    ora #$40
    sta $6000+24*40+1,x
    lda #0
    sta $D800+24*40+1,x
    rts
.endproc

.proc CRSRNEG
    lda #20
    sta BLINKCNT
    ldx CRSRPOS
    lda $6000+24*40+1,x
    eor #$40
    sta $6000+24*40+1,x
    lda $D800+24*40+1,x
    eor #5
    sta $D800+24*40+1,x
    rts
.endproc

