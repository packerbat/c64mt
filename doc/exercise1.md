# Ćwiczenie nr 1

Będzie to najprostsze, dalekie od doskonałości przełączanie zadań. Zadania będą zaprogramowane
na stałe, nie będzie można dodawać dynamicznie nowych zadań. Zadania nie będą wchodzić w interakcje
z otoczeniem (innymi zadaniami), będą całkowicie autonomiczne. Żeby widzieć działanie tych procesów
każdy z nich będzie poruszał swoim spritem. Poruszanie będzie zrobione bardzo prymitywnie. Każdy
proces będzie odpytywał na okrągło zegar i na podstawie upływu czasu będzie wyliczał nowe położenie
według swojego, unikalnego algorytmu poruszania się. Wszystkie zadania będą miały ten sam priorytet.

Nadzorca procesów będzie miał za zadanie obsłużyć przerwanie zegarowe, zapamiętać stan przerwanego
procesu, odtworzyć stan następnego procesu i go wznowić. Aby nadzorca mógł przełączać zadania
musi znać numer bieżącego zadania. Musi również mieć komplet informacji o każdym zadaniu (deskryptory),
które również będą miejscem na przechowywanie wspólnych zasobów.

Kolejne założenia upraszczające to:

1. procesy nie wywołują żadnych usług jądra,
2. procesy dostają przydział rozłącznych, niewielkich bloków pamięci z obszaru *zero page* i adresy
   tych obszarów są wkompilowane w proces,
3. procesy dostają niewielkie, rozłączne porcje stosu (bo prawie go nie potrzebują) a przydziałem
   stosu zajmuje się nadzorca.

Drugie założenie uniemożliwia dynamiczne dodawanie nowych procesów ale za to zapobiega zapamiętywaniu
obszarów *zero page* w deskryptorze.

W tym ćwiczeniu przyjmiemy, że zadania dostaną po 8 bajtów w obszarze *zero page* i po 32 bajty stosu.
Nadzorca dostanie 64 bajty stosu. To umożliwi uruchomienie zaledwie 6 procesów użytkownika.

Deskryptor procesu będzie bardzo mały bo będzie zawierał zaledwie 8 bajtów: rejestry A,X,Y,PC,PS,SP.
Oprócz tego będzie potrzebował 1 bajt na wskaźnik bieżącego procesu. Najwygodniej będzie przechowywać
na stronie zerowej adres deskryptora, który również będzie znajdował się na stronie zerowej.
