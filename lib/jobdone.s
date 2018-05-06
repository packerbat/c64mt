;----------------------------
; Funkcja JOBDONE czyści deskryptor bieżącego zadania a potem szuka
; aktywnego zdania i je wznawia. Jeśli takiego nie ma to wznawia IDLE
; Ta procedura musi się wykonać atomowo dlatego jest SEI na początku
; Do tej procedury można robić JMP choć JSR też będzie działać

.include "globals.inc"

.export JOBDONE
.import CURRTASK, TASK_REGPCL, TASK_REGPCH, TASK_REGA, TASK_REGX, TASK_REGY, TASK_REGPS, TASK_REGSP, TASK_STATE, TASK_EVENTS, EVENTS

.proc JOBDONE
    sei

    ; --- najpierw zamykam zadania, które potwierdziły swoje zamknięcie
    ldy CURRTASK
    lda #$20
    ora TASK_STATE,y
    sta TASK_STATE,y

    ldy #MAXTASKS-1
:   lda TASK_STATE,y
    bpl :+              ;pomijam puste sloty
    and #$20
    beq :+
    lda #0
    sta TASK_STATE,y
:   dey
    bne :--

    ; --- poszukiwanie zdania, które czeka na zdarzenia (nie pomijam T0 ale ono i tak nigdy na nic nie czeka)
    ldy CURRTASK
:   iny
    cpy #MAXTASKS
    bcc :+
    ldy #0
:   cpy CURRTASK
    beq :+
    lda TASK_STATE,y
    bpl :--
    lda TASK_EVENTS,y
    beq :--             ;to zadanie pomija bo nie czeka w SELECT
    and EVENTS
    beq :--
    sta TASK_REGA,y     ; A = tylko zdarzenia, na które czekał ten proces bo to jest pobudka z SELECT
    eor EVENTS          ; w EVENTS neguję bit, który się zdarzył
    sta EVENTS
    lda #0
    sta TASK_EVENTS,y   ; ale TASK_EVENTS zeruję całe bo już nie jestem w SELECT
    jmp activate_task_in_y

    ; --- teraz szukam zadania aktywnego (pomijam T0)
:   iny
    cpy #MAXTASKS
    bcc :+
    ldy #1
:   cpy CURRTASK
    beq :+
    lda TASK_STATE,y
    bpl :--
    lda TASK_EVENTS,y
    bne :--                 ;to zadanie na coś czeka w SELECT więc nie jest aktywne
    beq activate_task_in_y

    ; --- nie znalazłem więc skacze do IDLE (to chyba można w przyszłości uprościć)
:   ldy #0

    ; --- wznowienie znalezionego zdania
activate_task_in_y:
    ldx TASK_REGSP,y
    txs                 ;od tej pory działamy na stosie nowego zadania
    lda TASK_REGPCH,y
    pha
    lda TASK_REGPCL,y
    pha
    lda TASK_REGPS,y
    pha
    lda TASK_REGA,y     ;tu muszę użyć stosu bo inaczej nie odczytam A
    pha
    ldx TASK_REGX,y
    lda TASK_REGY,y
    sty CURRTASK
    tay
    pla                 ; restore A
    rti
.endproc
