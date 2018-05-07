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

.import IRQ, INITT, CLST, FILLCT, TXTPAGE, JiffyClock, WAIT, STARTJOB, STOPJOB, TASK2, TASK3, TASK4
.import JOBS, MVCRSR, CHROUT, PRINTHEX, BITSOFF, SCANKBD, GETKEY, KEYMOD, NEWKEYS
.import CONSINIT, CONSMOVEUP, CONSKEYS, CRSRON, CRSROFF, CRSRNEG, LINELEN
.import CMDLINE, CHKCMD, CURROW, CURCOL, CRSPTR:zeropage, STROUT, CONSLINEOUT
.import SUNSLOT, MOONSLOT, TOWNSLOT

.segment "BSS"
BLINKCNT: .res 1

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
    lda #'j'-$40
    sta $6002
    lda #'o'-$40
    sta $6003
    lda #'b'-$40
    sta $6004
    lda #'s'-$40
    sta $6005
    lda #':'
    sta $6005
    jsr JOBS
    txa
    clc
    adc #'0'
    sta $6008
    lda #'/'
    sta $6007
    tya
    clc
    adc #'0'
    sta $6006
    rts
.endproc

.proc print_keyboard_state
    ldx #12+0*2
    lda NEWKEYS+0
    jsr output_hex
    ldx #12+1*2
    lda NEWKEYS+1
    jsr output_hex
    ldx #12+2*2
    lda NEWKEYS+2
    jsr output_hex
    ldx #12+3*2
    lda NEWKEYS+3
    jsr output_hex
    ldx #12+4*2
    lda NEWKEYS+4
    jsr output_hex
    ldx #12+5*2
    lda NEWKEYS+5
    jsr output_hex
    ldx #12+6*2
    lda NEWKEYS+6
    jsr output_hex
    ldx #12+7*2
    lda NEWKEYS+7
    jsr output_hex
    ldx #13+8*2
    lda KEYMOD
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
    sbc #57
:   adc #'0'
    sta $6000,x
    inx
    pla
    and #$0F
    cmp #10
    bcc :+
    sbc #57
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
    lda #20
    sta BLINKCNT
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

