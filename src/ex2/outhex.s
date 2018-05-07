;---------------------------------------------------------- 
; Procedura wyświetla liczbę hex w górnym pasku ekranu
; poczynając od pozycji podanej w X. Procedura działa
; wyłącznie w trybie Text Single Buffer.
;
; input: A-liczba, X-pozycja w linii 0..38
; output: X-pozycja za liczbą

.export output_hex

.segment "CODE"
.proc output_hex
    pha
    lsr
    lsr
    lsr
    lsr
    cmp #10
    bcc :+
    sbc #57
:   adc #'0'
    sta $6000,x
    inx
    pla
    and #$0F
    cmp #10
    bcc :+
    sbc #57
:   adc #'0'
    sta $6000,x
    inx
    rts
.endproc
