;------------------------------------
; rysuje jeden pixel na ekranie graficznym
; ta procedura nie zmienia koloru
; kolor trzeba ustawić przed lub po narysowaniu za pomocą FILL
;
; zmienne lokalne: AD
; input: XP, YP, PTYP, HGRPAGE

.export POT, XP, YP, PTYP
.import VIDPAGE

.segment "ZEROPAGE": zeropage
AD:   .res 2

.segment "DATA"
PTYP:  .byte 1    ;0=AND 1=OR 2=XOR
XP:    .word 0
YP:    .word 0

.segment "CODE"
.proc POT
    ;---- validate input, ten fragment powienin być opjonalny
    lda YP+1
    bne nic_nie_rysuj       ;ZF=0 when YP >= 256
    lda YP
    cmp #$c8
    bcs nic_nie_rysuj       ;CF=1 when YP >= 200
    lda XP
    cmp #$40
    lda XP+1
    sbc #1
    bcs nic_nie_rysuj       ;CF=1 when XP >= 320

    ;--- oblicz: AD+1,AD = (YP \ 8) * 320
    lda #0
    sta AD+1        ;AD+1 = 0
    lda YP
    and #$F8        ;A = YP \ 8 * 8         ;numer wiersza * 8
    sta AD          ;AD+1,AD = AD+1,A = (YP \ 8) * 8
    asl
    rol AD+1
    asl
    rol AD+1        ;AD+1,A = (YP \ 8) * 32
    adc AD
    bcc :+
    inc AD+1        ;AD+1,A = (YP \ 8) * 32 + (YP \ 8) * 8
:   asl
    rol AD+1
    asl
    rol AD+1
    asl
    rol AD+1
    sta AD          ;AD+1,AD = (YP \ 8) * 256 + (YP \ 8) * 64   czyli  YP*320

    ;--- oblicz AD+1,AD = (YP \ 8) * 320 + (XP \ 8) * 8 + $4000,  X = XP % 8,  Y = YP % 8
    lda XP
    and #$F8        ;A = (XP \ 8) * 8
    adc AD
    sta AD
    lda XP+1
    adc AD+1
    adc VIDPAGE
    sta AD+1
    lda XP
    and #7          ;A = XP % 8
    tax
    lda YP
    and #7
    tay             ;Y = YP % 8             ;bajt w wierszu, on nie jest dodawany do adresu tylko uzywany jako indeks

    lda TBP,x       ;ukryte potęgowanie
    ldx PTYP        ;typ rysowania, 0 = neg/and (zgaś), 1 = or (zapal), 2 = xor (zaneguj)
    bne :+
    eor #$ff        ;PTYP=0 - turn off
    and (AD),y
    sta (AD),y
    rts

:   cpx #2
    beq :+          ;PTYP=1 - turn on
    ora (AD),y
    sta (AD),y
    rts

:   eor (AD),y      ;PTYP=2 - negate
    sta (AD),y
nic_nie_rysuj:
    rts
.endproc

.segment "RODATA"
TBP:    .byte 128,64,32,16,8,4,2,1