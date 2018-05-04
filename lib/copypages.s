;---------------------------------------------------------- 
; Copy X pages pointed by A to pages pointed by Y
; modified: A,X,Y,P,SRCPTR,DSTPTR
; reentrant: no

.export COPYPAGES

.segment "ZEROPAGE":zeropage
SRCPTR:   .res 2
DSTPTR:   .res 2

.segment "CODE"
.proc COPYPAGES
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
