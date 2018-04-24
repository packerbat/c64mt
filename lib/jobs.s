;----------------------------
; Procedura JOBS podaje liczbę aktywnych procesów
; input: -
; output: Y=active jobs (including process 0), X=MAXTASKS, NZCIDV=011---
; reentrant: yes

.include "globals.inc"

.export JOBS
.import CURRTASK, TASK_STATE

.proc JOBS
    ldy #1
    ldx #1
:   lda TASK_STATE,x
    bpl :+                  ;mam wolny slot
    iny
:   inx
    cpx #MAXTASKS
    bcc :--
    rts             ;jak nie ma wolnego slota to procedura START_JOB jest całkowicie przezroczysta
.endproc
