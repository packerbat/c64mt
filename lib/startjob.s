;----------------------------
; A=hi,X=lo = adres kontynuacji zadania 1 (tak na prawdę to początku zadania)
; Ta procedura udaje przełączanie zadań podobne jak w IRQ tylko, że na stosie jest
; jedynie adres powrotu, który tu jest nazywany adresem kontynuacji zadania.
; trzeba zapamiętać stan procesora w bieżącym deskrytorze (czyli 0)
; a następnie zainicjować deskryptor nowego zadania
; po zainicjowaniu nowego zadania robimy skok do nowego zadania (czyli 1), a IRQ
; je potem przerwie i wznowi zadanie 0.
;
; Użytkownik nie ma władzy na kolejnością wykonywania zadań. Jeśli żadne zadania
; nie będą zwalnianie to kolejność będzie zgodna z kolejnością wywoływania STARTJOB
; ale jeśli jakieś zadanie się zwolni to powstała dziura będzie zajmowana w pierwszej
; kolejności.
;
; adres kontynuacji zadania 0 jest dostępny jako lda $105,x (low) i lda $106,x (hi) ale jest pomniejszony o 1
; adres kontynuacji zadania 1 jest dostępny jako lda $102,x (low) i lda $103,x (hi)
;
; Ta procedura nigdy nie może się wykonać w trakcie obsługi innego przerwania
; bo manipuluje na stosie
;
; Niebezpieczne jest również przerwanie IRQ w trakcie konfigurowania zadania. Z tego
; względu zmiana statusu EMPTY na NOT EMPTY jest robiona na samym końcu podobnie jak
; ustawienie CURRTASK na nowe zadanie.
;
; System nie zapamiętuje, który proces zainicjował nowe zadanie.
;
; Zadanie nie może się zakończyć ani RTS ani RTI bo nie ma do czego wrócić. Jedyne co może
; zrobić to zgłosić chęć zakończenia działania jedną z flag (bit b5) w polu STATUS swojego
; dekryptora.


.include "globals.inc"

.export STARTJOB
.import CURRTASK, TASK_REGPCL, TASK_REGPCH, TASK_REGA, TASK_REGX, TASK_REGY, TASK_REGPS, TASK_REGSP, TASK_STATE, TASK_EVENTS

.proc STARTJOB
    php                 ; PS dostępne jako lda $104,x
    sei
    pha                 ; A dostępne jako lda $103,x
    txa
    pha                 ; X dostępne jako lda $102,x

    ; --- najpierw sprawdzam czy jest wolny slot dla zadania
    ldx #1
:   lda TASK_STATE,x
    bpl :+                  ;mam wolny slot
    inx
    cpx #MAXTASKS
    bcc :-
    pla
    tax
    pla             ;nie ma więc milcząco wracam do zadania, które wywołało STARTJOB
    plp
    rts             ;jak nie ma wolnego slota to procedura START_JOB jest całkowicie przezroczysta


:   tya
    pha                 ; Y dostępne jako lda $101,x
    tsx

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

    ; --- po raz drugi szukam wolnego slotu
    ldy #1
:   lda TASK_STATE,y
    bpl :+              ;mam wolny slot
    iny
    cpy #MAXTASKS
    bcc :-              ;wcześniej sprawdziłem, że jest wolny slot więc CF zawsze będzie 0

    ; --- zapamiętanie nowego zadania
:   lda #0
    sta TASK_EVENTS,y   ; nowe zadanie nie czeka na zdarzenia
    lda $102,x          ; pobranie PCL
    sta TASK_REGPCL,y
    lda $103,x          ; pobranie PCH
    sta TASK_REGPCH,y
    lda #0              ; rejestry A,X,Y na starcei będą miały wartość 0
    sta TASK_REGA,y
    sta TASK_REGX,y
    sta TASK_REGY,y
    lda $104,x          ; PS będzie równe staremu zadaniu
    sta TASK_REGPS,y
    tya
    asl
    asl
    asl
    asl
    asl
    sec
    sbc #224            ;y*32-224
    eor #255
    clc
    adc #1              ;224-y*32   zadanie 0 jest uprzywilejowane i dostaje większy stos (64 bajty)
    sta TASK_REGSP,y    ; pozostałe zadania (max 6 sztuk) dostaną po 32 bajty

    ; uruchomienie nowego zdania, Y = numer nowego zadania (czyli 1)
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
    lda #$80
    sta TASK_STATE,y    ; deskryptor nowego zadania nie jest pusty
    lda TASK_REGY,y
    sty CURRTASK
    tay
    pla
    rti
.endproc
