;-----------------------------------------------------------
; Trzy procedury związane z obsługo sotwarowego kursora.
; Cursor jest zawsze tam gdzie skończyło się pisanie przez CHROUT
; albo tam gdzie ustawiono kursor procedurą MVCRSR
; Procedura działa tylko na aktywnym ekranie (niekoniecznie widocznym)
; z tego względu nadaje się tylko do trybu Single Buffer.
; W trybie Double Buffer musiałaby rysować jednocześnie na obu buforach.
;
; Przyjazne dla C bo nie używają rejestru X

.export CRSROFF, CRSRON, CRSRNEG
.import CRSPTR:zeropage, CURCOL, TXTPAGE

.segment "CODE"
.proc CRSROFF
    ldy CURCOL
    lda (CRSPTR),y
    and #$BF
    sta (CRSPTR),y
    lda CRSPTR+1
    and #$03
    ora #$D8
    sta CRSPTR+1
    lda #5
    sta (CRSPTR),y
    lda CRSPTR+1
    and #$03
    ora TXTPAGE
    sta CRSPTR+1
    rts
.endproc

.proc CRSRON
    ldy CURCOL
    lda (CRSPTR),y
    ora #$40
    sta (CRSPTR),y
    lda CRSPTR+1
    and #$03
    ora #$D8
    sta CRSPTR+1
    lda #0
    sta (CRSPTR),y
    lda CRSPTR+1
    and #$03
    ora TXTPAGE
    sta CRSPTR+1
    rts
.endproc

.proc CRSRNEG
    ldy CURCOL
    lda (CRSPTR),y
    eor #$40
    sta (CRSPTR),y
    lda CRSPTR+1
    and #$03
    ora #$D8
    sta CRSPTR+1
    lda (CRSPTR),y
    eor #5
    sta (CRSPTR),y
    lda CRSPTR+1
    and #$03
    ora TXTPAGE
    sta CRSPTR+1
    rts
.endproc

