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
.import INITT, CLST, FILLCT, TXTPAGE, JiffyClock, WAIT, STARTJOB, TASK2, TASK3, TASK4
.import JOBS, MVCRSR, CHROUT, PRINTHEX, BITSOFF, SCANKBD, GETKEY, NEWKEYS, KEYMOD
.import STOPJOB

.segment "ZEROPAGE":zeropage
CMDPTR:   .res 2

.segment "BSS"
LINELEN:  .res 1
CRSRPOS:  .res 1
BLINKCNT: .res 1
CMDLEN:   .res 1
PATERLEN: .res 1

.segment "DATA"
SUNMUTEX:   .byte 0
MOONMUTEX:  .byte 0
TOWNMUTEX:  .byte 0

.segment "RODATA"
CMD1:   .byte 4,"stop"
CMD2:   .byte 5,"start"
        .byte 0

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

    ldx #0
    ldy #23
    jsr MVCRSR
    lda #'r'
    jsr CHROUT
    lda #'e'
    jsr CHROUT
    lda #'a'
    jsr CHROUT
    lda #'d'
    jsr CHROUT
    lda #'y'
    jsr CHROUT
    ldx #0
    ldy #24
    jsr MVCRSR
    lda #']'
    jsr CHROUT
    ldx #0
    stx LINELEN
    stx CRSRPOS
    jsr CRSRON

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
    cmp #96     ;pomijam wciśnięcia
    bcs get_next_key
    cmp #32     ;na razie znaki sterujące pomijam
    bcc znaki_sterujace
    pha
    jsr CRSROFF
    pla
    ldx LINELEN
    cpx #38
    bcs :+++         ;skończyło się miejsce więc milcząco ignoruję
    pha
    lda CRSRPOS
    cmp LINELEN
    beq :++          ;przesuwanie nie jest potrzebne

    ldx #38
:   lda $6000+24*40,x
    sta $6000+24*40+1,x
    dex
    cpx CRSRPOS
    bne :-

:   ldx CRSRPOS
    inx
    ldy #24
    jsr MVCRSR
    pla
    jsr CHROUT
    inc LINELEN
    inc CRSRPOS
:   jsr CRSRON
    jmp get_next_key

; --- program reaguje na następujące znaki:
; CRSR LEFT(30), CRSR RIGHT(29), DEL (20), HOME (19), RETURN (13) 
znaki_sterujace:
    cmp #30
    beq to_jest_crsr_left
    cmp #29
    beq to_jest_crsr_right
    cmp #20
    beq to_jest_del
    cmp #19
    beq to_jest_home
    cmp #13
    beq to_jest_return
    jmp get_next_key

to_jest_crsr_left:
    jsr CRSROFF
    lda CRSRPOS
    cmp #0
    beq :+
    dec CRSRPOS
:   jsr CRSRON
    jmp get_next_key

to_jest_crsr_right:
    jsr CRSROFF
    lda CRSRPOS
    cmp LINELEN
    beq :+
    inc CRSRPOS
:   jsr CRSRON
    jmp get_next_key

to_jest_del:
    jsr CRSROFF
    lda CRSRPOS
    cmp LINELEN
    beq :++

    dec LINELEN
    ldx CRSRPOS
:   lda $6000+24*40+2,x
    sta $6000+24*40+1,x
    inx
    cpx #38
    bne :-

:   jsr CRSRON
    jmp get_next_key

to_jest_home:
    jsr CRSROFF
    lda CRSRPOS
    cmp #0
    beq :+
    lda  #0
    sta CRSRPOS
:   jsr CRSRON
    jmp get_next_key

to_jest_return:
    jsr CRSROFF
    lda LINELEN
    sta CMDLEN
    jsr MOVEUP
    lda CMDLEN
    beq :+          ;nic do roboty
    jsr DOCMD
:   jsr CRSRON
    jmp get_next_key
.endproc

.proc CRSROFF
    lda #20
    sta BLINKCNT
    ldx CRSRPOS
    lda $6000+24*40+1,x
    and #$BF
    sta $6000+24*40+1,x
    lda #5
    sta $D800+24*40+1,x
    rts
.endproc

.proc CRSRON
    lda #20
    sta BLINKCNT
    ldx CRSRPOS
    lda $6000+24*40+1,x
    ora #$40
    sta $6000+24*40+1,x
    lda #0
    sta $D800+24*40+1,x
    rts
.endproc

.proc CRSRNEG
    lda #20
    sta BLINKCNT
    ldx CRSRPOS
    lda $6000+24*40+1,x
    eor #$40
    sta $6000+24*40+1,x
    lda $D800+24*40+1,x
    eor #5
    sta $D800+24*40+1,x
    rts
.endproc

.proc DOCMD
    ldx #0          ;ustawiam się na początku wiersza polecenia
    lda #<CMD1
    sta CMDPTR
    lda #>CMD1
    sta CMDPTR+1
    jsr CHKCMD
    bcc :+
    jsr GETCHARFROMSCREEN
    cmp #$20
    inx
    jsr GETCHARFROMSCREEN
    cmp #'1'
    bcc invalid_command
    cmp #'7'
    bcs invalid_command
    sec
    sbc #'0'
    jsr STOPJOB
    rts

:   lda #<CMD2
    sta CMDPTR
    lda #>CMD2
    sta CMDPTR+1
    jsr CHKCMD              ;X jest już ustawione
    bcc invalid_command
    jsr GETCHARFROMSCREEN
    cmp #$20
    inx
    jsr GETCHARFROMSCREEN
    cmp #'s'
    beq uruchom_sun
    cmp #'m'
    beq uruchom_moon
    cmp #'t'
    beq uruchom_town
    jmp invalid_command

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
    jsr MOVEUP
    rts
.endproc

;---------------------------
; input: X - pozycja w wierszu polecenia
; output: X - jest na literze za poprawną komendą albo na początkowej literze jeśli to nie jest ta komenda
;         CF=1 to jest ta komenda, CF=0 to nie jest ta komenda
;
.proc CHKCMD
    txa
    pha
    ldy #0
    lda (CMDPTR),y
    sta PATERLEN
    bne :++             ;to jest skok bezwzględny

:   jsr GETCHARFROMSCREEN
    iny
    cmp (CMDPTR),y
    bne :++             ;litera się nie zgadza, to źle
    inx
    cpy PATERLEN
    bcs :+++            ;Y jest równe długości wzorca, to dobrze bo wszystkie litery się zgadzały
:   cpx CMDLEN
    bcc :--             ;nie koniec więc szukam dalej
:   pla
    tax
    clc     ;to nie jest ta komenda
    rts

:   pla     ;znalazłem i CF jest już ustawione
    rts
.endproc

.proc MOVEUP
    ldx #39
:   lda $6000+24*40,x
    sta $6000+23*40,x
    lda #$20
    sta $6000+24*40,x
    lda $D800+24*40,x
    sta $D800+23*40,x
    lda #5              ;zielone litery  na pasku stanu i konsoli
    sta $D800+24*40,x
    dex
    bpl :-
    ldx #0
    ldy #24
    jsr MVCRSR
    lda #']'
    jsr CHROUT
    ldx #0
    stx LINELEN
    stx CRSRPOS
    rts
.endproc

;-----------------------------
; input: X - pozycja litery na ekranie
; output: A - lista ASCII, X - niezmienione, Y - niezmienione
.proc GETCHARFROMSCREEN
    lda $6000+23*40+1,x     ;bieże z linii 23 bo komenda właśnie została podniesiona
    cmp #32
    bcs :+
    clc
    adc #64
:   rts
.endproc