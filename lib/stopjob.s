;----------------------------
; A=numer zadania, które ma być zatrzymane
;   dopuszczalne wartości to 1..MAXTASKS-1 (bo procesu numer 0 nie można zakończyć)
; jeśli slot jest pusty to procedura nic nie robi
; Jeśli zadanie czeka w SELECT to nie ustawiamy flagi tylko wznawiamy zdarzenie
; z pustymi wszystkimi flagami zdarzeń (czyli że nic się nie wydarzyło).

.include "globals.inc"

.export STOPJOB
.import CURRTASK, TASK_REGPCL, TASK_REGPCH, TASK_REGA, TASK_REGX, TASK_REGY, TASK_REGPS, TASK_REGSP, TASK_STATE, TASK_EVENTS

.proc STOPJOB
    tay
    lda TASK_STATE,y    ; deskryptor nowego zadania nie jest pusty
    bpl :+
    lda TASK_EVENTS,y
    bne :++
    lda TASK_STATE,y
    ora #$40
    sta TASK_STATE,y    ; deskryptor nowego zadania nie jest pusty
:   rts

    ; --- czeka w SELECT więc budzę z pustą flagą
:   php
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

    ; --- nie znalazłem więc skacze do IDLE (to chyba można w przyszłości uprościć)
    ldy $101,x              ;w Y mam budzone zadanie
    lda #0
    sta TASK_EVENTS,y       ;nie czeka na zdarzenia
    sta TASK_REGA,y         ;rejest A po SELECT nie ma ustawionych żadnych flag

    ; --- wznowienie znalezionego zdania
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
