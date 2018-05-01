# Ćwiczenie nr 2

Ćwiczenie nr 1 pokazało jak bardzo marnowany był czas procesora w trakcie gdy
aktywny proces nie miał już nic to zrobienia i wchodził w blokującą funkcję WAIT.
Żaden proces nie powinien blokować procesora jeśli nie ma nic do roboty.
Proces powinien zwrócić sterowanie do jądra systemu informując jednocześnie na jakie
zdarzenie czeka. Jądro w tym czasie wykona inne zadania albo, jeśli nic nie będzie miało
do roboty, to przejście w stan niskiego poboru energii (o ile procesor ma taką instrukcję).


