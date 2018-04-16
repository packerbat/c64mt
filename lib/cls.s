;------------------------------------
; Procedura CLS czyści ekran graficzny i tablicę kolorów ekranu graficznego
;   Ekran zaczyna się od VIDPAGE a tablica kolorów od VIDPAGE-32
;   ekranu wysokiej rozdzielczości
;
; input: A=kolor, VIDPAGE
; output: ZF=1, X=0, Y=0
; stack: 1
; zeropage: 2
; reentrant: no

.export CLS
.import VIDPAGE

.segment "ZEROPAGE":zeropage
DPTR:    .res 2

.segment "CODE"
.proc CLS
    ldy #0
    sty DPTR
    tax
    lda VIDPAGE
    sec
    sbc #32-3
    sta DPTR+1
    txa
    ldx #4          ;4x256 = 1KB
    ldy #$e8        ;rozmiar $03e8 = 1000
:   dey
    sta (DPTR),y
    bne :-
    dec DPTR+1
    dex
    bne :-

    lda VIDPAGE
    clc
    adc #31
    sta DPTR+1
    lda #0          ;wypełnienie $00
    ldx #32         ;32x256 = 8KB
    ldy #$40        ;rozmiar $1f40 = 8000
:   dey
    sta (DPTR),y
    bne :-
    dec DPTR+1
    dex
    bne :-
    rts
.endproc

