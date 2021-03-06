;-----------------------------------------------------------
; Inicjuje konsolę, czyści pasek stanu i dwa wiersze poleceń
; pisze w wierszu polecenia słowo "READY." i w ostaniej linii
; przygotowuj prompt.
;
; Założenia upraszające.
; 1. Promp, czyli edycja wiersza _zawsze_ odbywa sie w ostatniej
;    linii.
; 2. Odczyt wyedytowanego polecenia zawsze odbywa się z linii
;    przedostatniej (bo po naciśnięciu RETURN, linia ostatnia
;    podjeżdża do góry a do piero potem następuje interpretacja
;    polecenia.
; 3. Konsola nie dubluje wpisywanych liter w pamięci i na ekranie.
;    Podobnie jak w BASIC-u, tu też edycja odbywa się wyłącznie na ekranie
;    i dopiero po wciśnięciu RETURN, następuje odczyt liter z ekranu.
; 4. 

.export CONSINIT, LINELEN, CMDLINE
.import MVCRSR, STROUT, CRSRON, CONSLINEOUT, CURCOL

.segment "BSS"
LINELEN:  .res 1
CMDLINE:  .res 38

.segment "RODATA"
READYSTR:   .byte "ready.",0

.segment "CODE"
.proc CONSINIT
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
    stx LINELEN

    ldx #0
    ldy #23
    jsr MVCRSR
    lda #<READYSTR
    ldy #>READYSTR
    jsr STROUT
    ldx #1
    ldy #24
    jsr MVCRSR
    jsr CONSLINEOUT
    jsr CRSRON
    rts
.endproc
