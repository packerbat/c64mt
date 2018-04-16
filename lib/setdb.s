;------------------------------------
; włącza tryb podwójnego bufforowanie ekranu
;
; input: A - 1=double buffer on, 0=double buffer off
; output: A=modified, X=unchanged, Y=unchanged
; stack: 0
; zeropage: 0
; reentrant: yes

.export SETDB, DBLBUF

.segment "DATA"
DBLBUF:   .byte $00     ;$00 - nie,  $C0 - tak

.segment "CODE"
.proc SETDB     ;A=1 or 0
    and #$01
    beq :+
    lda #$C0
    sta DBLBUF
    rts

:   lda #$00
    sta DBLBUF
    rts
.endproc
