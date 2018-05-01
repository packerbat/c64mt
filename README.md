# Preemptive Multitasking for Commodore 64

Gdy uruchomimy dowolną grę na Commodore 64, to ze zdziwieniem stwierdzamy, że na tak 
słabym komputerku (jeden, jednordzeniowy, jednowątkowy mikroprocesor) dzieje się
tyle niezależnych rzeczy jednocześnie: porusza się niezależnie kilka postaci, przewija
się płynnie plansza gry, gra w tle muzyka, słychać efekty dźwiękowe jak eksplozje,
szum silnika. Jak to możliwe?

Oczywiście, gry nie byłyby tak efektowne gdyby nie dwa potężne koprocesory:

1. układ graficzny VIC-II, który w tamtych czas zasługiwał na miano GPU,
2. układ dźwiękowy SID, który śmiało można nazwać SPU.

Jednak te dwa koprocesory same z siebie nic nie zrobią, muszą być nieustannie sterowane
przez główny procesor MOS 6510. A wszystko musi być perfekcyjnie zsynchronizowane w czasie
aby uzyskać efekt płynnego ruchu.

A może współczesne techniki wielozadaniowości i przetwarzania równoległego coś by w tym
względzie pomogły? Czy w ogóle napisanie wielozadaniowego systemu operacyjnego jest
możliwe na tak skromnym mikroprocesorze, który kompletnie nie ma żadnego wsparcia
dla wielozadaniowości?

W miarę wolnego czasu będę dokładał kolejne ćwiczenia ilustrujące, coraz bardzie
złożone techniki programowania wielozadaniowego. Opisy tych ćwiczeń będą umieszczane
w podfolderze [doc](https://github.com/packerbat/c64mt/tree/master/doc).

Ćwiczenie nr 1 będzie polegało na implementacji najprostszego sposobu przełączania
zadań a ćwiczenie nr 2 będzie polegało na usunięciu wad tej prymitywnej implementacji.
W kolejnych ćwiczeniach zmienimy założenia tak żeby nasz pseudo system operacyjny
pozwalał uruchamiać szerszą klasę procesów. Te problemy podane są w trzech poniższych
punktach.

1. Dostęp do współdzielonych obszarów pamięci i związany z tym problem zakleszczeń.
   Trzeba wprowadzić sekcje krytyczne, które zagwarantują atomowość operacji, których
   nie wolno przerwać. Bez obszarów współdzielonych procesy nie będą mogły wymieniać
   się informacji miedzy sobą.

2. Możliwość uruchamiania więcej niż jednej kopii
   danego procesu. Trzeba przygotować specjalne wersje wielu procedur, które będą
   wiedziała dla jakiego zdania pracują (reentrant). Dobrym przykładem są stworzone
   na potrzeby ćwiczenia 1 funkcje CHROUT, MVCRSR. Te funkcje wolno wywołać tylko
   w jednym zadaniu. Wywołanie w innymi zadaniu zniszczy zmienne globalne i oba
   procesy ucierpią.

3. Procesy powinny mieć możliwość dynamicznego ładowania z dysku. Taki plik będzie musiał
   mieć nagłówek, w którym będzie komplet informacji o relokacji. W przypadku procesora 6510,
   który nie ma rejestrów segmentowych może się okazać, że to będzie całkiem spory nagłówek.
   Będzie musiał obejmować wszystkie skoki bezwarunkowe, skoki do procedur, odwołania do
   połówek adresów (high/low byte), odwołania do pamięci *zero page*.

Potem można dalej udoskonalać jądra naszego pseudo systemu operacyjnego. Na przykład 
przeanalizować różne metody szeregowania zadań, wprowadzić priorytety, zagwarantować,
żeby żaden proces nie został zagłodzony.

Michał Wilde
