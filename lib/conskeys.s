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
.import CRSRON, CRSROFF, CRSRPOS, LINELEN, MVCRSR, CHROUT

;-------------------------------------
; pobiera i analizyje klawisze zgromadzone w buforze klawiatury
; tak długo aż opróżni bufor.
;
.segment "CODE"
.proc CONSKEYS
    cmp #96     ;pomijam wciśnięcia
    bcs nie_dotyczy_konsoli
    cmp #32     ;na razie znaki sterujące pomijam
    bcc znaki_sterujace
    pha
    jsr CRSROFF
    pla
    ldx LINELEN
    cpx #38
    bcs klawisz_obsluzony         ;skończyło się miejsce więc milcząco ignoruję
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

klawisz_obsluzony:
    jsr CRSRON
    clc
    rts

nie_dotyczy_konsoli:
    sec
    rts                 ;konsola bo 

; --- program reaguje na następujące znaki:
znaki_sterujace:
    cmp #30
    beq to_jest_crsr_left
    cmp #29
    beq to_jest_crsr_right
    cmp #20
    beq to_jest_del
    cmp #19
    bne nie_dotyczy_konsoli

to_jest_home:
    jsr CRSROFF
    lda CRSRPOS
    cmp #0
    beq :+
    lda  #0
    sta CRSRPOS
:   jmp klawisz_obsluzony

to_jest_crsr_left:
    jsr CRSROFF
    lda CRSRPOS
    cmp #0
    beq :+
    dec CRSRPOS
:   jmp klawisz_obsluzony

to_jest_crsr_right:
    jsr CRSROFF
    lda CRSRPOS
    cmp LINELEN
    beq :+
    inc CRSRPOS
:   jmp klawisz_obsluzony

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
:   jmp klawisz_obsluzony
.endproc
