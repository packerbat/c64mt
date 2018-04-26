;----------------------------
; Procedura JOBS podaje liczbę aktywnych procesów
; input: X=kolumna 0..39, Y=wiersz 0..24
; output: Y=?, X=?, A=kolumna, NZCIDV=011---
; stack: 4
; reentrant: no
;
; Ta procedura ma zmienne globalne więc może być użyta tyko w jednym
; wątku, użycie w innym wątku zmieni globalne zmienne CURROW, CURCOL, CRSPTR
; Żeby ta procedura miała sense w środowisku wielozadaniowym
; to musielibyśmy odczytać z dekryktora zadania wskaźnik na dwa
; bloki pamięci - prywatny fragment zeropage i prywatny fragment
; danych "DATA"
;
; Można to trochę poprawić dodając parametry na stosie, w których każdy
; proces przekaże swoje zmienne, a ta procedura je zaktualizuje
; i zwróci. Niestety nawet tu nie unikniemy korzystania z zeropage
; bo wskaźnik CRSPTR musi być w zeropage.

.export MVCRSR, CURROW, CURCOL, CRSPTR
.import TXTPAGE

.define NEWCOL a:$101,x
.define TMPH a:$100,x
.define TMPL a:$0FF,x
.define NEWROW a:$0FE,x

.segment "DATA"
CURROW:   .byte 0
CURCOL:   .byte 0

.segment "ZEROPAGE":zeropage
CRSPTR:   .res 2

.segment "CODE"
.proc MVCRSR
    txa
    pha                 ; X dostępne jako lda $101,x
    tsx
    lda #0
    pha                 ; PTRH dostępne jako lda $0FF,x
    pha                 ; PTRL dostępne jako lda $0FE,x
    tya
    pha                 ; Y dostępne jako lda $100,x

    asl
    asl
    adc NEWROW          ; 5*wiersz, CLC nie jest potrzebne bo A jest maksymalnie 120
    asl
    rol TMPH
    asl
    rol TMPH
    asl
    rol TMPH            ; $103,x i A mają teraz: wiersz * 40
    adc NEWCOL          ; $103,x i A mają teraz: wiersz * 40 + kolumna, CF na pewno jest 0
    sta TMPL
    lda TMPH
    adc #0
    adc TXTPAGE
    sta TMPH            ; $104,x i $103,x mają teraz wiersz * 40 + kolumna + TXTPAGE*256

    lda NEWROW
    sta CURROW
    lda NEWCOL
    sta CURCOL
    lda TMPL
    sta CRSPTR
    lda TMPH
    sta CRSPTR+1

    txs             ;szykie 3 x PLA
    pla             ;to przywróci A
    rts             ;jak nie ma wolnego slota to procedura START_JOB jest całkowicie przezroczysta
.endproc
