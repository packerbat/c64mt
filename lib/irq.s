;----------------------
; Przerwanie może być generowane przez:
;   1. CIA#1 IRQ out line
;      a) licznik A doliczył do zera
;      b) licznik B doliczył od zera
;      c) TOD wygenerował ALARM
;      d) Serial Port umieścił odebrany bajt w SDR albo Serial Port "wypchnął" cały bajt na linię DATA
;      e) na wejściu FLAG pojawiło się opadające zbocze (SRQ IN w SERIALBUS lub Cassete Read).
;   2. VIC-II IRQ out line
;   3. przerwanie od instrukcji BRK
;
; UWAGI:
;   1. Można używać obu liczników do własnych celów chyba że się chce używać
;      urządzenie szerego podpięte do USERPORT (wtedy TIMER A jest potrzebny do nadawania).
;   2. Można używać TOD do własnych celów.
;   3. Synchroniczny port seregowy jest w całości wyprowadzony na USERPOT włącznie z liniami
;      handshakingu PC i FLAG. Linia FLAG może być użyta jako chęć przejęcią magistrali przez
;      urządzenie zewnętrzne a PA2 jako chęć zawładnięcia magistralą przez komputer.
;   4. Czytając rejestr ICR wiemy, jakie przerwanie się zdarzyło (MSB mówi, że się zdarzyło
;      a dolne 5 bitów co się zdarzyło). Wpisując do ICR 1xx00100 odblokujemy przerwanie ALARM
;      a wpisując 0xx00100 zablokowujemy przerwanie ALARM. Innymi słowy najstarszy bit mówi
;      jak wartość ma być ustawiona a 5 dolnych bitów mówi gdzie ta wartość ma być wpisana.
;   5. NMI może zostać przerwane przez IRQ bo Commodore nie ma priorytetowego systemu przerwań.
;
; UWAGI nie mające znaczenia dla NMI:
;   4. Oprócz tego mamy dostęp do PB0-PB7 wyprowadzonych na USERPORT
;   5. CIA#2 realizuje również softwareowy transfer danych między komputerem a SERIALBUS
;      (PA7=DATA in, PA5=DATA out, PA6=CLK in, PA4=CLK out, PA3=ANT out). Ciekawe, że
;      linia SRQ IN w SERIALBUS nie jest podłączona do CIA#2 tylko do FLAG w CIA#1 i generuje
;      zwykłe przerwanie IRQ.
;
;
; cassete read i SERIALBUS SRQIN do CIA#1 FLAG
; cassete sense do P4 6510
; cassete write do P3 6510
; cassete motor do P5 6510
;
; CIA#1 IRQ do CPU IRQ
; CIA#2 IRQ do CPU NMI
; klawisz RESTORE do CPU NMI
; JoyB do input CIA#1 port A
; JoyA do input CIA#1 port B
; przycisk JoyA jest połączony z light pen in.
; keyboard column do output CIA#1 port A
; keyboard row do input CIA#1 port B
; USERPORT CNT1 do CIA#1 CNT
; USERPORT SP1 do CIA#1 SP
; USERPORT ATN i CIA#2 PA3 do SERIALBUS ATN
; USERPORT CNT2 do CIA#2 CNT
; USERPORT SP2 do CIA#2 SP
; USERPORT FLAG do CIA#2 FLAG
; SERIALBUS DATA do CIA#2 PA7
; SERIALBUS CLK do CIA#2 PA6 
; Cartridge NMI do CPU NMI
;
; nie sprawdzam czy cartrig została wsadzony

.export IRQ, CIA1IRQMask, CIA1IRQState, VICIRQMask, VICIRQState, JiffyClock
.import COLDSTART

.segment "DATA"
CIA1IRQMask:   .byte $7F        ;wstaw 0 do wszytkich masek przerwania CIA#2
CIA1IRQState:  .byte 0          ;ostatnie przyczyny IRQ w CIA#2
VICIRQMask:    .byte 0          ;wstaw 0 do wszytkich masek przerwania VIC-II
VICIRQState:   .byte 0          ;ostatnie przyczyny IRQ w VIC-II

.segment "BSS"
JiffyClock:    .res 4           ;32-bitowy licznik przerwań IRQ

.segment "CODE"

.proc IRQ
    sei                ; dzięki temu IRQ nie przerwie NMI
    pha                ; save A
    lda $DC0D                ; get source of interrupts in CIA#2 and clear interrupts flags
    bmi przerwanie_od_CIA1
    
    lda $D019               ; get source of interrupts in VIC-II
    bmi przerwanie_od_VICII

    ; nie znana przyczyna przerwania będzie kwitowana COLD START-em
    jmp COLDSTART

przerwanie_od_CIA1:
    sta CIA1IRQState
    ;lda #$7F
    ;sta $DC0D          ; dzięki temu CIA#1 nie spowoduje przerwania IRQ w trakcie obsługi IRQ
    ;txa                ; copy X
    ;pha                ; save X
    ;tya                ; copy Y
    ;pha                ; save Y

    ; tu można zrobić obsługę przerwania CIA#1 z zablokowanymi przerwaniami IRQ i CIA#2
    inc JiffyClock
    bne :+
    inc JiffyClock+1
    bne :+
    inc JiffyClock+2
    bne :+
    inc JiffyClock+3

:   inc $6000
    inc $6401
    inc $6002
    inc $A003

    ;pla                ; pull Y
    ;tay                ; restore Y
    ;pla                ; pull X
    ;tax                ; restore X
    ;lda CIA1IRQMask
    ;sta $DC0D          ; restore CIA#1 IRQ Mask
    pla                 ; restore A
    rti

przerwanie_od_VICII:
    sta VICIRQState
    ;txa                ; copy X
    ;pha                ; save X
    ;tya                ; copy Y
    ;pha                ; save Y

    ; tu można zrobić obsługę przerwania od VIC-II z zablokowanymi przerwaniami VIC-II, przerwania VIC_II odblokuje dobiero wpisanie 0 do $D019

    ;pla                ; pull Y
    ;tay                ; restore Y
    ;pla                ; pull X
    ;tax                ; restore X
    lda #0
    sta $D019           ; manual IRQ flag clear
    pla
    rti
.endproc