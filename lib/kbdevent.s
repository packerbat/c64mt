;----------------------------
; Procedura KBDEVENT interpretuje zawartość dwóch tablic NEWKEYS i LASTKEYS
; i na tej postawie umieszcze buforze klawiatury odpowiedni kod ASCII wcisniętego
; klawisza
; Klawiatura jest tylko jedna więc ta procedura jest rodzajem sterownika
; i nie ma powodu żeby była wielowejściowa
;
; input: -
; output: all
; stack: 2
; reentrant: no
;
; Klawiszy jest dokładnie 8 wierszy po 8 kolumn czyli 64. Najstarszy bit będzie wykorzystany
; do zapamiętania wciśnięcia/puszczenia czyli do dyspozycji mamy 128 kodów.
; W buforze będą kody ASCII nie scancodes. Te z ustawionym najstarszym bitem można
; po prostu ignorować, chyba, że gra będzie tego wymagała
;
; Do tych samych portów A i B są podłączone dwa joysticky i na razie ich nie analizuję.
; W przyszłości można tę procedurę rozbudować (np. do każdego wciśnięcia/puszczenia)
; dodać znacznik czasowy.
;
; Kolejka klawiszy ma 32 bajty ale w rzeczywistości to jest 16 bajtów bo na
; każdy klawisz przypadają dwa zdarzenia. Jednak ze względu na implementację
; ringbuffer tracimy jedną pozycję bo inaczej stan pusty i całkowicie zapełniony
; są nie rozróżnialne
;
; Procedura najpierw analizuje klawiszy specjalnych jak shift, ctrl, commodore
; ale do dlaszej analizy wykorzystywany jest tylko modyfikator SHIFT (bez znaczenia lewy czy prawy)
;
; Procedura nie obsługuje klawiszy samopowtarzalnych
;
; W jednym wywołaniu procedury może pojawić się wiele klawiszy jednocześnie. Mogą również
; pojawić się fałszywe klawisze gdy wciśniemy wiele klawiszy na raz.
;
; 1. pierwszy rząd: 16 klawiszy - cyfry i znaki interpunkcyjne z SHIFT-em
; 2. drugi rząd: 14 klawiszy + RESTORE (nie podłączony do CIA tylko do NMI)
; 3. trzeci rząd: 14 klawiszy + CAPS LOCK (nie podłączony do CIA)
; 4. czwarty rząd: 15 klawiszy
; 5. piąty rząd: 1 klawisz - SPACE
; 6. blok funkcyjny: 4 klawisze.
;
; Tablica kodów będzie zbliożona do kodów ASCII ale tylko 64 wybrane kody z zakresu 0..95
;    1. kody ASCII dostają klawisze: '@'..'Z', '0'..'9', '/', '=', ',', ':', '.', '-', '+'
;    2. POUND, ARROW LEFT i ARROW UP, RETURN dostają kody PETSCII w zgodzie z ASCII czyli: $5C ('\'), $5F ('_'), $5E ('^') i 13, 
;    3. modyfikatory dostają rozłączne bity: SHIFT LEFT=1, SHIFT RIGHT=2, CTRL=4, COMMODORE=8
;    4. kody zgodne z PETSCII: CRSR DOWN=17, CRSR RIGHT=29, HOME=19, DEL=20
;    4. klawisze specjalne: RUN/STOP=16, F1=21, F3=23, F5=25, F7=27
;
; Osobną grupą są kody po modyfikatorach. Minimalna obsługa to SHIFT bo bez SHIFT nie ma klawiszy
;    1: '!' (S1), '"' (S2), '#' (S3), '$' (S4), '%' (S5), '&' (S6), '\'' (S7), '(' (S8), ')' (S9)
;    2: '[' (S:), ']' (S;)
;    3: '<' (S,), '>' (S.), '?' (S/), 18 (SCD), 30 (SCR)
;    2: F2 (SF1), F4 (SF3), F6 (SF5), F8 (SF7)
 

.include "globals.inc"

.export KBDEVENT, KEYMOD, NEWKEYS, LASTKEYS
.import PUTKEY

.segment "ZEROPAGE":zeropage
KBFPTR:   .res 2

.segment "DATA"
KEYMOD:     .byte 0             ;b0=left shift, b1=right shift, b2=ctrl, b3=commodore
LASTKEYS:   .res 8,0
NEWKEYS:    .res 8,0

.segment "BSS"
TMPBIT:     .res 1
TMPVAL:     .res 1

.segment "RODATA"
KBDROWS:      .byte  17, 25, 23, 21, 27, 29, 13, 20
              .byte   1,'e','s','z','4','a','w','3'
              .byte 'x','t','f','c','6','d','r','5'
              .byte 'v','u','h','b','8','g','y','7'
              .byte 'n','o','k','m','0','j','i','9'
              .byte ',','@',':','.','-','l','p','+'
              .byte '/',$5E,'=',  2, 19,';','*',$5C
              .byte  16,'q',  8,' ','2',  4,$5F,'1'
KBDSHIFTROWS: .byte  18, 26, 24, 22, 28, 30, 13, 20
              .byte   1,'e','s','z','$','a','w','#'
              .byte 'x','t','f','c','&','d','r','%'
              .byte 'v','u','h','b','(','g','y',$27
              .byte 'n','o','k','m','0','j','i',')'
              .byte '<','@','[','>','-','l','p','+'
              .byte '?',$5E,'=',  2, 19,']','*',$5C
              .byte  16,'q',  8,' ','"',  4,$5F,'!'

.segment "CODE"
.proc KBDEVENT

    ; --- pobranie nowych stanów klawiszy
    ; ponieważ LASTKEYS nie będzie już potrzebne więc będą tam
    ; umieszczone znaczniki zmian stanów (1 oznacza, że ten klawisz zmienił stan)

    ; --- w LASTKEYS znaczniki zmian
    ldx #7
:   lda NEWKEYS,x
    eor LASTKEYS,x
    sta LASTKEYS,x
    dex
    bpl :-

    ; --- zanim będę skanował klawisze muszę sprawdzić stan modyfikatorów
    lda LASTKEYS+1      ;SHIFT LEFT
    and #$80
    beq :+
    lda #$7F
    and LASTKEYS+1
    sta LASTKEYS+1
    lda #$FE
    and KEYMOD
    sta KEYMOD
    lda NEWKEYS+1
    and #$80
    bne :+
    lda #$01
    ora KEYMOD
    sta KEYMOD

:   lda LASTKEYS+6      ;SHIFT RIGHT
    and #$10
    beq :+
    lda #$EF
    and LASTKEYS+6
    sta LASTKEYS+6
    lda #$FD
    and KEYMOD
    sta KEYMOD
    lda NEWKEYS+6
    and #$10
    bne :+
    lda #$02
    ora KEYMOD
    sta KEYMOD

:   lda LASTKEYS+7      ;CTRL
    and #$04
    beq :+
    lda #$FB
    and LASTKEYS+7
    sta LASTKEYS+7
    lda #$FB
    and KEYMOD
    sta KEYMOD
    lda NEWKEYS+7
    and #$04
    bne :+
    lda #$04
    ora KEYMOD
    sta KEYMOD

:   lda LASTKEYS+7      ;COMMODORE
    and #$20
    beq :+
    lda #$DF
    and LASTKEYS+7
    sta LASTKEYS+7
    lda #$F7
    and KEYMOD
    sta KEYMOD
    lda NEWKEYS+7
    and #$08
    bne :+
    lda #$08
    ora KEYMOD
    sta KEYMOD

:   lda #<(KBDROWS+8*7)
    sta KBFPTR
    lda #>(KBDROWS+8*7)
    sta KBFPTR+1
    ldx #7
    stx TMPBIT
    jmp sprawdz_czy_koniec     ; skok bezwarunkowy

    ; --- analiza zmian przez porównanie LASTKEYS i NEWKYES
next_row:
    ldx TMPBIT
    lda LASTKEYS,x
    beq brak_zmian

    lda NEWKEYS,x
    sta TMPVAL          ;TMPVAL nowy stan klawiszy

    ldy #0              ;y=0 bez SHIFT, y=64 z SHIFT
    lda KEYMOD
    and #$03
    beq :+
    ldy #64

:   lda LASTKEYS,x
    bpl :+              ;na najstarszym bicie nie ma zmian

    lda TMPVAL
    and #$80            ;znacznik puszczenia b7=1
    ora (KBFPTR),y
    jsr PUTKEY
    ldx TMPBIT          ;bo PUTKEY zniszczyło X
 
:   iny
    asl TMPVAL          ;przesuwam bity nowej wartości 1 wciśnięto, 0 puszczono
    asl LASTKEYS,x
    bne :--             ;jest jeszcze jakiś bit zmian

brak_zmian:
    sec
    lda KBFPTR
    sbc #8
    sta KBFPTR
    lda KBFPTR+1
    sbc #0
    sta KBFPTR+1
    dec TMPBIT

sprawdz_czy_koniec:      ;jeśli wszystkie LASKEYS są 0 to nie ma więcej zmian
    ldx #7
:   lda LASTKEYS,x
    bne next_row
    dex
    bpl :-

    ; --- przepisaniem NEWKEYS do LASTKEYS odbywa się w IRQ albo na początku SCANKBD
    rts
.endproc
