;----------------------------
; A=numer zadania, które ma być zatrzymane
;   dopuszczalne wartości to 1..MAXTASKS-1 (bo procesu numer 0 nie można zakończyć)
; jeśli slot jest pusty to procedura nic nie robi

.export STOPJOB
.import TASK_STATE

.proc STOPJOB
    tay
    lda TASK_STATE,y    ; deskryptor nowego zadania nie jest pusty
    bpl :+
    ora #$40
    sta TASK_STATE,y    ; deskryptor nowego zadania nie jest pusty
:   rts
.endproc
