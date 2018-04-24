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

.segment "DATA"
SLUPKI:   .byte 20,21,24,28,30,31,28,27,27,30,   35,40,48,54,55,55,56,57,60,65,   64,63,57,52,43,38,32,27,22,21,   18,17,17,18,19,20,22,21,21,20

.segment "RODATA"
KONCOWKI:  .byte 227,247,248,98,121,111,100,32,160

.segment "ZEROPAGE":zeropage
NPTR:    .res 2

.segment "CODE"
.proc DRAW_SCEEN
    lda #<(24*40)
    sta NPTR
    lda TXTPAGE
    clc
    adc #>(24*40)
    sta NPTR+1      ;będzie $6300 albo $6700

    lda #0          ;numer kolumny
    sta NRSLUP

nastepny_slupek:
    ldx #8          ;pętla po liniach licząc od dołu
 
:   txa             ;decyzja co wstawić: X+8>=W -> 32, X>=W -> K, 32
    ldy NRSLUP
    sec
    sbc SLUPKI,y
    ldy #8
    bcc :+          ; to grunt
    tay
    cmp #8
    bcc :+          ; to końcówka gruntu
    ldy #7          ; to niebo 
:   lda KONCOWKI,y
    ldy #0
    sta (NPTR),y
    lda NPTR        ;bloczek wyżej
    sec
    sbc #40
    sta NPTR
    lda NPTR+1
    sbc #0
    sta NPTR+1

    txa
    clc
    adc #8
    tax
    cpx #200          ;wspinam się na górę
    bne :--

    lda NPTR        ;nastepna kolumna
    clc
    adc #<961
    sta NPTR
    lda NPTR+1
    adc #>961
    sta NPTR+1

    inc NRSLUP
    lda NRSLUP
    cmp #40
    bcc nastepny_slupek
    rts
.endproc

