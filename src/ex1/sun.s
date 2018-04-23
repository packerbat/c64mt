;---------------------------------------------------------- 
; sekwencja uruchamiająca program bees

.export TASK2
.import WAIT, BITSOFF, BITSON

SPRITENR = 0
SHAPENR = $A0

.segment "DATA"
KULAX:   .word 160
KULAY:   .byte 100

.segment "RODATA"
.linecont +
SPRITE1: .byte \
  %00000000,%00111100,%00000000, \
  %00000001,%11111111,%10000000, \
  %00000111,%11111111,%11100000, \
  %00001111,%11111111,%11110000, \
  %00011111,%11111111,%11111000, \
  %00111111,%11111111,%11111100, \
  %01111111,%11111111,%11111110, \
  %01111111,%11111111,%11111110, \
  %11111111,%11111111,%11111111, \
  %11111111,%11111111,%11111111, \
  %11111111,%11111111,%11111111, \
  %11111111,%11111111,%11111111, \
  %11111111,%11111111,%11111111, \
  %01111111,%11111111,%11111110, \
  %01111111,%11111111,%11111110, \
  %00111111,%11111111,%11111100, \
  %00011111,%11111111,%11111000, \
  %00001111,%11111111,%11110000, \
  %00000111,%11111111,%11100000, \
  %00000001,%11111111,%10000000, \
  %00000000,%00111100,%00000000
.linecont -

.segment "CODE"
.proc TASK2
    ; init sprite
    ldx #62         ;copy sprite
:   lda SPRITE1,x
    sta $6800,x
    dex
    bpl :-
    ldx #SPRITENR   ;X = sprit number
    lda #SHAPENR    ;kształt pod adresem $2800 w ramach VIC
    sta $63F8,x     ;8 wskźników na definicje sprita
    lda #7          ;sprite color
    sta $D027,x

    lda $D010       ;MSB bit of x coordinate
    and BITSOFF,x
    sta $D010
    lda $D015       ;enable sprite
    ora BITSON,x
    sta $D015
    lda $D01D       ;expand X off
    and BITSOFF,x
    sta $D01D
    lda $D017       ;expand Y off
    and BITSOFF,x
    sta $D017
    lda $D01C       ;Multi-color off
    and BITSOFF,x
    sta $D01C
    lda $D01B       ;sprite 0 protity, MOB in front
    ora BITSON,x
    sta $D01B

:   jsr SETSPRITEPOS
    ldy #14
    jsr WAIT

    clc
    lda KULAX       ;zwiększ X o 1
    adc #1
    sta KULAX
    lda KULAX+1
    adc #0
    sta KULAX+1

    sec             ;czy większe od 320+24
    lda KULAX
    sbc #<344
    lda KULAX+1
    sbc #>344
    bcc :+

    lda KULAX       ;tak przeba wrócić na początek ekranu
    sbc #<344
    sta KULAX
    lda KULAX+1
    sbc #>344
    sta KULAX+1

:   clc
    lda KULAY
    adc #1
    sta KULAY
    jmp :--
.endproc

.proc SETSPRITEPOS
    ldx #SPRITENR          ; X = 2 * sprite number
    txa
    asl
    tax
    lda KULAX       ;x position
    sta $D000,x
    lda KULAY       ;y position
    sta $D001,x
    txa
    lsr
    tax
    lda $D010
    and BITSOFF,x
    ldy KULAX+1
    beq :+
    ora BITSON,x
:   sta $D010
    rts
.endproc