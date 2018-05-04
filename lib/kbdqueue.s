;----------------------------
; Procedura GETKEY pobiera klawisz z bufora pierścieniowego
; Procedura PUTKEY zapamiętuje klawisz w buforze pierścieniowym

.include "globals.inc"

.export GETKEY, PUTKEY, KBDHEAD, KBDTAIL

.segment "DATA"
KBDHEAD:    .byte 0             ;to czoło zapisu nowych klawiszy i tylko SCANKBD ma prawo zmieniać wartość
KBDTAIL:    .byte 0             ;to czoło odczytu zgromadzonych klawiszy, prawo odczytu powiniem mieć tylko jeden proces

.segment "BSS"
KBDBUFFER:  .res KDBQUEUESIZE,0

.segment "CODE"

;-----------------------------
; Pobiera klawisz jeśli jest i go zwraca w  A z ZF=1
; Jeśli bufor jest pusty to zwraca ZF=0
; input: -
; output:
;   if ZF=1:  A=unmodified, X=KBDTAIL
;   if ZF=0:  A=key, X=KBDTAIL, NF=1 pressed NF=0 released
;
.proc GETKEY
    ldx KBDTAIL
    cpx KBDHEAD
    beq :++
    inx
    cpx #KDBQUEUESIZE
    bcc :+
    ldx #0
:   lda KBDBUFFER,x     ;ta kolejność jest bezpieczniejsza
    stx KBDTAIL
:   rts
.endproc

;-----------------------------
; Wsadzam klawisz w A do bufora
; Nic nie robi jeśli nie ma miejsca w buforze
; input: A=key
; output:
;   if ZF=1:  buffer full, A=key, X=KBDHEAD
;   if ZF=0:  buffer not full, A=key, X=KBDHEAD
;
.proc PUTKEY
    ldx KBDHEAD
    inx
    cpx #KDBQUEUESIZE
    bcc :+
    ldx #0
:   cpx KBDTAIL
    beq :+
    sta KBDBUFFER,x     ;ta kolejność jest bezpieczniejsza
    stx KBDHEAD
:   rts
.endproc

