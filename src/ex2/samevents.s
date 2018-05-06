;---------------------------------------------------------- 
; Sekwencja uruchamiająca program Sun & Moon.
; Ta sekwencja uruchamia trzy zadania operujące na spritach
; i środkowej części ekranu (nazwijmy ją ekranem graficznym)
; Zaś sam proces główny przekształca się w proces konsoli i
; paska stanu.
;
; Uwaga: proces konsoli i paska stanu używa jednozadaniowych
; procedur MVCRSR, CHROUT i PRINTHEX. Może je bezpiecznie używać pod
; warunkiem, że żadne inne zadanie z nich nie korzysta.

.include "../../lib/globals.inc"

.import IRQ, INITT, CLST, FILLCT, TXTPAGE, STARTJOB, TASK1, TASK2, TASK3, TASK4

.segment "CODE"
    .org $0801

    .word $080D       ;wskaźnik to następnej linii
    .word 2018        ;numer linii i jednocześnie rok powstania
    .byte $9E         ;SYS token
    .asciiz "(2063)"  ;SYS argument
    .word 0           ;wskaźnik na następną linię, $0000 oznacza, że jest to ostania linia

    ldx #$FF
    txs
    cld               ; i nigdy więcej nie włączaj
    sei
    lda #<IRQ
    sta $FFFE        ;Hardware IRQ Interrupt Vector
    lda #>IRQ
    sta $FFFF
    cli
    jsr INITT

    lda $D011        ;extended background mode
    ora #$40
    sta $D011
    lda #0           ;czarne tło dla konsoli
    sta $D021
    lda #5           ;zielone tło dla konsoli dla znaków w inwersji
    sta $D022
    lda #6           ;ciemno niebieskie
    sta $D023
    lda #14          ;jasno niebieskie
    sta $D024

    lda #>TASK1       ;będę wracał przez RTI więc TASK1 a nie TASK1-1
    ldx #<TASK1
    jsr STARTJOB

    lda #>TASK2
    ldx #<TASK2
    jsr STARTJOB

    lda #>TASK3
    ldx #<TASK3
    jsr STARTJOB

    lda #>TASK4
    ldx #<TASK4
    jsr STARTJOB

    ; --- teraz zaczyna się zerowy proces IDLE, którego nie można zabić.
    ; tu można zrobić licznik obiegów pętli, który będzie wyznaczał stopień
    ; nudy mikroprocesora.
:   nop
    jmp :-

