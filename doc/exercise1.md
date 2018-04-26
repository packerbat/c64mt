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
3. ten sam rodzaj zadania nie można uruchomić w dwóch kopiach jednocześnie (zadania nie są
   wielowejściowe),
4. zadania można zatrzymać (z wyjątkiem zadania 0) i uruchomić ponownie,
5. zadania nie mogą przydzielać sobie dynamicznie pamięci dlatego nadzorca nie musi
   kontrolować co, który proces posiada (nic nie jest czyszczone przy zatrzymywaniu zadania),
5. procesy, w trakcie kompilacji, dostają rozłączne fragmenty pamięci z obszaru *zero page*
   (*zero page* przestaje być wspólnym zasobem i nie musi być kopiowana do deskryptorów),
6. procesy dostają niewielkie, rozłączne porcje stosu (bo prawie go nie potrzebują) a przydziałem
   stosu zajmuje się nadzorca.

W tym ćwiczeniu przyjmiemy, że zadania dostaną po 32 bajty stosu z wyjątkiem procesu 0,
który dostanie 64 bajty stosu. To umożliwi uruchomienie zaledwie 6 procesów użytkownika.
Trzeba pamiętać, że w tych 32 bajtach potrzebne jest również miejsce na obsługę przerwań
i na przełączanie zadań (które ma podobne zapotrzebowania na stos jak obsługa przerwań).

Deskryptor procesu będzie bardzo mały bo będzie zawierał zaledwie 8 bajtów: rejestry A,X,Y,PC,PS,SP
i bajt STATE, który będzie zawierał flagi procesu takie jak: deskryptor zajęty/wolny, żądanie
zamknięcia, potwierdzenia zamknięcia. W przyszłości można dodać jeszcze flagę uśpienia procesu,
która pozwoli pomijać uśpione zadania w trakcie przełączania zadań.

Proces musi sam monitorować stan flagi żądania zamknięcia. Jeśli tego nie będzie robił
i nie zareaguje na żądanie to proces będzie się wykonywał dalej. Na razie nie ma mechanizmu,
który pozwoliłby zamknąć proces brutalnie (odpowiednik `kill -9`).

W ćwiczeniu nr 1 proces 0 jest zalążkiem procesu systemu operacyjnego. To on uruchamia
3 podprocesy: SUN, MOON i TOWN. Po ich uruchomieniu staje się rodzajem terminala systemowego.
U góry tworzy jeden wiesz z informacjami o stanie programu a na dole dwa wiersze konsoli.
Informacje o stanie programu to:

1. jednoznakowy licznik wywołania IRQ,
2. liczba aktywnych zadań (włącznie z procesem systemowym może być ich tylko 7),
3. flagi klawiatury (16 cyfr hex) 
4. stan klawiszy modyfikujących (Shift, Ctrl, C=)

Konsola pozwala pisać komendy:

1. STOP <nr slotu> zamyka proces o podanym numerze, <nr  slotu> może mieć wartość 1..6,
2. START <job> uruchamia proces podanego typu, <job> może być literą S, M albo T (odpowiednio
   słońce, księżyc, wieżowce).

Błędna komenda zwróci ERROR, dobra komenda się wykona bez żadnego komunikatu.

Możliwość zamykania procesów dobitnie pokazuje, jak przyspieszają zadania, które jeszcze
nie zostały zamknięte. Im mniej procesów tym szybciej pracują pozostałe.
Jest to efekt stosowanie blokujących funkcji WAIT. Oczywiście te blokujące funkcje
WAIT nie blokują innych wątków a jedynie wątek, który ją wywołał. Blokująca funkcja WAIT
jest zła z jeszcze jednego powodu. W środowisku wielozadaniowym taka funkcja może w każdej
chwili zostać przerwana przez inny proces a zatem czas wykonania takiej funkcji jest
nieprzewidywalny. Tym problemem trzeba się zająć w pierwszej kolejności. Proces powinien
zwrócić sterowanie do jądra systemu informując jednocześnie na jakie zdarzenie czeka.
Jądro w tym czasie wykona inne zadania albo, jeśli nic nie będzie miało roboty, to
przejście w stan niskiego poboru energii (w przypadku 6510, który nie ma instrukcji HLT,
wywoła proces *idle*). 

Ważnymi i trudnymi problemami są:

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
   połówek adresów, odwołania do pamięci *zero page*.
   
Ale to są problemy do rozwiązania w następnych ćwiczeniach.

