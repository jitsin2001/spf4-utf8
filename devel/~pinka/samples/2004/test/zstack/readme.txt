\ 03.Sep.2004  ruv

 Реализация эксперимента для выявления степени замедления, 
 которое вносит прослойка в виде стека параметров.

 zstack.f  - реализация стека Z-стек  в user-области,
             указатель вершины в переменной ZSP.

 vfm.f     - определение высокоуровневых слов VFM,
             использующей Z-стек в качестве стека параметров.
             Определения делаются на базе соответствующих слов SPF.

 index.f   - загрузка VFM

 test.f    - запуск двух тестов 
                samples\bench\queens.f
                samples\bench\bubble.f
           вначале на SPF, а затем в подгуженной VFM.


 Результаты:
  Выполнением queens в VFM  в  30 с лишним  раз медленней, чем в самом SPF.
  Выполнении bubble - в 20 раз медленней.
