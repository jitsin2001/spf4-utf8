REQUIRE EMBODY    ~pinka/spf/forthml/index.f

`stream-mem.L1.f.xml EMBODY

( Простой бинарный поток данных в динамически распределяемой памяти.
  При исчерпании очередного блока памяти создается новый блок,
  блоки связываются в список. Размер каждого следующего блока
  адаптируется под объем данных для уменьшения общего числа блоков.
  При чтении полностью вычитанные блоки освобождаются.
  Когда читать больше нечего -- длина прочитанного 0.
)


 \ stream-mem-hidden ALSO!

 S" abc" write
 HERE 100 readout TYPE CR

 HERE 10000 write
 HERE 10000 write
 .( available: ) available . CR
 HERE 50000 readout SWAP . . CR
 .( available: ) available . CR
 HERE 50000 readout SWAP . . CR
 .( available: ) available . CR
 HERE 50000 readout SWAP . . CR
 HERE 50000 readout SWAP . . CR
 .( available: ) available . CR
 CR
 HERE 10000 write
 HERE 10000 write
 .( available: ) available . CR
 next-chunk SWAP . . CR
 next-chunk SWAP . . CR
 next-chunk SWAP . . CR
 .( available: ) available . CR



(  О, попалось архивное по близкой теме:
    http://article.gmane.org/gmane.comp.lang.forth.spf/733/ 
    -- письмо от ~yz в spf-dev@ от 2006-05-10
      http://blogs.msdn.com/larryosterman/archive/2004/04/19/116084.aspx
      -- создание временного файла в памяти через атрибуты
      FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_DELETE_ON_CLOSE
)
