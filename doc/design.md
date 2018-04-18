# Preemptive Multitasking for Commodore 64

## Założenia

Projekt ma charakter edukacyjny. Ma pokazać problemy na jakie napotyka twórca
wielozadaniowego systemu operacyjnego przeznaczonego na komputer z jednym, jednordzeniowym,
jednowątkowym procesorem. Oczywiście taka wielozadaniowość jest tylko iluzją. Wiadomo, że procesor
może na raz wykonywać tylko jeden program komputerowy. Trzeba w jakiś sposób przydzielać
procesor i inne zasoby komputera poszczególnym programom. Jak to robić efektywnie?
Na to pytanie nie ma jednoznacznej odpowiedzi. Dużo zależy od charakteru programów,
które chcemy uruchamiać.

Drugim, bardzo ważnym założeniem jest brak jakiejkolwiek (sprzętowej lub softwarowej)
ochrony bloków pamięci czy portów I/O. Każdy proces ma dostęp do wszystkiego i to 
programista, pisząc dany proces, zadba aby nie wchodzić w paradę innym procesom. Takie 
podejście przypomina bardziej programowanie wielowątkowe niż wielozadaniowe. Mimo wszystko
całkowita separacja zadań jest zagadnieniem całkowicie niezależnym od wielozadaniowości.
Wirtualizacja sprzętu również jest niezależnym zagadnieniem. Obie te kwestie można poruszyć
w osobnych artykułach.


### Przetwarzanie wsadowe

Przetwarzanie wsadowe polega na nieinteraktywnym wykonywaniu algorytmu obliczeniowego.
Dla uproszczenia załóżmy, że dane wejściowe zostały zweryfikowane i umieszczone w
pamięci operacyjne znanej dla naszego programu. Program również ma przygotowane miejsce w
pamięci operacyjne, do którego zapisze wyniki. Przykładem komputera, który zarządzał by
takimi zadaniami mógłby być komputer przeznaczony do mnożenia macierzy. Komputer główny
zlecałby takie obliczenia w nieznanej chwili czasu również wtedy gdy wcześniejsze zlecenie
jeszcze się nie zakończyło. Jak łatwo się domyślić w tak specyficznie skonstruowanej sytuacji
wielozadaniowość z wywłaszczaniem pogorszy wydajność naszego komputera obliczeniowego.
Przełączanie zadań wymaga wiele operacji na zapamiętanie stanu zadania, które ma zostać 
przerwane i odtworzenie stanu zdania, które ma zostać za chwilę wznowione. Bardziej 
efektywny byłby tu jednozadaniowy system operacyjny z kolejkowaniem zleceń.

Ważne jest założenie, że danej wejściowe i wyjściowe znajdują się w pamięci operacyjne.
Jeśli dane wejściowe miałyby być pobierane z dysku lub z sieci i wyniki również miałby
być zapisywane na dysku lub wysyłane przez sieć, to warto by taki komputer wyposażyć w
dwuzadaniowy system operacyjny - jedno zadanie do mnożenia macierzy, drugie zadanie
do komunikacji ze światem zewnętrznym.

Jak łatwo się domyśleć przetwarzaniem wsadowym nie będziemy się tu zajmować.

### Cooperative Multitasking

Jest to kolejny model wielozadaniowości, szczególnie efektywny w przypadku słabych mikroprocesorów.
Jego zaletą, jest to, że redukuje przełączanie zadań do minimum. Jednak ma jedną wadę,
zadania w nim uruchamiane muszą być bezbłędne i muszą co jakiś czas wywoływać dowolne usługi
jądra systemu operacyjnego. Tak, ten system polega na zaufaniu. Długotrwałe zadania obliczeniowe
muszą w sposób sztuczny, co jakiś czas, wywołać procedurę jądra. Przykładem takich systemów
operacyjnych jest rodzina Windows 3.x/95/98/ME. W tych systemach używało się do tego funkcji
`PeekMessage`, która nieblokująco pobierała zdarzenia z kolejki zdarzeń bieżącego procesu.

W szczególnych przypadkach w takim systemie można by się obyć nawet bez przerwań IRQ. Zadania
byłyby w kółko uruchamiane i każde z nich sprawdzałoby czy coś jest do zrobienia i jeśli nie to
natychmiast przekazywałoby sterowanie do jądra systemu. Oczywiście takie podejście "usmażyłoby"
współczesne procesory.

Cooperative Multitasking wcale nie umarło wraz z końcem Windows 3.x/95/98/ME, na przykład zostało
zaimplementowane w Python 3.4 asyncio i w Node.js.

### Jedno zadanie główne z podzadaniami o wysokich priorytetach

Ten przypadek jest jednym z najbardziej rozpowszechnionych modeli wielozadaniowości na mikrokontrolerach
choć większość ludzi nie nazwie tego wielozadaniowością. A jednak jest to wielozadaniowość
z krwi i kości, choć narzuca pewne ograniczenia na zdania. Jak łatwo się domyśleć mowa
tu o przerwaniach IRQ i NMI. Pierwszy rodzaj to przerwania maskowalne (mogą być priorytetowe)
a drugi rodzaj to przerwania niemaskowalne (zazwyczaj jedno i nie można go zablokować).
Przerwania IRQ to głównie przerwania od urządzeń wejścia i wyjścia, zegarów itp.
Drugi rodzaj przerwania służy do zgłaszania poważnych awarii. W moim pierwszym
PC (Inswell XT z procesorem Intel 8088 4,7 MHz i 640 MB RAM), przerwanie niemaskowalne służyło
do zgłaszania błędu parzystości pamięci RAM.

Istotą zadań wykonywanych w trakcie obsługi przerwania jest:

1. muszą być skończone,
2. muszą jak najszybciej odblokować przerwania,
3. mogą zostać przerwane tylko innym przerwaniem (po odblokowaniu przerwań) lub przez NMI.

Pierwszy punkt mówi, że tylko zadanie główne może trwać w nieskończoność. Obsługa przerwań
musi się być jak najkrótsza i powrócić do zadania głównego, tak żeby zadanie główne nie ucierpiało
w trakcie obsługi przerwania. A zatem zadanie główne nie powinno mieć żadnych miejsc czasowo
krytycznych (np. nie może programowo generować impulsu o szerokości 0.5 milisekundy na jakimś pinie
wyjściowym bo przerwanie, które może się zdarzyć w trakcie odmierzania 0.5 milisekundy może
wydłużyć czas trwania tego impulsu a program główny nie będzie o tym wiedział).

Ten model, choć ograniczony, jednak jest niezwykle efektywny. Obsługa przerwania w ogóle nie musi
zapamiętywać stanu przerwanego zadania, wystarczy, że na stosie przechowa rejestry, które
są potrzebne do wykonania obsługi przerwania.

Przerwania są konieczne bo bez nich nie można zrealizować wielozadaniowości z wywłaszczaniem.
Minimalny zestaw przerwań to przerwanie zegarowe, które pozwoli przełączać zadania. Teoretycznie
wszystkie pozostałe czynności (np. obsługę urządzeń wejścia/wyjścia) można powierzyć zadaniom
(choć nie będzie to efektywne podejście).

### Preemtive Multitasking

W wielozadaniowości z wywłaszczaniem zadania dostają czas procesora i inne zasoby na określony
odcinek czasu, zwykle niewielki, liczony w milisekundach albo dziesiątkach milisekund. W efektywnym
systemie wielozadaniowym procesy, które zgłoszą oczekiwanie na jakieś zdarzenie (lub zbiór zdarzeń)
w ogóle nie dostaną procesora. Dostaną go dopiero gdy zdarzy się coś na co czeka ten proces np.
zostanie odebrany pakiet danych przez interfejs sieciowy, albo dysk twardy prześle kolejny
sektor danych albo port szeregowy odbierze bajt albo zegar odmierzy zadany czas.
Procesy, które wykonują długotrwałe obliczenia dostaną równe kwanty
czasu albo zgodnie z priorytetami przypisanymi do procesów. Może się tak zdarzyć, że żaden
proces nie potrzebuje procesora. Wtedy system operacyjny może zdecydować o przejściu procesora
w stan niskiego poboru prądu. Uśpiony procesor może zostać wybudzony jakimś zewnętrznym zdarzeniem
np. przerwaniem IRQ.

Właśnie takim modelem wielozadaniowości chcę się zająć w tym artykule.

## Platforma testowa

Jako platformę do zabaw z wielozadaniowością wybrałem Commodore 64. Jest to idealna
platforma testowa. Zalety to:

1. niezwykle prosty kod maszynowy mikroprocesora 6502/6510,
2. brak rozgraniczenia między pamięcią a urządzeniami wejścia/wyjścia (wszystko jest pamięcią),
3. całkowite panowanie nad maszyną,
4. niezwykły układ graficzny VIC-II (w tamtych czasach zasługiwał na nazwę GPU),
5. niezwykły układ do generacji polifonicznego dźwięku SID,
6. obszerna i szczegółowa dokumentacja "C64 Programmer's Reference Guide" z licznymi przykładami,
7. wygodna kompilacja programów dzięki kroskopilatorowi [cc65](https://www.cc65.org),
8. kompletny emulator o nazwie [VICE](http://vice-emu.sourceforge.net) w pełni zgodny ze sprzętem.

Mapa pamięci będzie zrobiona na wyrost będzie uwzględniała możliwość użycia techniki *double buffer*.
Z tego powodu trzeba osobno zaprojektować mapę dla trybu tekstowego i trybu wysokie rozdzielczości.

W trybie tekstowym ekran zajmuje zaledwie 1 KB więc można zrobić
technikę podwójnego buforowania w ramach jednego banku pamięci. Niestety
pamięć kolorów jest wspólna dla wszystkich ekranów tekstowych (bez względu na bank pamięci)
i znajduje się pod adresem $D800. Innymi słowy nie da się zrobić pełnego podwójnego buforowania
w trybie tekstowym, bo pamięć kolorów trzeba będzie zaktualizować tuż przez przełączeniem
ekranów. Wskaźniki na sprite trzeba zawsze programować podwójnie: te same adresy pod
$63F8-$63FF i pod $67F8-$67FF.

    $0000-$00FF - 256 bajtów "zero page"
    $0100-$01FF - 256 bajtów stosu
    $0200-$07FF - obszar na zmienne niezainicjowane
    $0800-$3FFF - 14 KB na programy
    $4000-$7FFF - 16 KB pierwszy bank wideo
       $4000-$47FF - programowalne czcionki trybu tekstowego
       $4800-$5FFF - unused
       $6000-$63F7 - ekran tekstowy nr 1
       $63F8-$63FF - 8 wskaźników na definicje spritów
       $6400-$67F7 - ekran tekstowy nr 2
       $67F8-$67FF - 8 wskaźników na definicje spritów
       $6800-$7FFF - miejsce na 96 spritów po 64 bajty
    $8000-$BFFF - 16 KB drugi bank wideo, unused
    $C000-$CFFF - unused, in future space for Multitasking Kernel
    $D000-$DFFF - zewnętrzne urządzenia wejścia/wyjścia
    $E000-$FFF9 - KERNAL in RAM, practically not used, probably will by replaced by Multitasking Kernel.
    $FFFA-$FFFB - Vector NMI
    $FFFC-$FFFD - Vector RESET
    $FFFE-$FFFF - Vector IRQ

W trybie wysokiej rozdzielczości nie można wykorzystać dwóch stron w ramach
jednego banku pamięci bo to by oznaczało przerzucanie spritów między dwiema połowami banku.
Tu trzeba przełączać banki. W obu bankach trzeba definiować te same sprity. Podobnie
wskaźniki na sprity umieszczone na końcu pamięci kolorów muszą być identyczne w obu
bankach.

    $0000-$00FF - 256 bajtów "zero page"
    $0100-$01FF - 256 bajtów stosu
    $0200-$07FF - obszar na zmienne niezainicjowane
    $0800-$3FFF - 14 KB na programy
    $4000-$7FFF - 16 KB pierwszy bank wideo
       $4000-$43F7 - pamięć kolorów
       $43F8-$43FF - 8 wskaźników na definicje spritów
       $4400-$4FFF - miejsce na 48 spritów
       $5000-$5FFF - CPU i VIC-II widzą tu zwykły RAM
       $6000-$7FFF - ekran graficzny wysokiej rozdzielczości
    $8000-$BFFF - 16 KB drugi bank wideo
       $8000-$83F7 - pamięć kolorów
       $83F8-$83FF - 8 wskaźników na definicje spritów 
       $8400-$8FFF - miejsce na 48 spritów
       $9000-$9FFF - VIC-II widzi tu zawsze ROM z czcionkami, ale CPU może korzystać z tego obszaru
       $A000-$BFFF - ekran graficzny wysokiej rozdzielczości
    $C000-$CFFF - unused, in future space for Multitasking Kernel
    $D000-$DFFF - zewnętrzne urządzenia wejścia/wyjścia
    $E000-$FFF9 - KERNAL in RAM, practically not used, probably will by replaced by Multitasking Kernel.
    $FFFA-$FFFB - Vector NMI
    $FFFC-$FFFD - Vector RESET
    $FFFE-$FFFF - Vector IRQ

Architektura Commodore 64 ma również wiele wad, które niezwykle utrudniają pisanie relokowalnych
programów oraz pisanie programów wielozadaniowych:

1. maleńki stos o wielkości 256 bajtów na stałe mieszczony w obszarze $0100-$01FF,
2. specjalna, maleńka strona *zero page* w obszarze $0002-$00FF, bez której nie działa wiele
   rozkazów mikroprocesora - szczególnie adresowanie indeksowe np. LDA&nbsp;($FB),Y,
3. brak rejestrów segmentowych znanych z architektury Intel 8x86, które niezwykle upraszczają
   pisanie programów relokowalnych.

## C64MT.LIB

Aby ułatwić pisanie eksperymentalnych programów powstała biblioteka ze zbiorem przydatnych
procedur. Wszystkie procedury są relokowalne i zostaną dołączone według potrzeby przez linker.

Funkcje w tej bibliotece dzielą się na 3 zasadnicze grupy: praca w trybie tekstowym, praca
w trybie graficznym i procedury nie związane z grafiką.

### Praca w trybie graficznym

Proste użycie opisanych tu procedur zostało zilustrowane w przykładowym programie
`dbuf.s`. Program można skompilować w dwóch wariantach: bez użycia *double buffer*
i z wykorzystaniem *double buffer*. Program `dbuf` nieustanie czyści ekran wysokiej
rozdzielczości i rysuje obracający się kwadrat na środku ekranu. Widać, że po
włączeniu trybu *double buffer* miganie ekranu ustało.


#### INIT

Procedura INIT ma za zadanie zainicjować mapę pamięci i podstawową obsługę przerwań. Przed
jej wywołanie trzeba wywołać procedurę Wykonuje:

1. kopię obszaru $E000-$FFFF z ROM do RAM, żeby można było podmienić wektory przerwań,

2. kopiuje czcionki z ROM do $9000-$97FF móc je malować na ekranie graficznym,

3. wyłącza KERNAL ROM i BASIC ROM,

4. wyłącza *double buffer*,

5. włącza tryb graficzny w banku 1 i ustawia bank rysowania również na 1,

6. czyści oba banki ekranu graficznego (również ten niewidoczny),

7. ustawia podstawową obsługę przerwań.
   

Obszar pamięci $9800-$9FFF pozostaje wolny ale nie może on być wykorzystany ani na sprity ani
na pamięć kolorów (VIC-II go nie widzi, bo w tym miejscu jest ROM z czcionkami).

#### SETDB

Procedura służy do włączania lub wyłączania techniki *double buffer*. Aby włączyć tryb
*double buffer* trzeba wywołać tę procedurę z akumulatorem równym 1 jak na przykładzie poniżej:

    lda #1
    jsr SETDB

Aby wyłączyć trzeba wywołać z akumulatorem równym 0.

    lda #0
    jsr SETDB

Zadaniem tej procedury jest też właściwe ustawienie zmiennej VIDPAGE, która wskazuje na
widoczny bank pamięci wideo (gdy *double buffer* jest wyłączone) albo na niewidoczny bank
pamięci (gdy *double buffer* jest włączone).

#### HGR

Procedura HGR służy do przełączanie grafiki w tryb wysokiej rozdzielczości w banku 1.
Ta procedura również wyłącza tryb *double buffer* i ustawia VIDPAGE na $6000 czyli
również w banku nr 1. To co użytkownik narysuje jest jednocześnie widoczne na
ekranie. Procedura nie ma parametrów.

#### CLS

Procedura CLS służy do wyczyszczenia grafiki wysokiej rozdzielczości. Procedura
czyści wskazany bank w zmiennej VIDPAGE (czyli gdy włączona jest technika *double buffer*
to czyści bank pamięci, którego nie widać). Pamięć ekranu jest wypełniana zerami,
a pamięć kolorów jest wypełniana wartością podaną w akumulatorze.

#### SWAPSCR

Procedura SWAPSCR służy do przełączania banków pamięci jeśli tryb *double buffer*
jest włączony. Jeśli tryb *double buffer* nie jest włączony to ta procedura nic nie robi.
Procedura również ustawia poprawną stronę pamięci graficznej w zmiennej VIDPAGE w zależności
o tego czy tryb *double buffer* jest włączony czy nie. Procedura nie ma parametrów.

#### POT

Procedura POT rysuje punkt na ekranie wysokiej rozdzielczości w banku pamięci
podanym w zmiennej VIDPAGE. Przed wywołaniem trzeba podać współrzędne punktu
w zmiennych XP i YP (obie 16-bitowe). Współrzędna XP musi być w zakresie 0..319
a współrzędna YP w zakresie 0.199. Jeśli któryś z tych zakresów nie będzie
spełniony to procedur POT nic nie robi. Sposób rysowania zależy od wartości zmiennej
PTYP. Jeśli jest podana wartość 0 - to piksel zostanie wyzerowany, jeśli wartość
1 - to piksel zostanie ustawiony, jeśli wartość 2 - to piksel zostanie zanegowany.

    lda #2
    sta PTYP
    lda #10
    ldy #0
    sta XP
    sty XP+1
    lda #123
    ldy #0
    sta YP
    sty YP+1
    jsr POT

zaneguje piksel w kolumnie 10, wierszu 123 licząc od lewego górnego narożnika.

#### LINE

Procedura LINE rysuje odcinek na ekranie wysokiej rozdzielczości w banku pamięci
podanym w zmiennej VIDPAGE. Przed wywołaniem trzeba podać współrzędne punktu
początkowego w zmiennych XP i YP (obie 16-bitowe) i współrzędne końca w zmiennych
XK i YK (również obie 16-bitowe). Współrzędne początku i końca nie muszą pokrywać
się z zakresem ekranu graficznego czyli 0..319 i 0..199. Punkty odcinka są 
rysowane przez funkcję POT, która zignoruje punkty wykraczające poza zakres
ekranu. Sposób rysowania zależy od wartości zmiennej PTYP. Jeśli jest podana
wartość 0 - to piksele odcinka zostaną wyzerowane, jeśli wartość 1 - to piksele
zostaną ustawione, jeśli wartość 2 - to piksele zostaną zanegowane.

Procedura LINE zawsze kończy swoje działanie z wartościami XP=XK i YP=YK. Dzięki
temu można rysować łamane:

    lda #1
    sta PTYP
    lda #10
    ldy #0
    sta XP
    sty XP+1
    lda #123
    ldy #0
    sta YP
    sty YP+1
    lda #10
    ldy #0
    sta XK
    sty XK+1
    lda #50
    ldy #0
    sta YK
    sty YK+1
    jsr LINE
    lda #110
    ldy #0
    sta XK
    sty XK+1
    lda #50
    ldy #0
    sta YK
    sty YK+1
    jsr LINE

zaneguje piksel w kolumnie 10, wierszu 123 licząc od lewego górnego narożnika.

Procedura LINE nie jest optymalnie napisana bo wykorzystuje funkcję POT, która
za każdym razem oblicza adres i bit piksela. Można pokusić się o napisanie
znacznie szybszej procedury, która tylko 1 raz wyliczy adres i bit piksela a
następne piksele będzie rysować relatywnie do obliczonego za pierwszym razem
adresu gdyż kolejne punku odcinka zawsze ze sobą sąsiadują pionowo, poziomo
lub po skosie. Kolejnym przyspieszeniem będzie wykrycie linii poziomych i 
pionowych, które można (z wyjątkiem końcówek) rysować po 8 pikseli na raz.

### Praca w trybie tekstowym

Proste użycie opisanych tu procedur zostało zilustrowane w przykładowym programie
`dbuft.s`. Program można skompilować w dwóch wariantach: bez użycia *double buffer*
i z wykorzystaniem *double buffer*. Program na przemian czyście ekran tekstowy i
wypełnia losowym znakiem. Tu też widać, że po włączeniu trybu *double buffer*
miganie ekranu ustało.

#### INITT

Procedura INITT ma za zadanie zainicjować mapę pamięci i podstawową obsługę przerwań
w trybie tekstowym. Przed jej wywołanie trzeba wywołać procedurę Wykonuje:

1. kopię obszaru $E000-$FFFF z ROM do RAM, żeby można było podmienić wektory przerwań,

2. kopiuje czcionki z ROM do $4000-$47FF (niezbędne do pracy trybu tekstowego),

3. wyłącza KERNAL ROM i BASIC ROM,

4. wyłącza *double buffer*,

5. włącza tryb tekstowy w banku 1 i ustawia pierwszy ekran tekstowy pod adresem $6000-$63FF,

6. czyści oba ekrany tekstowe (również ten niewidoczny),

7. ustawia podstawową obsługę przerwań.
   
#### SETDBT

Procedura służy do włączania lub wyłączania techniki *double buffer* w trybie tekstowym.
Aby włączyć tryb *double buffer* trzeba wywołać tę procedurę z akumulatorem równym 1 jak
na przykładzie poniżej:

    lda #1
    jsr SETDBT

Aby wyłączyć trzeba wywołać z akumulatorem równym 0.

    lda #0
    jsr SETDBT

Zadaniem tej procedury jest też właściwe ustawienie zmiennej TXTPAGE, która wskazuje na
widoczny ekran tekstowy (gdy *double buffer* jest wyłączone) albo na niewidoczny ekran
tekstowy (gdy *double buffer* jest włączone).

#### NRM

Procedura NRM służy do przełączanie grafiki w tryb tekstowy w banku nr 1.
Ta procedura również wyłącza tryb *double buffer* i ustawia TXTPAGE na $6000 czyli
pierwszy ekran. To co użytkownik narysuje jest jednocześnie widoczne na
ekranie. Procedura nie ma parametrów.

#### CLST

Procedura CLST służy do wyczyszczenia ekranu w trybie tekstowym. Procedura
czyści ekran wskazany przez zmienną TXTPAGE (czyli gdy włączona jest technika *double buffer*
to czyści ekran, którego nie widać). Pamięć ekranu jest wypełniana spacjami (wartość 32),
a pamięć kolorów jest wypełniana wartością podaną w akumulatorze.

#### SWAPSCRT

Procedura SWAPSCRT służy do przełączania banków pamięci jeśli tryb *double buffer*
jest włączony. Jeśli tryb *double buffer* nie jest włączony to ta procedura nic nie robi.
Procedura również ustawia poprawną stronę pamięci graficznej w zmiennej TXTPAGE w zależności
o tego czy tryb *double buffer* jest włączony czy nie. Procedura nie ma parametrów.

