;-----------------------------------------------------------
; Ta procedura poddaje analizie odczytany klawisz z bufora
; klawiatury. Jeśli obsłuży klawisz to ustawia CF=0
; jeśli nie wie co zrobić z klawiszem, to zostawia go w A
; i ustawia CF=1

; Procedura reaguje na następujące znaki sterujące:
;    CRSR LEFT(30),
;    CRSR RIGHT(29),
;    DEL (20),
;    HOME (19)
; 

.export CONSKEYS
.import CRSRON, CRSROFF, CURCOL, LINELEN, MVCRSR, CHROUT, CONSLINEOUT, CMDLINE

;-------------------------------------
; pobiera i analizyje klawisze zgromadzone w buforze klawiatury
; tak długo aż opróżni bufor.
;
.segment "CODE"
.proc CONSKEYS
    cmp #96                      ;pomijam wciśnięcia
    bcs nie_dotyczy_konsoli
    pha
    jsr CRSROFF
    pla
    cmp #32
    bcc znaki_sterujace
    ldx LINELEN
    cpx #38
    bcs klawisz_obsluzony        ;skończyło się miejsce więc milcząco ignoruję
    ldx CURCOL
    dex
    cpx LINELEN
    beq :++          ;przesuwanie nie jest potrzebne

    pha
    ldx LINELEN
    inx
:   lda CMDLINE-2,x
    sta CMDLINE-1,x
    dex
    cpx CURCOL
    bne :-
    pla

:   ldx CURCOL
    dex
    sta CMDLINE,x
    inc LINELEN
    jsr CONSLINEOUT
    inc CURCOL

klawisz_obsluzony:
    jsr CRSRON
    clc
    rts

nie_dotyczy_konsoli:
    pha
    jsr CRSRON
    pla
    sec
    rts                 ;konsola bo 

; --- program reaguje na następujące znaki:
znaki_sterujace:
    cmp #30
    bne moze_crsr_right
    lda CURCOL
    cmp #1
    beq :+
    dec CURCOL
:   jmp klawisz_obsluzony

moze_crsr_right:
    cmp #29
    bne moze_home
    ldx CURCOL
    dex
    cpx LINELEN
    beq :+
    inc CURCOL
:   jmp klawisz_obsluzony

moze_home:
    cmp #19
    bne moze_del
    lda CURCOL
    cmp #1
    beq :+
    lda #1
    sta CURCOL
:   jmp klawisz_obsluzony

moze_del:
    cmp #20
    bne nie_dotyczy_konsoli
    lda LINELEN
    beq :++
    ldx CURCOL
    cpx LINELEN     ;jestem na ostatnim znaku, tylko skracam i nic nie przesuwam
    beq :++
    dex
    cpx LINELEN     ;jestem za ostatnim znakiem, nic nie robię
    beq :+++

:   lda CMDLINE+1,x       ;przesuwanie jest konieczne
    sta CMDLINE,x
    inx
    cpx LINELEN
    bne :-

:   dec LINELEN
    jsr CONSLINEOUT
:   jmp klawisz_obsluzony
.endproc
