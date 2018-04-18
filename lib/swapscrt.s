;------------------------------------
; zmienia strony ekranu tekstowego
;
; pamięć $DD00 i VIDPAGE powinny być zmieniane atomowo a to procedura o to nie dba
;
; input: -
; output: A=modified, X=unchanged, Y=unchanged
; stack: 0
; zeropage: 0
; reentrant: yes in real cases

.export SWAPSCRT, TXTPAGE
.import TXTDBLBUF

.segment "DATA"
TXTPAGE:  .byte $60

.segment "CODE"
.proc SWAPSCRT
    lda TXTDBLBUF
    beq :+
    lda $D018    ;VIC Memory Control Register
    eor #$10     ;first time after NRM: 1000xxxx -> 1001xxxx
    sta $D018
    eor #$10     ;tu bity nie są odwrócone, więc trzeba odwórcić
    ror
    ror          ;1000xxxx -> xx1000xx
    and #$3C
    ora #$40     ;to da adres ekranu tekstowego $6000 albo $6400
    sta TXTPAGE
:   rts
.endproc
