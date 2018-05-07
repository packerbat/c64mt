;---------------------------------------------------------- 
; Procedura wyświetla liczbę hex w górnym pasku ekranu
; poczynając od pozycji podanej w X. Procedura działa
; wyłącznie w trybie Text Single Buffer.
;
; input: A-liczba, X-pozycja w linii 0..38
; output: X-pozycja za liczbą, Y=0

.export output_dec

.segment "BSS"
NUM10:    .res 1
REM10:    .res 1
STRDEC:   .res 3

.segment "CODE"
.proc output_dec
    sta NUM10
    lda #' '
    sta STRDEC
    sta STRDEC+1
    sta STRDEC+2

    jsr div8bitby10
    lda REM10
    clc
    adc #'0'
    sta STRDEC+2
    lda NUM10
    beq :+

    jsr div8bitby10
    lda REM10
    clc
    adc #'0'
    sta STRDEC+1
    lda NUM10
    beq :+
    clc
    adc #'0'
    sta STRDEC

:   lda STRDEC
    sta $6000,x
    inx
    lda STRDEC+1
    sta $6000,x
    inx
    lda STRDEC+2
    sta $6000,x
    inx
    rts
.endproc

.proc div8bitby10
    lda #0
    sta REM10       ;wyzerowanie reszty
    ldy #8
:   asl NUM10       ;najstarszy bit dzielnej ląduje na najmłoszym bicie reszty i jednocześnie najstarszy bit wyniku (na razie 0) ląduje na najmłodzym bicie NUMERATOR (na końcu stanie się najstarszym)
    rol REM10
    sec
    lda REM10       ;proba odjęcia R-D
    sbc #10
    bcc :+
    inc NUM10       ;R>=D więc wpycham CF=1 do wyniku, wiem, że najmłodzy bit jest 0 więc bezpiecznie mogę użyć INC
    sec
    lda REM10       ; a teraz rzeczywiste odjęcie R-D
    sbc #10
    sta REM10
:   dey
    bne :--
    rts
.endproc