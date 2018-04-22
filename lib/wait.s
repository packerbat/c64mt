;----------------------
; Procedur WAIT czaka blokująca przez bliżej nieokreślony czas.
;
; input: Y=starszy bajt liczby obiegów pustej pętli
; output: A=unchanged, X=0, Y=0, ZF=0
; reentrant: yes
;
; To jest przykład procedury, której nie wolno robić ani w programowaniu
; jednowątkowym ani wielowątkowym.

.export WAIT

.segment "CODE"
.proc WAIT
    ldx #0
:   nop         ;65536 * 2 cycles
    dex         ;65536 * 2 cycles
    bne :-      ;(65536-256) * 3 cycles + 256 * 2 cycles
    dey         ;256 * 2 cycles
    bne :-      ;255 * 3 cycles + 2 cycles
    rts         ;powrót po 65536*4+65536*3-256+256*2+256*3-1=459775, powinno się zmieniać co 0.5 sekundy a chyba jest rzadziej.
.endproc