;----------------------------
; Procedura CHROUT wyświetla podaną literę (A) w miescu bieżącego kursora (CRSPTR, CURROW, CURCOL)
; input: A=litera, CRSPTR
; output: Y=?, X=?, A=?, NZCIDV=011---
; stack: 4
; reentrant: yes (z wyjątkiem przerwania NMI)

.export CHROUT
.import TXTPAGE, CRSPTR:zeropage, CURROW, CURCOL

.proc CHROUT
    ldy #0
    cmp #$40
    bcc :+
    sbc #$40
:   sta (CRSPTR),y

    sei                 ; na razie atomowość tych zmian gwarantuję blokadą przerwań
    lda CURCOL          ; licząc na to, że nikt nie wywoła tej procedury w NMI
    cmp #39
    bcs :+
    inc CURCOL          ;najprostszy przypadek, wiersz się nie skończył więc tylko dwa inkrementy
    inc CRSPTR
    bne koniec_przesuwania
    inc CRSPTR+1
    bne koniec_przesuwania

:   lda CURROW
    cmp #24
    bcs :+              ;ekran się skończył
    lda #0
    sta CURCOL
    inc CURROW          ;wiersz się skończył ale ekran jeszcze nie
    inc CRSPTR
    bne koniec_przesuwania
    inc CRSPTR+1        ;to działa gdy okno tekstowe ma 40 kolumn
    bne koniec_przesuwania

:   lda #0              ;tu powieniem być SCROLL UP ale narazie jest zawinięcie na górę ekranu
    sta CURCOL
    sta CURROW
    sta CRSPTR
    lda TXTPAGE
    sta CRSPTR+1

koniec_przesuwania:
    cli
    rts
.endproc
