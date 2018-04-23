;---------------------------------------------------------- 
; sekwencja uruchamiająca program bees

.import INITT, CLST, FILLCT, TXTPAGE, JiffyClock, WAIT, STARTJOB

.segment "ZEROPAGE":zeropage
NPTR:  .res 2
NRSLUP: .res 1

.segment "DATA"
SLUPKI:   .byte 20,21,24,28,30,31,28,27,27,30,   35,40,48,54,55,55,56,57,60,65,   64,63,57,52,43,38,32,27,22,21,   18,17,17,18,19,20,22,21,21,20

.segment "DATA"
KULAX:   .word 160
KULAY:   .byte 100

.segment "RODATA"
KONCOWKI:  .byte 227,247,248,98,121,111,100,32,160
BITYZAP:   .byte $01,$02,$04,$08,$10,$20,$40,$80
BITYZGA:   .byte $FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F

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
    .org $0801

    .word $080D       ;wskaźnik to następnej linii
    .word 2018        ;numer linii i jednocześnie rok powstania
    .byte $9E         ;SYS token
    .asciiz "(2063)"  ;SYS argument
    .word 0           ;wskaźnik na następną linię, $0000 oznacza, że jest to ostania linia

    ldx #$FF
    txs
    cld               ; i nigdy więcej nie włączaj
    jsr INITT

    lda #$20          ;niepotrzebne ponowne czyszczenie
    jsr CLST
    lda #$05          ;domyślne kolory C64 po włączeniu
    jsr FILLCT

    lda #>TASK2       ;będę wracał przez RTI więc TASK2 a nie TASK2-1
    ldx #<TASK2
    jsr STARTJOB

    jmp TASK1

;*********************************************************
; TASK No 1

.segment "CODE"
.proc DRAW_SCEEN
    lda #<(24*40)
    sta NPTR
    lda TXTPAGE
    clc
    adc #>(24*40)
    sta NPTR+1      ;będzie $6300 albo $6700

    lda #0          ;numer kolumny
    sta NRSLUP

nastepny_slupek:
    ldx #8          ;pętla po liniach licząc od dołu
 
:   txa             ;decyzja co wstawić: X+8>=W -> 32, X>=W -> K, 32
    ldy NRSLUP
    sec
    sbc SLUPKI,y
    ldy #8
    bcc :+          ; to grunt
    tay
    cmp #8
    bcc :+          ; to końcówka gruntu
    ldy #7          ; to niebo 
:   lda KONCOWKI,y
    ldy #0
    sta (NPTR),y
    lda NPTR        ;bloczek wyżej
    sec
    sbc #40
    sta NPTR
    lda NPTR+1
    sbc #0
    sta NPTR+1

    txa
    clc
    adc #8
    tax
    cpx #200          ;wspinam się na górę
    bne :--

    lda NPTR        ;nastepna kolumna
    clc
    adc #<961
    sta NPTR
    lda NPTR+1
    adc #>961
    sta NPTR+1

    inc NRSLUP
    lda NRSLUP
    cmp #40
    bcc nastepny_slupek
    rts
.endproc

.proc MOVEOBJS
    ldx #0          ;przesunięcie słupków w lewo
    ldy #39
    lda SLUPKI,x
    pha
:   lda SLUPKI+1,x
    sta SLUPKI,x
    inx
    dey
    bne :-
    pla
    sta SLUPKI,x
    rts
.endproc

.proc TASK1
:   jsr DRAW_SCEEN
    ldy #14
    jsr WAIT
    jsr MOVEOBJS
    jmp :-
.endproc


;*********************************************************
; TASK No 2

.segment "CODE"
.proc TASK2
    ; init sprite
    ldx #62         ;copy sprite
:   lda SPRITE1,x
    sta $6800,x
    dex
    bpl :-
    ldx #0          ;X = sprit number
    lda #$A0        ;kształt pod adresem $2800 w ramach VIC
    sta $63F8,x     ;8 wskźników na definicje sprita
    lda #7          ;sprite color
    sta $D027,x

    lda $D010       ;MSB bit of x coordinate
    and BITYZGA,x
    sta $D010
    lda $D015       ;enable sprite
    ora #$01
    sta $D015
    lda $D01D       ;expand X off
    and BITYZGA,x
    sta $D01D
    lda $D017       ;expand Y off
    and BITYZGA,x
    sta $D017
    lda $D01C       ;Multi-color off
    and BITYZGA,x
    sta $D01C
    lda $D01B       ;sprite 0 protity, MOB in front
    ora BITYZAP,x
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
    ldx #0          ; X = 2 * sprite number
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
    and BITYZGA,x
    ldy KULAX+1
    beq :+
    ora BITYZAP,x
:   sta $D010
    rts
.endproc