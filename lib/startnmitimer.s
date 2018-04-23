;----------------------------
; 

.export INIT_NMI_DOUBLE_TIMER
.import CIA2IRQMask

.proc INIT_NMI_DOUBLE_TIMER
    ; --- ten fragment nie niszczy rejestru Y
    lda #$07      ; 1 sekunda dla NTSC to 1022727=$000F9B07, 60 razy na sekundę $00004295
    sta $DD04     ; CIA#1 Timer A
    lda #$9B
    sta $DD05
    lda #$0F
    sta $DD06     ; CIA#2 Timer B
    lda #$00
    sta $DD07
    lda #$82
    sta CIA2IRQMask
    sta $DD0D     ; CIA#2, enable Timer B interrupt
    lda $DD0E     ; CIA#2: Control Register A
    and #$80      ; zostaw tylko TOD freq.
    ora #$11      ; ustaw: force reload Timer A i start Time A, Continuous
    sta $DD0E     ; CIA#2: Control Register A
    lda $DD0F     ; CIA#2: Control Register A
    and #$80      ; zostaw tylko Alarm/TOD mode
    ora #$51      ; ustaw: Count Timer A Underflow Pulses, force reload Timer A i start Time A, Continuous
    sta $DD0F     ; CIA#2: Control Register A
    rts
.endproc
