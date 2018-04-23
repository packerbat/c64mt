;------------------------------------
; Procedura CLST czyści ekran tekstowy.
; Aktywna ekran (niekoniecznie widoczny) wskazuje zmienna TXTPAGE (typowo $60 albo $64)
;
; input: A=wypełniacz, TXTPAGE
; output: ZF=1, X=0, Y=0
; stack: 1
; zeropage: 2
; reentrant: no

.export CLST
.import TXTPAGE

.segment "ZEROPAGE":zeropage
DPTR:    .res 2

.segment "CODE"
.proc CLST
    ldy #0
    sty DPTR
    ldy TXTPAGE
    iny
    iny
    iny
    sty DPTR+1      ;będzie $6300 albo $6700
    ldx #4          ;4x256 = 1KB
    ldy #$E8        ;rozmiar $03e8 = 1000
:   dey
    sta (DPTR),y
    bne :-
    dec DPTR+1
    dex
    bne :-
    rts
.endproc

