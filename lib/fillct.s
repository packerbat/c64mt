;------------------------------------
; Procedura FILLCT czyści tablicę kolorów ekranu tekstowego.
;
; input: A=kolor
; output: ZF=1, X=0, Y=0
; stack: 1
; zeropage: 2
; reentrant: no

.export FILLCT

.segment "ZEROPAGE":zeropage
DCPTR:    .res 2

.segment "CODE"
.proc FILLCT
    ldy #0
    sty DCPTR
    ldy #$DB
    sty DCPTR+1
    ldx #4          ;4x256 = 1KB
    ldy #$e8        ;rozmiar $03e8 = 1000
:   dey
    sta (DCPTR),y
    bne :-
    dec DCPTR+1
    dex
    bne :-
    rts
.endproc

