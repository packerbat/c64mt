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

.export SUNMUTEX, MOONMUTEX, TOWNMUTEX
.import INITT, CLST, FILLCT, TXTPAGE, JiffyClock, WAIT, STARTJOB, STOPJOB, TASK2, TASK3, TASK4
.import JOBS, MVCRSR, CHROUT, PRINTHEX, BITSOFF, SCANKBD, GETKEY, NEWKEYS, KEYMOD
.import CONSINIT, CONSGETCHAR, CONSMOVEUP, CONSKEYS, CRSRON, CRSROFF, CRSRNEG, BLINKCNT, LINELEN
.import CHKCMD, CMDLEN

.segment "DATA"
SUNMUTEX:   .byte 0
MOONMUTEX:  .byte 0
TOWNMUTEX:  .byte 0

.segment "RODATA"
CMDSTAB:   .byte 4,"stop",5,"start",0

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
    jsr CONSINIT

    ; --- pętla zadania głównego czyli obsługa paska stanu i konsoli
main_loop:
    jsr print_number_of_jobs
    jsr SCANKBD
    jsr print_keyboard_state
    jsr analyse_keys
    ldy #1
    jsr WAIT
    dec BLINKCNT
    bne :+
    jsr CRSRNEG
:   jmp main_loop
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
    lda NEWKEYS,y
    jsr PRINTHEX

    tsx
    dec $101,x
    bpl :-

    ldx #12+8*2
    ldy #0
    jsr MVCRSR
    lda #32
    jsr CHROUT
    lda KEYMOD
    jsr PRINTHEX

    pla             ;usuwam tymczasowe zmienne
    rts
.endproc

;-------------------------------------
; pobiera i analizyje klawisze zgromadzone w buforze klawiatury
; tak długo aż opróżni bufor.
;
.proc analyse_keys
get_next_key:
    jsr GETKEY
    bne cos_jest_w_buforze_klawiatury
    rts

cos_jest_w_buforze_klawiatury:
    jsr CONSKEYS
    bcc get_next_key
    cmp #13
    bne get_next_key
    jsr CRSROFF
    lda LINELEN
    sta CMDLEN
    jsr CONSMOVEUP
    lda CMDLEN
    beq :+          ;nic do roboty
    jsr DOCMD
:   jsr CRSRON
    jmp get_next_key
.endproc

.proc DOCMD
    ldx #0          ;ustawiam się na początku wiersza polecenia
    lda #<CMDSTAB
    ldy #>CMDSTAB
    jsr CHKCMD
    bcc invalid_command
    cmp #1                  ;A=1 to START
    beq :+

    jsr CONSGETCHAR         ;A=0 to STOP
    cmp #$20
    inx
    jsr CONSGETCHAR
    cmp #'1'
    bcc invalid_command
    cmp #'7'
    bcs invalid_command
    sec
    sbc #'0'
    jsr STOPJOB
    rts

:   jsr CONSGETCHAR         ;obsługa komendy START
    cmp #$20
    inx
    jsr CONSGETCHAR
    cmp #'s'
    beq uruchom_sun
    cmp #'m'
    beq uruchom_moon
    cmp #'t'
    beq uruchom_town

invalid_command:
    ldx #0             ;ERROR
    ldy #24
    jsr MVCRSR
    lda #'e'
    jsr CHROUT
    lda #'r'
    jsr CHROUT
    lda #'r'
    jsr CHROUT
    lda #'o'
    jsr CHROUT
    lda #'r'
    jsr CHROUT
    jsr CONSMOVEUP
    rts

uruchom_sun:
    lda SUNMUTEX
    bne :+
    lda #>TASK2
    ldx #<TASK2
    jsr STARTJOB
:   rts

uruchom_moon:
    lda MOONMUTEX
    bne :+
    lda #>TASK3     ;tu nie ma zabezpieczenia przed uruchomieniem drugiej kopii tego zadania
    ldx #<TASK3
    jsr STARTJOB
:   rts

uruchom_town:
    lda TOWNMUTEX
    bne :+
    lda #>TASK4     ;tu nie ma zabezpieczenia przed uruchomieniem drugiej kopii tego zadania
    ldx #<TASK4
    jsr STARTJOB
:   rts
.endproc

