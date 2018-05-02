# Ćwiczenie nr 2

Ćwiczenie nr 1 pokazało jak bardzo marnowany był czas procesora w trakcie gdy
aktywny proces nie miał już nic to zrobienia i wchodził w blokującą funkcję WAIT.
Żaden proces nie powinien blokować procesora jeśli nie ma nic do roboty.
Proces powinien zwrócić sterowanie do jądra systemu informując jednocześnie na jakie
zdarzenie czeka. Jądro w tym czasie wykona inne zadania albo, jeśli nic nie będzie miało
do roboty, to przejście w stan niskiego poboru energii (o ile procesor ma taką instrukcję).

Zazwyczaj zdarzenia w systemie tworzy się dynamicznie w miarę potrzeby np. otwarcie pliku,
otwarcie gniazda sieciowego, uruchomienie zegara itp. Dla uproszczenia stworzymy 6 zdarzeń,
które będą istniały przez cały czas w systemie. Te zdarzenia to:

1. 4 zegary programowe o rozdzielczości 1/60 sekundy,
2. pojawił się klawisz w kolejce klawiatury,
3. VIC-II wygenerował przerwanie typu raster.

Oczywiście zegary nie będą "pracować" póki któryś z procesów nie uruchomi takiego
zegara wpisując wartość to przeładowania różną od 0. Podobnie przerwanie raster
od VIC-II będzie początkowo zablokowane.

Ponieważ nasz system jeszcze nie przechowuje żadnych dodatkowych informacji
o procesach (pomijam tu informacje niezbędne do przełączania zadań) więc na razie
nie będzie kontroli, który proces uruchomił dane zdarzenie (np. który zegar). To
programista będzie musiał zadbać aby proces nasłuchiwał tylko na te zdarzenia,
które sam uruchomił. Oczywiście w przyszłości trzeba będzie wprowadzić identyfikatory
procesów i przypisywać je do zasobów zajętych przez dany proces.

Przy tak mocnych założeniach upraszczających, unixowa funkcja select (poll, epoll) czy
windowsowe WaitForEvent upraszcza się do podania bitowej maski zdarzeń na jaką
czeka dany proces. Będzie to oznaczało, że deskryptor zadania wydłuży się zaledwie
o 1 bajt, w którym będą zdefiniowane flagi sześciu zdarzeń. Jeśli jakieś zdarzenie
(lub kilka na raz) zaistnieje to proces dostanie bitowe znaczniki (np. w akumulatorze),
informujące co się stało.

Poniższy diagram czasowy pokazuje jak działa program z ćwiczenia nr 2 (z znacznym
uproszczeniu).

![exercise 2 time diagram](ex2time.svg)
