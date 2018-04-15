;------------------------------------
; Procedura CLS czyści ekran graficzny albo tekstowy w zależności od bita w $D011
;   i tablicę kolorów ekranu graficznego, który pokrywa się
;   z adresem ekranu tekstowego. Tablica kolorów musi być ulokowana bezpośrednio przez pamięcią
;   ekranu wysokiej rozdzielczości
; input: A=kolor, X=adres tablicy kolorów w przypadku grafiki albo adres znaków w przypadku tekstu
; output: ZF=1, X=0, Y=0
; stack: 1
; zeropage: 2
; reentrant: no

.export CLS

.segment "ZEROPAGE":zeropage
DPTR:    .res 2

.segment "CODE"
.proc CLS
    ldy #0
    sty DPTR

    pha
    lda $D011    ;VIC Control Register 1
    ora #$20     ;Bit 5 = 1 Enable bitmap mode
    beq czyszczenie_ekranu_tekstowego

    txa
    clc
    adc #4+31
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
    jmp wypelnianie_kolorem

czyszczenie_ekranu_tekstowego:
    inx
    inx
    inx
    stx DPTR+1
    lda #$20
    ldx #4          ;4x256 = 1KB
    ldy #$E8        ;rozmiar $03e8 = 1000
:   dey
    sta (DPTR),y
    bne :-
    dec DPTR+1
    dex
    bne :-
    lda #$DB
    sta DPTR+1

wypelnianie_kolorem:
    pla
    ldx #4          ;4x256 = 1KB
    ldy #$e8        ;rozmiar $03e8 = 1000
:   dey
    sta (DPTR),y
    bne :-
    dec DPTR+1
    dex
    bne :-
    rts
.endproc

