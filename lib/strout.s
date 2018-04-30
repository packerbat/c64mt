;----------------------------
; Procedura CHROUT wyświetla podaną literę (A) w miescu bieżącego kursora (CRSPTR, CURROW, CURCOL)
; input: A/Y=adres stringu, CRSPTR, CURROW, CURCOL
; output: Y=?, X=preserved, A=?, CRSPTR, CURROW, CURCOL
; stack: 0
; reentrant: no

.export STROUT
.import CHROUT

.segment "ZEROPAGE":zeropage
STRPTR:   .res 2

.segment "CODE"
.proc STROUT
    sta STRPTR
    sty STRPTR+1
:   ldy #0
    lda (STRPTR),y
    beq :+
    jsr CHROUT
    inc STRPTR
    bne :-
    inc STRPTR+1
    bne :-
:   rts
.endproc
