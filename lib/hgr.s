;------------------------------------
; przełącza VIC w tryb wysokiej rozdzielczości i ustawia BANK1
; ustawia również HGRPAGE na BANK2 (czyli niewidoczny)
;
; pamięć $DD00 i HGRPAGE powinny być zmieniane atomowo a ta procedura o to nie dba
;
; input: DBLBUF
; output: X=unchanged, Y=unchanged, VIDPAGE
; stack: 0
; zeropage: 0
; reentrant: yes in real cases

.export HGR
.import VIDPAGE, DBLBUF

.segment "CODE"
.proc HGR
    lda $D011    ;VIC Control Register 1
    ora #$20     ;Bit 5 = 1 Enable bitmap mode
    sta $D011    ;VIC Control Register 1
    lda #$08     ;%1010 0000 = video matrix base address 1010=$6800, character base addres 0 = dolne 8 KB bloku 16 KB
    sta $D018    ;VIC Memory Control Register, adres grafiki od $6000 do $7FFF
    lda $DD00    ;CIA#2 Data Port A
    and #$FC
    ora #$02
    sta $DD00    ;CIA#2 Data Port A, grafika w banku 1
    lda #$60
    eor DBLBUF
    sta VIDPAGE
    rts
.endproc
