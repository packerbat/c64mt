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
bankach

    $0000-$00FF - 256 bajtów "zero page"
    $0100-$01FF - 256 bajtów stosu
    $0200-$07FF - obszar na zmienne niezainicjowane
    $0800-$3FFF - 14 KB na programy
    $4000-$7FFF - 16 KB pierwszy bank wideo
       $4000-$43F7 - pamięć kolorów
       $43F8-$43FF - 8 wskaźników na definicje spritów
       $4400-$4FFF - miejsce na 48 spritów
       $5000-$5FFF - czcionki do malowania w trybie wysokiej rozdzielczości
       $6000-$7FFF - ekran graficzny wysokiej rozdzielczości
    $8000-$BFFF - 16 KB drugi bank wideo
       $8000-$83F7 - pamięć kolorów
       $83F8-$83FF - 8 wskaźników na definicje spritów 
       $8400-$8FFF - miejsce na 48 spritów
       $9000-$9FFF - czcionki do malowania w trybie wysokiej rozdzielczości
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

### INIT

Procedura INIT ma za zadanie zainicjować mapę pamięci i podstawową obsługę przerwań.
