;---------------------------------------------------------- 
; sekwencja uruchamiająca program bees

.import INIT, HGR, NRM, CLS

.segment "CODE"
    .org $0801

    .word $080D       ;wskaźnik to następnej linii
    .word 2018        ;numer linii i jednocześnie rok powstania
    .byte $9E         ;SYS token
    .asciiz "(2063)"  ;SYS argument
    .word 0           ;wskaźnik na następną linię, $0000 oznacza, że jest to ostania linia

    jsr INIT
    jsr HGR
    lda #$01     ;białe litery na czarnym tle
    ldx #$5C     ;strona pamięci koloru
    jsr CLS


:   nop
    jmp :-
