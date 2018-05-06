;----------------------------
; Funkcja SELECT jest zrobiona na wzór unixowej funkcji select
; i służy do czekania na zdarzenia. Jej głównym zadaniem jest
; zapamiętać na co czeka beżący proces a następnie przełączyć
; się na inne zadanie, które nie śpi. Jeśli nie ma takiego
; zadania to SELECT przełącza się na zdanie IDLE (TASK0)
;
; W przerwaniu IRQ, uśpiony proces zostanie wznowiony a w A będzie
; miał flagi zdarzeń.
;
; input: A=maska zdarzeń
; Ta procedura udaje przełączanie zadań podobne jak w IRQ tylko, że na stosie jest
; jedynie adres powrotu, który tu jest nazywany adresem kontynuacji zadania.
; trzeba zapamiętać stan procesora w bieżącym deskrytorze
; a następnie znaleźć następne zadanie i je uruchomić
;
; adres kontynuacji zadania bieżącego jest dostępny jako lda $105,x (low) i lda $106,x (hi) ale jest pomniejszony o 1
;
; Ta procedura nigdy nie może się wykonać w trakcie obsługi innego przerwania
; bo manipuluje na stosie dla tego na starcie ma SEI

.include "globals.inc"

.export SELECT
.import CURRTASK, TASK_REGPCL, TASK_REGPCH, TASK_REGA, TASK_REGX, TASK_REGY, TASK_REGPS, TASK_REGSP, TASK_STATE, TASK_EVENTS, EVENTS

.proc SELECT
    php
    sei
    pha
    txa
    pha
    tya
    pha
    tsx                 ;Y=$101,x  X=$102,x  A=$103,x  PS=$104,x  PCL=$105,x  PCH=$106,x

    ; --- najpierw zamykam zadania, które potwierdziły swoje zamknięcie
    ldy #MAXTASKS-1
:   lda TASK_STATE,y
    bpl :+              ;pomijam puste sloty
    and #$20
    beq :+
    lda #0
    sta TASK_STATE,y
:   dey
    bne :--

    ; --- zapamiętanie starego zadania
    ldy CURRTASK
    clc
    lda $105,x          ; pobranie PCL
    adc #1
    sta TASK_REGPCL,y
    lda $106,x          ; pobranie PCH
    adc #0
    sta TASK_REGPCH,y
    lda $103,x          ; pobranie A
    sta TASK_REGA,y
    sta TASK_EVENTS,y
    lda $102,x          ; pobranie X
    sta TASK_REGX,y
    lda $101,x          ; pobranie Y
    sta TASK_REGY,y
    lda $104,x          ; pobranie PS
    sta TASK_REGPS,y
    txa
    clc
    adc #6
    sta TASK_REGSP,y    ; SP wskazuje na adres przed skokiem dlatego podnoszę o 6

    ; --- poszukiwanie zdania, które czeka na zdarzenia (nie pomijam T0 ale ono i tak nigdy na nic nie czeka)
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
