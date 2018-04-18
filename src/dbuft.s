;---------------------------------------------------------- 
; sekwencja uruchamiająca program dbuft

.import INITT, SETDBT, SWAPSCRT, CLST, TXTPAGE

.segment "ZEROPAGE":zeropage
NPTR:  .res 2
NRSLUP: .res 1

.segment "DATA"
SLUPKI:   .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

.segment "RODATA"
KONCOWKI:  .byte 100,111,121,98,248,247,227,160

.segment "CODE"
    .org $0801

    .word $080D       ;wskaźnik to następnej linii
    .word 2018        ;numer linii i jednocześnie rok powstania
    .byte $9E         ;SYS token
    .asciiz "(2063)"  ;SYS argument
    .word 0           ;wskaźnik na następną linię, $0000 oznacza, że jest to ostania linia

    jsr INITT
    lda #1
    jsr SETDBT        ;turn on double buffer

:   jsr DRAW_SCEEN
    jsr SWAPSCRT
    jmp :-

.proc DRAW_SCEEN
    lda #$35
    jsr CLST

    lda #<(24*40)
    sta NPTR
    lda TXTPAGE
    clc
    adc #>(24*40)
    sta NPTR+1      ;będzie $6300 albo $6700

    lda #0          ;numer kolumny
    sta NRSLUP

nastepny_slupek:
    ldy NRSLUP
    ldx SLUPKI,y
    beq slupek_namalowany
 
    lda NPTR+1
    pha
    lda NPTR
    pha
    ldy #0
    cpx #9
    bcc :++         ;czas na koncowke
    
:   lda #160        ;spacja w inwersji
    sta (NPTR),y
    lda NPTR        ;bloczek wyżej
    sec
    sbc #40
    sta NPTR
    lda NPTR+1
    sbc #0
    sta NPTR+1
    txa
    sec
    sbc #8
    tax
    cpx #9          ;wciąż mamy całe bloczki 
    bcs :-

:   cpx #0          ;malowanie_koncowki X=0..8
    beq :+
    dex
    lda KONCOWKI,x
    sta (NPTR),y

:   pla             ;powrót na dół ekranu
    sta NPTR
    pla
    sta NPTR+1

slupek_namalowany:
    lda NPTR        ;nastepna kolumna
    clc
    adc #1
    sta NPTR
    lda NPTR+1
    adc #0
    sta NPTR+1

    inc NRSLUP
    lda NRSLUP
    cmp #40
    bcc nastepny_slupek
    
    ldx #0          ;przesunięcie słupków w lewo
    ldy #39
:   lda SLUPKI+1,x
    sta SLUPKI,x
    inx
    dey
    bne :-
    lda $A2
    lsr
    lsr
    sta SLUPKI,x

    ;jsr WAIT
    rts
.endproc

.proc WAIT
    ldx #1
    ldy #0
:   nop         ;65536 * 2 cycles
    dex         ;65536 * 2 cycles
    bne :-      ;(65536-256) * 3 cycles + 256 * 2 cycles)
    dey         ;256 * 2 cycles
    bne :-      ;255 * 3 cycles + 2 cycles
    rts         ;powrót po 65536*4+65536*3-256+256*2+256*3-1=459775, powinno się zmieniać co 0.5 sekundy a chyba jest rzadziej.
.endproc