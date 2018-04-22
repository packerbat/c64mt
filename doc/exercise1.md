# Ćwiczenie nr 1

Będzie to najprostsze, dalekie od doskonałości przełączanie zadań. Zadania będą zaprogramowane
na stałe, nie będzie można dodawać dynamicznie nowych zadań. Zadania nie będą wchodzić w interakcje
z otoczeniem (innymi zadaniami), będą całkowicie autonomiczne. Żeby widzieć działanie tych procesów
każdy z nich będzie poruszał swoim spritem z wyjątkiem jednego zadania, które będzie zmieniać ekran
tekstowy. Poruszanie będzie zrobione bardzo prymitywnie. Każdy
proces będzie "malował" swój obiekt, odczekiwał chwilę w sposób blokujący, a następnie wyznaczał 
nowe położenie swojego elementu i "malował" znowu. Wszystkie zadania będą miały ten sam priorytet.

Nadzorca procesów będzie miał za zadanie obsłużyć przerwanie zegarowe, zapamiętać stan przerwanego
procesu, odtworzyć stan następnego procesu i go wznowić. Aby nadzorca mógł przełączać zadania
musi znać numer bieżącego zadania. Musi również mieć komplet informacji o każdym zadaniu (deskryptory),
które również będą miejscem na przechowywanie wspólnych zasobów.

Kolejne założenia upraszczające to:

1. procesy nie wywołują żadnych usług jądra (z wyjątkiem funkcji WAIT, która nie korzysta
   z żadnych zasobów i jest wielowejściowa),
2. lista procesów jest stała (nie można dodawać nowych procesów ani usuwać istniejących),
3. procesy, w trakcie kompilacji, dostają rozłączne fragmenty pamięci z obszaru *zero page*
   (*zero page* przestaje być wspólnym zasobem i nie musi być kopiowana do deskryptorów),
4. procesy dostają niewielkie, rozłączne porcje stosu (bo prawie go nie potrzebują) a przydziałem
   stosu zajmuje się nadzorca.

W tym ćwiczeniu przyjmiemy, że zadania dostaną po 32 bajty stosu z wyjątkiem procesu 0,
który dostanie 64 bajty stosu. To umożliwi uruchomienie zaledwie 6 procesów użytkownika.
Trzeba pamiętać, że w tych 32 bajtach potrzebne jest również miejsce na obsługę przerwań
i na przełączanie zadań (które ma podobne zapotrzebowania na stos jak obsługa przerwań).

Deskryptor procesu będzie bardzo mały bo będzie zawierał zaledwie 8 bajtów: rejestry A,X,Y,PC,PS,SP,STATE.
Ostatni bajt o nazwie STATE będzie zawierał informację os stanie deskryptora. Na razie będzie
to tylko informacja, czy deskryptor jest zajęty czy pusty (najstarszy bit). W przyszłości
będzie można w tym bajcie zawrzeć informację o tym, że dany proces czeka na jakieś
zdarzenie i nie ma nic do roboty (status *sleep*).

Jeśli proces miałby być ładowany z dysku to będzie musiał mieć nagłówek, w którym
będzie komplet informacji o relokacji. W przypadku procesora 6510, który nie ma rejestrów
segmentowych może się okazać, że to będzie całkiem spory nagłówek. Będzie musiał obejmować
wszystkie skoki bezwarunkowe, skoki do procedur, odwołania do połówek adresów, odwołania do 
pamięci *zero page*. Ale to są problemy do rozwiązania w znacznie późniejszych ćwiczeniach.

Największym mankamentem tego ćwiczenia jest to, że zawiera on blokujące funkcje WAIT, które
w takim środowisku wielozadaniowym mogą zostać przerwane przez inny proces więc ich czas
wykonania jest nieprzewidywalny. Zatem następnym problem do rozwiązania będzie poinformowanie jądra
na co czeka dany proces i przekazanie sterowania do jądra. Jądro w tym czasie wykona
inne zadania lub jeśli nic nie będzie miało roboty, to przejście w stan niskiego poboru
energii (w przypadku 6510, który nie ma instrukcji HLT, wywoła proces *idle*).
