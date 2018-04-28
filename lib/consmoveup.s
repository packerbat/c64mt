;-----------------------------------------------------------
; Procedura powstała na potrzeby konsoli i jej zadaniem
; jest podnieść ostanią linię do góry, wyczyścić ostanią
; linię i namalować tam promp
; 

.export CONSMOVEUP
.import MVCRSR, CHROUT, LINELEN, CRSRPOS

;-----------------------------
; input: X - pozycja litery na ekranie
; output: A - lista ASCII, X - niezmienione, Y - niezmienione
.proc CONSMOVEUP
    ldx #39
:   lda $6000+24*40,x
    sta $6000+23*40,x
    lda #$20
    sta $6000+24*40,x
    lda $D800+24*40,x
    sta $D800+23*40,x
    lda #5              ;zielone litery  na pasku stanu i konsoli
    sta $D800+24*40,x
    dex
    bpl :-
    ldx #0
    ldy #24
    jsr MVCRSR
    lda #']'
    jsr CHROUT
    ldx #0
    stx LINELEN
    stx CRSRPOS
    rts
.endproc

