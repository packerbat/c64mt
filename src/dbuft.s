;---------------------------------------------------------- 
; sekwencja uruchamiająca program bees

.import INITT, SETDBT, SWAPSCRT, CLST, TXTPAGE

.segment "ZEROPAGE":zeropage
NPTR:  .res 2

.segment "CODE"
    .org $0801

    .word $080D       ;wskaźnik to następnej linii
    .word 2018        ;numer linii i jednocześnie rok powstania
    .byte $9E         ;SYS token
    .asciiz "(2063)"  ;SYS argument
    .word 0           ;wskaźnik na następną linię, $0000 oznacza, że jest to ostania linia

    jsr INITT
    ;lda #1
    ;jsr SETDBT        ;turn off double buffer

:   jsr DRAW_SCEEN
    jsr SWAPSCRT
    jmp :-

.proc DRAW_SCEEN
    lda #$FE
    jsr CLST

    lda #0
    sta NPTR
    lda TXTPAGE
    clc
    adc #3
    sta NPTR+1      ;będzie $6300 albo $6700
    lda $A2         ;jiffy clock
    and #$3F
    ldx #4          ;4x256 = 1KB
    ldy #$E8        ;rozmiar $03e8 = 1000
:   dey
    sta (NPTR),y
    bne :-
    dec NPTR+1
    dex
    bne :-

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