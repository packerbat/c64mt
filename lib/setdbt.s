;------------------------------------
; włącza tryb podwójnego bufforowanie ekranu (domyślnie wyłączone)
; i ustawia TXTPAGE na stronę widocznę (gdy wyłączymy) albo na stronę
; niewidoczną (gdy włączymy double buffer)
;
; input: A - 1=double buffer on, 0=double buffer off
; output: A=TXTPAGE, X=unchanged, Y=unchanged, DBLBUF=1 or 0, VIDPAGE=$60 or $64
; stack: 0
; zeropage: 0
; reentrant: no (TXTDBLBUF and TXTPAGE should be changed in critical section)

.export SETDBT, TXTDBLBUF
.import TXTPAGE

.segment "DATA"
TXTDBLBUF:   .byte $00     ;default no

.segment "CODE"
.proc SETDBT     ;A=1 or 0
    and #$01
    sta TXTDBLBUF
    lsr             ;CF=1 double buffer on
    lda $D018    ;VIC Memory Control Register
    bcc :+
    eor #$10     ;first time after NRM: 1000xxxx -> 1001xxxx
:   ror
    ror          ;xx1000xx -> xx1000xx
    and #$3C
    ora #$40     ;to da adres ekranu tekstowego $6000 albo $6400
    sta TXTPAGE
    rts
.endproc
