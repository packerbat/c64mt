;----------------------------
; Procedura JOBS podaje liczbę aktywnych procesów
; input: X=kolumna 0..39, Y=wiersz 0..24
; output: X=kolumna, Y=wiersz
; stack: 0
; reentrant: no
;
; Ta procedura ma zmienne globalne więc może być użyta tyko w jednym
; wątku, użycie w innym wątku zmieni globalne zmienne CURROW, CURCOL, CRSPTR
; Żeby ta procedura miała sense w środowisku wielozadaniowym
; to musielibyśmy odczytać z deskryptora zadania wskaźnik na dwa
; bloki pamięci - prywatny fragment zeropage i prywatny fragment
; danych "DATA", oba przyznane dynamicznie w trakcie ładowania
; procesu do pamięci.
;
; Można to trochę poprawić dodając parametry na stosie, w których każdy
; proces przekaże swoje zmienne, a ta procedura je zaktualizuje
; i zwróci. Niestety nawet tu nie unikniemy korzystania z zeropage
; bo wskaźnik CRSPTR musi być w zeropage. Z CRSPTR nie możemy zrezygnować
; nawet jeśli byśmy za każdym razem liczyli adres na ekranie.
;
; W tej wersji procedury CRSPTR wskazuje zawsze na początek linijki
; na ekranie a nie na znak na ekranie. Żeby wskazać na znak trzeba
; zrobić "ldy CURCOL" a potem "lda (CRSPTR),y".

.export MVCRSR, CURROW, CURCOL, CRSPTR
.import TXTPAGE

.segment "DATA"
CURROW:   .byte 0
CURCOL:   .byte 0

.segment "ZEROPAGE":zeropage
CRSPTR:   .res 2

.segment "CODE"
.proc MVCRSR
    sty CURROW
    stx CURCOL
    lda #0
    sta CRSPTR+1
    tya
    asl
    asl
    adc CURROW          ; 5*wiersz, CLC nie jest potrzebne bo A jest maksymalnie 120
    asl                 ; tu "rol CRSPTR+1" nie jest potrzebne bo A jest maksymalnie 240
    asl
    rol CRSPTR+1
    asl
    rol CRSPTR+1        ; CRSPTR+1 i A mają teraz: wiersz * 40
    sta CRSPTR
    lda CRSPTR+1
    adc TXTPAGE
    sta CRSPTR+1        ; CRSPTR+1 i CRSPTR mają teraz wiersz * 40 + kolumna + TXTPAGE*256
    rts
.endproc
