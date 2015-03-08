Изучаем электронную музыку с Haskell -- Основы 
=========================================================

Привет! Давайте поэкспериментируем с электронной музыкой в Haskell.
На hackage есть библиотека csound-expression. Эта библиотека
позволяет писать электронную музыку в Haskell. Это DSL для создания
файлов порграммного синтезатора Csound. Csound это язык программирования
синтезаторов и электронной музыки. Он очень эффективный, но и весьма
неуклюжий. В нём совсем мало абстракций и многие операции приходится выполнять
на низком уровне. Бибилотека csound-expression зачительно упрощает процесс
создания музыки в Csound.

В этой небольшой статье мы рассмотрим основные понятия электронной
музыки. Мы посмотрим на осцилляторы, фильтры, LFO и другие элементы,
которые часто встречаются в синтезаторах. 

Установка и запуск
------------------------

Нам понадобится [Csound](http://www.csounds.com/). Если установка 
прошла успешно мы сможем выполнить в командной строке

~~~
> csound
~~~

Должно появится длинное сообщение с версией Csound (она должна быть не ниже 5.13).
Теперь установим библиотеку csound-expression:

~~~
> cabal update
> cabal install csound-expression
~~~

Вызовем `ghci` и загрузим основной модуль `Csound.Base`:

~~~
> ghci
> :m +Csound.Base
~~~

Теперь послушаем синусоиду на частоте 440 Hz:

~~~haskell
> dac $ osc 440
~~~

Если всё установилось правильно мы должны услышать 
звук. Остановить программу можно нажав `Ctrl+C`.
Иногда в Windows Csound жалуется на отсутствие dll
для Python. Если это произошло находим соответствующий dll
и сохраняем его в папке `C:\Windows\system32`.


Слушаем звук в реальном времени и сохраняем на диск
----------------------------------

Вернёмся к первой команде:

~~~haskell
> dac $ osc 440
~~~

Почему мы слышим звук? Функция `osc` создаёт синусоиду 
с заданной частотой, а функция `dac` создаёт в текущей директории
файл `tmp.csd` и запускает на нём Csound с флагом `-odac`.
Этот флаг говорит о том, что мы посылаем звук в звуковую карту.

????????????

Если у нас несколько звуковых карт, то эта команда может дать сбой.
Мы не услышим звук. В этом случае необходимо указать номер карты
с которой звук идёт на колонки. Узнать этот номер можно, запустив 
команду csound с заведомо большим индексом карты:

~~~
> csound -o dac99 tmp.csd
~~~

Csound напечатает все доступные звуковые карты. 
Допустим мы хотим послать звук в карту `dac:`.
Тогда мы выполняем команду:

~~~haskell
> let run = dacBy (setDacBy "dac5")
> run $ osc 440
~~~

???????????????




