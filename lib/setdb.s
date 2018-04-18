;------------------------------------
; włącza tryb podwójnego bufforowanie ekranu (domyślnie wyłączone)
; i ustawia VIDPAGE na stronę widocznę (gdy wyłączymy) albo na stronę
; niewidoczną (gdy włączymy double buffer)
;
; input: A - 1=double buffer on, 0=double buffer off
; output: A=VIDPAGE, X=unchanged, Y=unchanged, DBLBUF=1 or 0, VIDPAGE=$80 or $A0
; stack: 0
; zeropage: 0
; reentrant: no ($DD00, DBLBUF and VIDPAGE should be changes in critical section)

.export SETDB, DBLBUF
.import VIDPAGE

.segment "DATA"
DBLBUF:   .byte $00     ;default no

.segment "CODE"
.proc SETDB     ;A=1 or 0
    and #$01
    sta DBLBUF
    lsr             ;CF=1 double buffer on
    lda $DD00       ;CIA#2 Data Port A
    bcs :+
    eor #$03     ;first time after HGR: xxxxxx10 -> xxxxxx01
:   ror
    ror
    ror          ;01xxxxxx or 10xxxxxx
    and #$C0
    clc
    adc #$20     ;to da adres ekranu graficznego $6000 albo $A000
    sta VIDPAGE
    rts
.endproc
