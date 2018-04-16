;---------------------------------------------------------- 
; sekwencja uruchamiająca program bees

.import INITT, SETDBT, SWAPSCRT

.segment "CODE"
    .org $0801

    .word $080D       ;wskaźnik to następnej linii
    .word 2018        ;numer linii i jednocześnie rok powstania
    .byte $9E         ;SYS token
    .asciiz "(2063)"  ;SYS argument
    .word 0           ;wskaźnik na następną linię, $0000 oznacza, że jest to ostania linia

    lda #0
    jsr SETDBT        ;turn off double buffer
    jsr INITT

:   jsr DRAW_SCEEN
    jsr SWAPSCRT
    jmp :-

.proc DRAW_SCEEN
    ldx #0
    ldy #0
:   nop         ;65536 * 2 cycles
    dex         ;65536 * 2 cycles
    bne :-      ;(65536-256) * 3 cycles + 256 * 2 cycles)
    dey         ;256 * 2 cycles
    bne :-      ;255 * 3 cycles + 2 cycles
    rts         ;powrót po 65536*4+65536*3-256+256*2+256*3-1=459775, powinno się zmieniać co 0.5 sekundy a chyba jest rzadziej.
.endproc