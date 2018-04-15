;------------------------------------
; przełącza VIC w tryb wysokiej rozdzielczości
; na razie tylko BANK1
; zmienia tylko A i flagi
; input: -
; output: X=unchanged, Y=unchanged
; stack: 0
; zeropage: 0
; reentrant: yes

.export HGR

.segment "CODE"
.proc HGR
    lda $DD00    ;CIA#2 Data Port A
    and #$FC
    ora #$02
    sta $DD00    ;CIA#2 Data Port A, grafika w banku 1
    lda #$78     ;%0111 1000 = video matrix base address 7=$5C00, character base addres 4 = górne 8 KB bloku 16 KB
    sta $D018    ;VIC Memory Control Register, adres grafiki od $6000 do $7FFF
    lda $D011    ;VIC Control Register 1
    ora #$20     ;Bit 5 = 1 Enable bitmap mode
    sta $D011    ;VIC Control Register 1
    rts
.endproc
