;----------------------------
; Procedura STARTTIMER uruchamia zegar wskazany przez rejestr Y
; Odstęp czasu podaje się w A w 1/60 sekundy (czyli A=60 oznacza wyzwolenie)
; zegara co 1 sekundę
;
; Z
;
; input: Y-numer zegara, A-reload value
; output: A=?, X-preserved, Y-numer zegara
; stack: 0
; reentrant: yes
;
; Procedura STOPTIMER zatrzymuje zegar wskazany przez rejestr Y
;
; input: Y-numer zegara
; output: A=?, X-preserved, Y-numer zegara
; stack: 0
; reentrant: yes

.export STARTTIMER, TIMERS_RELOAD, TIMERS
.import EVENTS, BITSOFF

.segment "DATA"
TIMERS_RELOAD:  .byte 0,0,0,0    ;0-disabled

.segment "BSS"
TIMERS:        .res 4

.segment "CODE"
.proc STARTTIMER
    sei
    sta TIMERS_RELOAD,y
    sta TIMERS,y
    lda BITSOFF+4,y
    and EVENTS
    sta EVENTS
    cli
    rts
.endproc

.proc STOPTIMER
    sei
    lda #0
    sta TIMERS_RELOAD,y
    lda BITSOFF+4,y
    and EVENTS
    sta EVENTS
    cli
    rts
.endproc
