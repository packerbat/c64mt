;------------------------------------
; obsługa tokena LINE rysującego odcinek od XP,YP do XK,YK
; w trybie rysowania PTYP
;
; zmienne lokalne: KX, KY, DX, DY, PM
; input: XP, YP, XK, YP, PTYP
; output: XP=XK, YP=YK
;

.export LINE
.import POT, XP, YP

.segment "ZEROPAGE": zeropage
KX:   .res 2
KY:   .res 2
DX:   .res 2
DY:   .res 2
PM:   .res 2

.segment "DATA"
XK:    .word 0
YK:    .word 0

.segment "CODE"
.proc LINE
    ldx #$01
    stx KX
    stx KY
    dex
    stx KX+1
    stx KY+1        ;KX = 1, KY = 1
    dex
    sec
    lda XK
    sbc XP
    sta DX
    lda XK+1
    sbc XP+1
    sta DX+1        ;DX = XK-XP
    bpl :+
    stx KX          ;KX = -1
    stx KX+1
    sec
    lda XC
    sbc XK
    sta DX
    lda XP+1
    sbc XK+1
    sta DX+1        ;DX = XP-XK
:   sec
    lda YK
    sbc YP
    sta DY
    lda YK+1
    sbc YP+1
    sta DY+1
    bpl :+
    stx KY
    stx KY+1        ;KY = -1
    sec
    lda YP
    sbc YK
    sta DY
    lda YP+1
    sbc YK+1
    sta DY+1        ;DY = YK-YP
:   asl DX
    rol DX+1        ;DX *= 2
    asl DY
    rol DY+1        ;DY *= 2
    lda DX
    cmp DY
    lda DX+1
    sbc DY+1
    bcc iterate_by_Y

iterate_by_X:
    lda DX+1
    lsr
    sta PM+1
    lda DX
    ror
    sta PM        ; PM = DX/2
:   lda XP
    ldy XP+1
    cmp XK
    bne :+
    cpy XK+1
    bne :+
    rts         ;XK=XP czyli koniec rysowania

:   sec
    lda PM
    sbc DY
    sta PM
    lda PM+1
    sbc DY+1
    sta PM+1        ;PM -= DY
    bpl :+
    clc
    lda YP
    adc KY
    sta YP
    lda YP+1
    adc KY+1
    sta YP+1        ;YP += KY
    clc
    lda PM
    adc DX
    sta PM
    lda PM+1
    adc DX+1
    sta PM+1        ;PM += DX
:   clc
    lda XP
    adc KX
    sta XP
    lda XP+1
    adc KX+1
    sta XP+1        ;XP += KX
    jsr POT
    jmp :---

iterate_by_Y:
    lda DY+1
    lsr
    sta PM+1
    lda DY
    ror
    sta PM        ; PM = DY/2
:   lda YP
    ldy YP+1
    cmp YK
    bne :+
    cpy YK+1
    bne :+
    rts         ;YK=YP czyli koniec rysowania

:   sec
    lda PM
    sbc DX
    sta PM
    lda PM+1
    sbc DX+1
    sta PM+1        ;PM -= DX
    bpl :+
    clc
    lda XP
    adc KX
    sta XP
    lda XP+1
    adc KX+1
    sta XP+1        ;XP += KX
    clc
    lda PM
    adc DY
    sta PM
    lda PM+1
    adc DY+1
    sta PM+1        ;PM += DY
:   clc
    lda YP
    adc KY
    sta YP
    lda YP+1
    adc KY+1
    sta YP+1        ;XP += KX
    jsr POT
    jmp :---
.endproc

