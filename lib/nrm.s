;------------------------------------
; przywrócenie trybu tekstowego przy zablokowanych przerwaniach
; na razie tylko BANK1
; zmienia tylko A i flagi
; input: DBLBUF
; output: X=unchanged, Y=unchanged, VIDPAGE
; stack: 0
; zeropage: 0
; reentrant: yes

.export NRM
.import TXTPAGE, TXTDBLBUF

.segment "CODE"
.proc NRM
    lda $D011    ;VIC Control Register 1
    and #$df     ;Bit 5 = 0 Disable bitmap mode
    sta $D011    ;VIC Control Register 1
    lda #$80     ;%1000 0000 = video matrix base address 1000=$6000, character base addres 000 to RAM $4000-$47FF
    sta $D018    ;VIC Memory Control Register, adres grafiki od $0400 do $07FF
    lda $DD00    ;CIA#2 Data Port A
    and #$FC
    ora #$02
    sta $DD00    ;CIA#2 Data Port A, grafika w banku 1
    lda #$60
    eor TXTDBLBUF
    sta TXTPAGE
    rts
.endproc