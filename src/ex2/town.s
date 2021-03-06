;---------------------------------------------------------- 
; Proces wyświetlający przesuwające się wieżowce
; 

.export TASK4, TOWNSLOT
.import TXTPAGE, STARTTIMER, STOPTIMER, SELECT, JOBDONE, TASK_STATE, CURRTASK

.segment "DATA"
SLUPKI:   .byte 8,8,8,0,12,12,4,4,4,4,   4,0,7,7,7,0,8,8,8,8,   0,14,14,14,16,16,16,13,13,13,   0,6,6,6,6,5,5,5,5,0

.segment "ZEROPAGE":zeropage
NPTR:  .res 2

.segment "DATA"
TOWNSLOT:   .byte 0

.segment "BSS"
LASTEVENTS:   .res 1

.segment "CODE"
.proc TASK4
    lda CURRTASK
    sta TOWNSLOT
    jsr CLRWIN

    lda #%11111111      ;zmiana litery $3f na segment wieżowca
    sta $4000+$3f*8+0
    sta $4000+$3f*8+1
    sta $4000+$3f*8+5
    sta $4000+$3f*8+6
    sta $4000+$3f*8+7
    lda #%11000111
    sta $4000+$3f*8+2
    sta $4000+$3f*8+3
    sta $4000+$3f*8+4

    jsr DRAW_SCEEN

    ldy #3
    lda #20
    jsr STARTTIMER

main_loop_TOWN:
    lda #$80
    jsr SELECT                  ;po powrocie w A będą flagi zdarzeń, które rzeczywiście miały miejsce
    sta LASTEVENTS

    lda #$80
    bit LASTEVENTS
    beq koniec_TOWN              ;wyszedł z SELECT ale nie ustawił flagi TIMER4 więc to KILL

    ldy TOWNSLOT
    lda TASK_STATE,y
    and #$40          ;test stop request
    bne koniec_TOWN

    jsr SCROLL_SCEEN
    jmp main_loop_TOWN

koniec_TOWN:
    ldy #3
    jsr STOPTIMER
    lda #0
    sta TOWNSLOT
    jmp JOBDONE
.endproc

.proc CLRWIN
    lda #40
    sta NPTR
    lda TXTPAGE
    sta NPTR+1      ;będzie $6300 albo $6700

    ldx #22         ;pętla po wierszach
:   ldy #0          ;pętla po kolumnach
    lda #$A0
:   sta (NPTR),y
    iny
    cpy #40
    bcc :-

    lda NPTR
    clc
    adc #40
    sta NPTR
    lda NPTR+1
    adc #0
    sta NPTR+1
    dex
    bne :--

    lda #<($D800+1*40)
    sta NPTR
    lda #>($D800+1*40)
    sta NPTR+1      ;będzie $D840

    ldx #22         ;pętla po wierszach
:   ldy #0          ;pętla po kolumnach
    lda #12
:   sta (NPTR),y
    iny
    cpy #40
    bcc :-

    lda NPTR
    clc
    adc #40
    sta NPTR
    lda NPTR+1
    adc #0
    sta NPTR+1
    dex
    bne :--
    rts
.endproc

.proc DRAW_SCEEN
    lda #<(22*40)
    sta NPTR
    lda TXTPAGE
    clc
    adc #>(22*40)
    sta NPTR+1      ;będzie $6300 albo $6700

    lda #0
:   tay
    ldx SLUPKI,y    ;pętla po liniach licząc od dołu
 
    pha
    lda NPTR+1
    pha
    lda NPTR
    pha
    cpx #0
    beq :++

:   lda #$3f+$80
    ldy #0
    sta (NPTR),y
    lda NPTR        ;bloczek wyżej
    sec
    sbc #40
    sta NPTR
    lda NPTR+1
    sbc #0
    sta NPTR+1
    dex
    bne :-

:   pla
    sta NPTR
    pla
    sta NPTR+1
    lda NPTR        ;nastepna kolumna
    clc
    adc #1
    sta NPTR
    lda NPTR+1
    adc #0
    sta NPTR+1

    pla
    clc
    adc #1
    cmp #40
    bcc :---
    rts
.endproc

.proc SCROLL_SCEEN
    lda #<(1*40)
    sta NPTR
    lda TXTPAGE
    clc
    adc #>(1*40)
    sta NPTR+1      ;będzie $6300 albo $6700

    lda #22         ;pętla po wierszach
:   pha
    ldy #0          ;pętla po liniach licząc od dołu
    lda (NPTR),y
    pha             ;zapamietanie pierwszego klocka, żeby go umieścić na końcu
 
:   iny             ;kopiowanie klocków
    lda (NPTR),y
    dey
    sta (NPTR),y
    iny
    cpy #40
    bcc :-

    pla
    dey
    sta (NPTR),y      ;pierwszy klocek na końcu

    lda NPTR
    clc
    adc #40
    sta NPTR
    lda NPTR+1
    adc #0
    sta NPTR+1
    pla
    sec
    sbc #1
    bne :--
    rts
.endproc
