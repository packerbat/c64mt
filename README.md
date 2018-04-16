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
aby uzyskać efekt płynnego ruchy.

A może współczesne techniki wielozadaniowości i przetwarzania równoległego coś by w tym
względzie pomogły? Czy w ogóle napisanie wielozadaniowego systemu operacyjnego jest
możliwe na tak skromnym mikroprocesorze, który kompletnie nie ma żadnego wsparcia
dla wielozadaniowości?

W miarę wolnego czasu będę dokładał kolejne ćwiczenia ilustrujące, co raz bardzie
złożone techniki programowania wielozadaniowego. Opis tych ćwiczeń będzie umieszczony
w podfolderze [doc](https://github.com/packerbat/c64mt/tree/master/doc).

Michał Wilde
