;------------------------------------
; Procedura DIVIDE24 dzieli dwie liczby 24-bitowe.
; Aktywna ekran (niekoniecznie widoczny) wskazuje zmienna TXTPAGE (typowo $60 albo $64)
;
; input: NUMERATOR 24-bity, DIVISOR 24-bit
; output: NUMERATOR 24-bit, REMAINDER 24-bit, DIVISOR=unchanged, Y=0, X=preserved
; stack: 0
; zeropage: 0
; reentrant: no
; przyjazne dla C bo nie zmienia X

.export DIV24, NUMERATOR, DIVISOR, REMAINDER

.segment "BSS"
NUMERATOR:    .res 3
DIVISOR:      .res 3
REMAINDER:    .res 3

.segment "CODE"
.proc DIV24
    lda #0
    sta REMAINDER       ;wyzerowanie reszty
    sta REMAINDER+1
    sta REMAINDER+2

    ldy #24
:   asl NUMERATOR       ;najstarszy bit dzielnej ląduje na najmłoszym bicie reszty i jednocześnie najstarszy bit wyniku (na razie 0) ląduje na najmłodzym bicie NUMERATOR (na końcu stanie się najstarszym)
    rol NUMERATOR+1
    rol NUMERATOR+2
    rol REMAINDER
    rol REMAINDER+1
    rol REMAINDER+2
    sec
    lda REMAINDER       ;proba odjęcia R-D
    sbc DIVISOR
    lda REMAINDER+1
    sbc DIVISOR+1
    lda REMAINDER+2
    sbc DIVISOR+2
    bcc :+
    inc NUMERATOR       ;R>=D więc wpycham CF=1 do wyniku, wiem, że najmłodzy bit jest 0 więc bezpiecznie mogę użyć INC
    sec
    lda REMAINDER       ; a teraz rzeczywiste odjęcie R-D
    sbc DIVISOR
    sta REMAINDER
    lda REMAINDER+1
    sbc DIVISOR+1
    sta REMAINDER+1
    lda REMAINDER+2
    sbc DIVISOR+2
    sta REMAINDER+2
:   dey
    bne :--
    rts
.endproc

