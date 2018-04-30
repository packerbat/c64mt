;------------------------------------
; Procedura CMDPTR sprawdza czy na ekranie pod wskazaną
; pozycją przez X jest jedna z komend podanych w tablicy.
; Tablica komend jest w formacie: <cmd1 length><cmd1 name><cmd2 length><cmd2 name>...<cmdn length><cmdn name>0
;
; locals: CMDPTR - adres tablicy, CMDNUM - numer komendy, CMDXPOS - początkowa pozycja na ekranie, PATERLEN - długość sprawdzanej komendy
; input: X - pozycja w wierszu polecenia, CMDLEN - liczba liter na ekranie, A/Y=adres tablicy
; output: X - jest na literze za poprawną komendą albo na początkowej literze jeśli to nie jest ta komenda
;         CF=1 to jest ta komenda, CF=0 to nie jest ta komenda
;         A=numer komendy
; stack: 2
; zeropage: 2
; reentrant: no

.export CHKCMD
.import CMDLINE, LINELEN

.segment "ZEROPAGE":zeropage
CMDPTR:   .res 2

.segment "BSS"
PATERLEN: .res 1
CMDNUM:   .res 1
CMDXPOS:  .res 1

.segment "CODE"
.proc CHKCMD
    sta CMDPTR
    sty CMDPTR+1
    lda #0
    sta CMDNUM
    stx CMDXPOS
    ldy #0
    lda (CMDPTR),y

nastepna_komenda:
    sta PATERLEN
:   lda CMDLINE,x
    iny
    cmp (CMDPTR),y
    bne to_nie_ta_komenda             ;litera się nie zgadza, to źle
    inx
    cpy PATERLEN
    bcs wszystkie_litery_zgodne       ;Y jest równe długości wzorca, to dobrze bo wszystkie litery się zgadzały
    cpx LINELEN
    bcc :-              ;nie koniec więc szukam dalej

to_nie_ta_komenda:
    ldx CMDXPOS
    inc CMDNUM
    ldy #0
    lda (CMDPTR),y
    sec                 ;to da długosc komendy + 1
    adc CMDPTR
    sta CMDPTR
    lda #0
    adc CMDPTR+1
    sta CMDPTR+1        ;CMDPTR wskazuje na następną komendę w tablicy
    lda (CMDPTR),y
    bne nastepna_komenda
    ldx CMDXPOS
    clc                 ;skończyła się tablica to nie jest ta komenda
    rts

wszystkie_litery_zgodne:
    lda CMDNUM          ;znalazłem i CF jest już ustawione
    rts
.endproc

