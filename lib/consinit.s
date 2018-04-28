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

.export CONSINIT, LINELEN
.import MVCRSR, CHROUT, CRSRON, CRSRPOS

.segment "BSS"
LINELEN:  .res 1

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
    lda #'.'
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
.endproc
