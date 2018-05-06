;---------------------------------------------------------- 
; Proces wyświetlający przesuwające się wieżowce
; 

.export TASK1
.import STARTTIMER, SELECT, EVENTS, STARTJOB, STOPJOB, TASK2, TASK3, TASK4
.import JOBS, MVCRSR, CHROUT, PRINTHEX, KBDEVENT, GETKEY, NEWKEYS, KEYMOD, EVENTS
.import CONSINIT, CONSMOVEUP, CONSKEYS, CRSRON, CRSROFF, CRSRNEG, BLINKCNT, LINELEN
.import CMDLINE, CHKCMD, CURROW, CURCOL, STROUT, CONSLINEOUT, STARTTIMER
.import SUNSLOT, MOONSLOT, TOWNSLOT

.segment "RODATA"
CMDSTAB:   .byte 4,"stop",5,"start",0
JOBSSTR:   .byte "jobs:",0
ERRORSTR:  .byte "error",0

.segment "BSS"
LASTEVENTS:   .res 1

.segment "CODE"
;*********************************************************
; TASK No 1

.proc TASK1
    jsr CONSINIT
    ldy #0
    lda #30
    jsr STARTTIMER

    ; --- pętla zadania głównego czyli obsługa paska stanu i konsoli
main_loop:
    jsr print_number_of_jobs
    jsr print_event_state
    lda #$18                    ;czekam na zdarzenie zmiany stanu klawiatury i od zegara 0 (zegar 0 służy do zmiany stanu kursora)
    jsr SELECT                  ;po powrocie w A będą flagi zdarzeń, które rzeczywiście miały miejsce
    sta LASTEVENTS

    lda #$08
    bit LASTEVENTS
    beq :+
    jsr KBDEVENT
    jsr analyse_keys
    jmp main_loop

:   lda #$10
    bit LASTEVENTS
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
    beq obsluga_komendy_start

    lda CMDLINE,x           ;A=0 to STOP
    cmp #$20
    inx
    lda CMDLINE,x
    cmp #'s'
    beq zakoncz_sun
    cmp #'m'
    beq zakoncz_moon
    cmp #'t'
    bne invalid_command

zakoncz_town:
    lda TOWNSLOT
    beq :+
    jsr STOPJOB
:   jsr CONSMOVEUP
    rts

zakoncz_sun:
    lda SUNSLOT
    beq :+
    jsr STOPJOB
:   jsr CONSMOVEUP
    rts

zakoncz_moon:
    lda MOONSLOT
    beq :+
    jsr STOPJOB
:   jsr CONSMOVEUP
    rts

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

obsluga_komendy_start:
    lda CMDLINE,x           ;obsługa komendy START
    cmp #$20
    inx
    lda CMDLINE,x
    cmp #'s'
    beq uruchom_sun
    cmp #'m'
    beq uruchom_moon
    cmp #'t'
    bne invalid_command

uruchom_town:
    lda TOWNSLOT
    bne :+
    lda #>TASK4     ;tu nie ma zabezpieczenia przed uruchomieniem drugiej kopii tego zadania
    ldx #<TASK4
    jsr STARTJOB
:   jsr CONSMOVEUP
    rts

uruchom_sun:
    lda SUNSLOT
    bne :+
    lda #>TASK2
    ldx #<TASK2
    jsr STARTJOB
:   jsr CONSMOVEUP
    rts

uruchom_moon:
    lda MOONSLOT
    bne :+
    lda #>TASK3     ;tu nie ma zabezpieczenia przed uruchomieniem drugiej kopii tego zadania
    ldx #<TASK3
    jsr STARTJOB
:   jsr CONSMOVEUP
    rts
.endproc

