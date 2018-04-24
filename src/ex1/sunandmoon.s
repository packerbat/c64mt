;---------------------------------------------------------- 
; sekwencja uruchamiająca program bees

.include "../../lib/globals.inc"

.import INITT, CLST, FILLCT, TXTPAGE, JiffyClock, WAIT, STARTJOB, TASK2, TASK3, TASK4
.import JOBS, MVCRSR, CHROUT, PRINTHEX, BITSOFF, SCANKBD, LASTKEYS, KBDHEAD, KBDTAIL, KBDBUFFER

.segment "BSS"
LINELEN:  .res 1

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
    jsr INITT

    lda $D011        ;extended background mode
    ora #$40
    sta $D011
    lda #0           ;czarne tło dla konsoli
    sta $D021
    lda #5           ;zielone
    sta $D022
    lda #6           ;ciemno niebieskie
    sta $D023
    lda #14          ;jasno niebieskie
    sta $D024

    lda #>TASK2       ;będę wracał przez RTI więc TASK2 a nie TASK2-1
    ldx #<TASK2
    jsr STARTJOB

    lda #>TASK3
    ldx #<TASK3
    jsr STARTJOB

    lda #>TASK4
    ldx #<TASK4
    jsr STARTJOB

    jmp TASK1

;*********************************************************
; TASK No 1

.proc TASK1
    ldx #40
    lda #$20
:   dex
    sta $6000,x         ;pasek stanu na górze i podwójny pasek konsoli na dole
    sta $6000+23*40,x
    sta $6000+24*40,x
    bne :-
    ldx #40
    lda #5              ;zielone litery  na pasku stanu i konsoli
:   dex
    sta $D800,x         ;pasek stanu na górze i podwójny pasek konsoli na dole
    sta $D800+23*40,x
    sta $D800+24*40,x
    bne :-
    lda #29             ;prompt
    sta $6000+23*40
    lda #$20+$40        ;kursor
    sta $6000+23*40+1
    ldx #0
    stx LINELEN

    ; --- pętla zadania głównego czyli obsługa paska stanu i konsoli
:   jsr print_number_of_jobs
    jsr SCANKBD
    jsr print_keyboard_state
    lda KBDTAIL
    cmp KBDHEAD
    beq bufor_klawiatury_pusty
:   clc
    adc #1
    cmp #KDBQUEUESIZE
    bcc :+
    lda #0
:   tax
    lda KBDBUFFER,x     ;najpiew pobrać do kolejki
    stx KBDTAIL         ;a dopiero potem przesunąć TAIL

    tay
    and #$80
    bne :+
    tya
    and #$3F
    ldx LINELEN
    sta $6000+23*40+1,x
    inx
    lda #$20+$80
    sta $6000+23*40+1,x
    stx LINELEN

:   lda KBDTAIL
    cmp KBDHEAD
    bne :---

bufor_klawiatury_pusty:
    ldy #1
    jsr WAIT
    jmp :----
.endproc

.proc print_number_of_jobs
    ldx #2
    ldy #0
    jsr MVCRSR
    lda #'j'
    jsr CHROUT
    lda #'o'
    jsr CHROUT
    lda #'b'
    jsr CHROUT
    lda #'s'
    jsr CHROUT
    lda #':'
    jsr CHROUT
    jsr JOBS
    txa
    clc
    adc #'0'
    pha
    tya
    clc
    adc #'0'
    jsr CHROUT
    lda #'/'
    jsr CHROUT
    pla
    jsr CHROUT
    rts
.endproc

.proc print_keyboard_state
    lda #7
    pha                 ;TMPBIT = $101,x

:   tsx
    lda $101,x
    asl
    clc
    adc #12
    tax         ;wylicz kolumnę
    ldy #0
    jsr MVCRSR

    tsx
    ldy $101,x
    lda LASTKEYS,y
    jsr PRINTHEX

    tsx
    dec $101,x
    bpl :-

    pla             ;usuwam tymczasowe zmienne
    rts
.endproc