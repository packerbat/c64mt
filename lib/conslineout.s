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

.export CONSLINEOUT
.import CRSPTR:zeropage, LINELEN, CMDLINE

.segment "CODE"
.proc CONSLINEOUT
    ldy #0
    lda #(']'-$40)
    sta (CRSPTR),y
    ldx #0
    lda LINELEN
    beq :+++            ;tylko czyszczenie
:   iny
    lda CMDLINE,x
    cmp #$40
    bcc :+
    sbc #$40
:   sta (CRSPTR),y
    inx
    cpx LINELEN
    bne :--

:   lda #$20
:   iny
    sta (CRSPTR),y
    inx
    cpx #39
    bne :-

    rts
.endproc
