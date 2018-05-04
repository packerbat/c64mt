;----------------------------
; Procedura SCANKBD skanuje klawiaturę w poszukiwaniu wciśniętego klawisza
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
; Procedura nie analizuje klawiszy specjalnych jak shift, ctrl, commodore.
; Również nie obsługuje klawiszy samopowtarzalnych
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

.export SCANKBD
.import KBDEVENT, BITSOFF, NEWKEYS, LASTKEYS

.segment "CODE"
.proc SCANKBD

    ; --- pobranie nowych stanów klawiszy
    ; ponieważ LASTKEYS nie będzie już potrzebne więc będą tam
    ; umieszczone znaczniki zmian stanów (1 oznacza, że ten klawisz zmienił stan)

    ldx #7
:   lda NEWKEYS,x
    sta LASTKEYS,x
    dex
    bpl :-

    ldx #7
:   lda BITSOFF,x
    sta $DC00
    nop
    nop
:   lda $DC01
    cmp $DC01
    bne :-
    eor #$FF            ; teraz mam 1 tam gdzie wciśnięto i 0 na niewciśniętych klawiszach
    sta NEWKEYS,x
    dex
    bpl :--
    lda #$FF
    sta $DC00                  ;wyłączenie wszystkich wierszy

    jmp KBDEVENT
.endproc
