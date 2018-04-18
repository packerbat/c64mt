;---------------------------------------------------------- 
; sekwencja uruchamiająca program bees

.import INIT, SETDB, CLS, SWAPSCR, XP, YP, XK, YK, LINE
.import tablica_naroznikow

.segment "ZEROPAGE"
NPOS:  .res 1
NPTR:  .res 2
 
.segment "CODE"
    .org $0801

    .word $080D       ;wskaźnik to następnej linii
    .word 2018        ;numer linii i jednocześnie rok powstania
    .byte $9E         ;SYS token
    .asciiz "(2063)"  ;SYS argument
    .word 0           ;wskaźnik na następną linię, $0000 oznacza, że jest to ostania linia

    jsr INIT
    lda #1
    jsr SETDB         ;turn on double buffer

    lda #128-5
    sta NPOS
    lda #<(tablica_naroznikow+128-5)
    sta NPTR
    lda #>(tablica_naroznikow+128-5)
    sta NPTR+1

:   jsr DRAW_SCEEN
    jsr SWAPSCR
    jmp :-

.proc DRAW_SCEEN
    lda #$FE          ;jasnoszare litery na fioletowym tle
    jsr CLS

    lda #5
    jsr next_corner
    sta XP
    jsr next_NPTR
    sta XP+1
    jsr next_NPTR
    sta YP
    jsr next_NPTR
    sta YP+1

    lda #29
    jsr next_corner
    sta XK
    jsr next_NPTR
    sta XK+1
    jsr next_NPTR
    sta YK
    jsr next_NPTR
    sta YK+1
    jsr LINE

    lda #29
    jsr next_corner
    sta XK
    jsr next_NPTR
    sta XK+1
    jsr next_NPTR
    sta YK
    jsr next_NPTR
    sta YK+1
    jsr LINE

    lda #29
    jsr next_corner
    sta XK
    jsr next_NPTR
    sta XK+1
    jsr next_NPTR
    sta YK
    jsr next_NPTR
    sta YK+1
    jsr LINE

    lda #29
    jsr next_corner
    sta XK
    jsr next_NPTR
    sta XK+1
    jsr next_NPTR
    sta YK
    jsr next_NPTR
    sta YK+1
    jsr LINE

    ;jsr WAIT
    rts         ;powrót po 65536*4+65536*3-256+256*2+256*3-1=459775, powinno się zmieniać co 0.5 sekundy a chyba jest rzadziej.
.endproc

.proc WAIT
    ldx #0
    ldy #0
:   nop         ;65536 * 2 cycles
    dex         ;65536 * 2 cycles
    bne :-      ;(65536-256) * 3 cycles + 256 * 2 cycles)
    dey         ;256 * 2 cycles
    bne :-      ;255 * 3 cycles + 2 cycles
    rts         ;powrót po 65536*4+65536*3-256+256*2+256*3-1=459775, powinno się zmieniać co 0.5 sekundy a chyba jest rzadziej.
.endproc

.proc next_NPTR
    lda #1
    clc
    adc NPOS
    and #$7F    ;zawiń wskaźnik
    sta NPOS
    clc
    adc #<tablica_naroznikow
    sta NPTR
    lda #0
    adc #>tablica_naroznikow
    sta NPTR+1
    lda (NPTR),y
    rts
.endproc

; A=number of bytes to skeep, 29 or 5
.proc next_corner
    clc
    adc NPOS
    and #$7F
    sta NPOS
    clc
    adc #<tablica_naroznikow
    sta NPTR
    lda #0
    adc #>tablica_naroznikow
    sta NPTR+1
    ldy #0
    lda (NPTR),y
    rts
.endproc
