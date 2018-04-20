;---------------------------------------------------------- 
; włącza ROM i robi skok do oryginalnej procedury COLD START

.export COLDSTART

.proc COLDSTART
    lda #$37
    sta $01         ;włączam oba ROM-y bo dobiero teraz mogę zrobić skok do ROM–u.
    jmp $FCE2
.endproc