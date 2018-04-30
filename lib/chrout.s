;----------------------------
; Procedura CHROUT wyświetla podaną literę (A) w miescu bieżącego kursora (CRSPTR, CURROW, CURCOL)
; input: A=litera, CRSPTR, CURROW, CURCOL
; output: Y=?, X=preserved, A=?, CRSPTR, CURROW, CURCOL
; stack: 0
; reentrant: no

.export CHROUT
.import TXTPAGE, CRSPTR:zeropage, CURROW, CURCOL

.proc CHROUT
    ldy CURCOL
    cmp #$40
    bcc :+
    sbc #$40
:   sta (CRSPTR),y

    cpy #39
    bcs :+
    iny
    sty CURCOL          ;najprostszy przypadek
    rts

:   lda #0
    sta CURCOL
    ldy CURROW
    cpy #24
    bcs :++             ;ekran się skończył
    iny
    sty CURROW          ;wiersz się skończył ale ekran jeszcze nie
    lda CRSPTR
    clc
    adc #40
    sta CRSPTR
    bcc :+
    inc CRSPTR+1
:   rts

:   lda #0              ;tu powieniem być SCROLL UP ale narazie jest zawinięcie na górę ekranu
    sta CURROW
    sta CRSPTR
    lda TXTPAGE
    sta CRSPTR+1
    rts
.endproc
