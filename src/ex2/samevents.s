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
.import IRQ, INITT, CLST, FILLCT, TXTPAGE, JiffyClock, WAIT, STARTJOB, STOPJOB, TASK2, TASK3, TASK4
.import JOBS, MVCRSR, CHROUT, PRINTHEX, BITSOFF, KBDEVENT, GETKEY, NEWKEYS, KEYMOD, EVENTS
.import CONSINIT, CONSMOVEUP, CONSKEYS, CRSRON, CRSROFF, CRSRNEG, BLINKCNT, LINELEN
.import CMDLINE, CHKCMD, CURROW, CURCOL, CRSPTR:zeropage, STROUT, CONSLINEOUT, TASK_EVENTS, STARTTIMER

.segment "DATA"
SUNMUTEX:   .byte 0
MOONMUTEX:  .byte 0
TOWNMUTEX:  .byte 0

.segment "RODATA"
CMDSTAB:   .byte 4,"stop",5,"start",0
JOBSSTR:   .byte "jobs:",0
ERRORSTR:  .byte "error",0

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
    lda #$18
    sta TASK_EVENTS     ;czekam na zdarzenie zmiany stanu klawiatury !!!!!!!!!!!
    ldy #0
    lda #30
    jsr STARTTIMER

    ; --- pętla zadania głównego czyli obsługa paska stanu i konsoli
main_loop:
    jsr print_number_of_jobs
    jsr print_event_state
    ;jsr SELECT

    lda #$E7
    and EVENTS
    sta EVENTS
    lda #$18
:   bit EVENTS
    beq :-

    lda #$08
    bit EVENTS
    beq :+
    jsr KBDEVENT
    jsr analyse_keys
    jmp main_loop

:   lda #$10
    bit EVENTS
    beq main_loop
    jsr CRSRNEG
    jmp main_loop
.endproc

.proc print_number_of_jobs
    lda #'j'-$40
    sta $6007
    lda #':'
    sta $6008
    jsr JOBS
    txa
    clc
    adc #'0'
    sta $600B
    lda #'/'
    sta $600A
    tya
    clc
    adc #'0'
    sta $6009
    rts
.endproc

.proc print_event_state
    ldx #13
    lda EVENTS
    jsr output_hex
    rts
.endproc

.proc output_hex
    pha
    lsr
    lsr
    lsr
    lsr
    cmp #10
    bcc :+
    adc #6
:   adc #'0'
    sta $6000,x
    inx
    pla
    and #$0F
    cmp #10
    bcc :+
    adc #6
:   adc #'0'
    sta $6000,x
    inx
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
    beq :+          ;nic do roboty
    jsr DOCMD
:   ldx #0
    stx LINELEN
    inx
    ldy #24
    jsr MVCRSR
    jsr CONSLINEOUT
    jsr CRSRON
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

    lda CMDLINE,x           ;A=0 to STOP
    cmp #$20
    inx
    lda CMDLINE,x
    cmp #'1'
    bcc invalid_command
    cmp #'7'
    bcs invalid_command
    sec
    sbc #'0'
    jsr STOPJOB
    jsr CONSMOVEUP
    rts

:   lda CMDLINE,x           ;obsługa komendy START
    cmp #$20
    inx
    lda CMDLINE,x
    cmp #'s'
    beq uruchom_sun
    cmp #'m'
    beq uruchom_moon
    cmp #'t'
    beq uruchom_town

invalid_command:
    jsr CONSMOVEUP
    ldx #0             ;ERROR
    ldy #24
    jsr MVCRSR
    lda #<ERRORSTR
    ldy #>ERRORSTR
    jsr STROUT
    jsr CONSMOVEUP
    rts

uruchom_sun:
    lda SUNMUTEX
    bne :+
    lda #>TASK2
    ldx #<TASK2
    jsr STARTJOB
:   jsr CONSMOVEUP
    rts

uruchom_moon:
    lda MOONMUTEX
    bne :+
    lda #>TASK3     ;tu nie ma zabezpieczenia przed uruchomieniem drugiej kopii tego zadania
    ldx #<TASK3
:   jsr CONSMOVEUP
    rts

uruchom_town:
    lda TOWNMUTEX
    bne :+
    lda #>TASK4     ;tu nie ma zabezpieczenia przed uruchomieniem drugiej kopii tego zadania
    ldx #<TASK4
    jsr STARTJOB
:   jsr CONSMOVEUP
    rts
.endproc

