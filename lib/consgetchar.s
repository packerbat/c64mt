;-----------------------------------------------------------
; Procedura powstała na potrzeby konsoli i nie jest
; elegancko napisana.
; 

.export CONSGETCHAR

;-----------------------------
; input: X - pozycja litery na ekranie
; output: A - lista ASCII, X - niezmienione, Y - niezmienione
.proc CONSGETCHAR
    lda $6000+23*40+1,x     ;bieże z linii 23 bo komenda właśnie została podniesiona
    cmp #32
    bcs :+
    clc
    adc #64
:   rts
.endproc
