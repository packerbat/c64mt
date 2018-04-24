;----------------------------
; Procedura SCANKBD skanuje klawiaturę w poszukiwaniu wciśniętego klawisza
; input: -
; output: Y=?, X=?, A=?, NZCIDV=011---
; stack: 2
; reentrant: no
;
; Klawiszy jest dokładnie 8 wierszy po 8 kolumn czyli 64. Najstarszy bit będzie wykorzystany
; do zapamiętania wciśnięcia/puszczenia czyli do dyspozycji mamy 128 kodów.
; W buforze będą kody ASCII nie scancodes. Te z ustawionym najstarszym bitem można
; po prostu ignorować, chyba, że gra będzie tego wymagała
;
; Do tych samych portów A i B są podłączone dwa joysticky i na razie je nie analizuje.
; W przyszłości można tą procedurę rozbudować (np. każdego wciśnięci/puszczenia)
; dodać znacznik czasowy.
;
; Kolejka klawiszy ma 32 bajty ale w rzeczywistości to jest 16 bajtów bo na
; każdy klawisz przypadają dwa zdarzenia. Jednak ze względu na implementację
; ringbuffer tracimy jedną pozycję bo inaczej stan pusty i całkowicie zapełniony
; są nie rozróżnialne
;
; Procedura nie analizuje klawiszy specjalnych jak shift, ctrl, commodore.
;
; W jednym wywołaniu procedury może pojawić się wiele klawiszy jednocześnie. Mogą również
; pojawić się fałszywe klawisze gdy wciśniemy wiele klawiszy na raz.

.include "globals.inc"

.export SCANKBD, LASTKEYS, KBDHEAD, KBDTAIL, KBDBUFFER
.import BITSOFF

.segment "ZEROPAGE":zeropage
KBFPTR:   .res 2

.segment "DATA"
LASTKEYS:   .res 8,0
KBDHEAD:    .byte 0             ;to czoło zapisu nowych klawiszy i tylko SCANKBD ma prawo zmieniać wartość
KBDTAIL:    .byte 0             ;to czoło odczytu zgromadzonych klawiszy, prawo odczytu powiniem mieć tylko jeden proces

.segment "BSS"
KBDBUFFER:  .res KDBQUEUESIZE,0

.segment "RODATA"
KBDROW1: .byte $20,'q',$22,$23,'2',$25,$26,'1'
KBDROW2: .byte '/',$29,'=',$2B,$2C,';','*',$2F
KBDROW3: .byte ',','@',':','.','-','l','p','+'
KBDROW4: .byte 'n','o','k','m','0','j','i','9'
KBDROW5: .byte 'v','u','h','b','8','g','y','7'
KBDROW6: .byte 'x','t','f','c','6','d','r','5'
KBDROW7: .byte $50,'e','s','z','4','a','w','3'
KBDROW8: .byte $58,$59,$5A,$5B,$5C,$5D,$0D,$5F

.define TMPBIT a:$103,x
.define TMPVAL a:$102,x
.define TMPCODE a:$101,x

.segment "CODE"
.proc SCANKBD
    lda #7
    pha                 ;TMPBIT = $103,x
    lda #0
    pha                 ;TMPVAL = $102,x
    pha                 ;TMPCODE = $101,x
    tsx

    lda #<KBDROW1
    sta KBFPTR
    lda #>KBDROW1
    sta KBFPTR+1

next_row:
    ldy TMPBIT
    lda BITSOFF,y
    sta $DC00
    nop
    nop
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta TMPVAL
    eor LASTKEYS,y
    beq brak_zmian

    sta TMPCODE         ;TMPCODE bity zmian
    lda TMPVAL          ;zapamiętuję ostatni stan w tym rzędzie, dzięk temu TMPVAL też mogę przesuwać
    sta LASTKEYS,y

    ldy #0
:   lda TMPCODE
    bpl :++             ;na tym bicie nie ma zmian

    lda TMPVAL
    and #$80            ;znacznik wciśnięcia b7=1
    ora (KBFPTR),y
    pha
    lda KBDHEAD
    clc
    adc #1
    cmp #KDBQUEUESIZE
    bcc :+
    lda #0
:   tax
    pla
    sta KBDBUFFER,x     ;najpiew wstawić do kolejki
    stx KBDHEAD         ;a dopiero potem przesunąć HEAD
    tsx

:   iny
    asl TMPVAL          ;przesuwam bity nowej wartości 0 wciśnięto, 1 puszczono
    asl TMPCODE         ;przesuwam bity zmian
    bne :---            ;jest jeszcze jakiś bit zmian

brak_zmian:
    clc
    lda KBFPTR
    adc #8
    sta KBFPTR
    lda KBFPTR+1
    adc #0
    sta KBFPTR+1
    dec TMPBIT
    bpl next_row

    lda #$FF
    sta $DC00
    pla
    pla
    pla             ;usuwam tymczasowe zmienne
    rts
.endproc