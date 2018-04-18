;------------------------------------
; Procedura CLST czyści ekran tekstowy i tablicę kolorów ekranu tekstowego.
; tablica kolorów ma stałe miejsce D800-DBE7
; tablica znaków zaczyna się od strony podanej w TXTPAGE
;
; input: A=kolor, TXTPAGE
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
    ldy #$DB
    sty DPTR+1
    ldx #4          ;4x256 = 1KB
    ldy #$e8        ;rozmiar $03e8 = 1000
:   dey
    sta (DPTR),y
    bne :-
    dec DPTR+1
    dex
    bne :-

    lda TXTPAGE
    clc
    adc #3
    sta DPTR+1      ;będzie $6300 albo $6700
    lda #$20
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

