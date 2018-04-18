;------------------------------------
; zmienia strony dla trybu wysokiej rozdzielczości
;
; pamięć $DD00 i VIDPAGE powinny być zmieniane atomowo a to procedura o to nie dba
;
; input: -
; output: A=modified, X=unchanged, Y=unchanged
; stack: 0
; zeropage: 0
; reentrant: no

.export SWAPSCR, VIDPAGE
.import DBLBUF

.segment "DATA"
VIDPAGE:  .byte $60

.segment "CODE"
.proc SWAPSCR
    lda DBLBUF
    beq :+
    lda $DD00    ;CIA#2 Data Port A
    eor #$03     ;first time after HGR: xxxxxx10 -> xxxxxx01
    sta $DD00
    ror          ;ponieważ bity są odwrócone więc w A mam już bity niewidocznego bufora wideo
    ror
    ror          ;01xxxxxx or 10xxxxxx
    and #$C0
    clc
    adc #$20     ;to da adres ekranu graficznego $6000 albo $A000
    sta VIDPAGE
:   rts
.endproc
