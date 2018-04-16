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
    lda $D018    ;CIA#2 Data Port A
    eor #$10     ;first time after NRM: 1000xxxx -> 1001xxxx
    sta $D018
    eor #$10     ;tu bity nie są odwrócone, więc trzeba odwórcić
    ror          ;ponieważ bity są odwrócone więc w A mam już bity niewidocznego bufora wideo
    ror          ;xx1000xx -> xx1000xx
    and #$3C
    clc
    adc #$1C     ;to da adres ekranu tekstowego $5C00 albo $9C00
    stx TXTPAGE
    lda #$70     ;%1000 0000 = video matrix base address 8=$6000, character base addres 0 to RAM $4000-$47FF
    sta $D018    ;VIC Memory Control Register, adres grafiki od $0400 do $07FF
:   rts
.endproc
