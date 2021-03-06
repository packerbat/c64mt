;----------------------------
; Procedura PRINTHEX wyświetla podaną wartość (A) jako hex w miejscu bieżącego kursora (CRSPTR, CURROW, CURCOL)
; input: A=wartość
; output: Y=?, X=preserved, A=?
; stack: 3
; reentrant: no

.export PRINTHEX
.import CHROUT

.proc PRINTHEX
    pha
    lsr
    lsr
    lsr
    lsr
    cmp #10
    bcc :+
    adc #6
:   adc #'0'
    jsr CHROUT
    pla
    and #$0F
    cmp #10
    bcc :+
    adc #6
:   adc #'0'
    jsr CHROUT
    rts
.endproc
