REQUIRE EMBODY    ~pinka/spf/forthml/index.f

`envir.f.xml            FIND-FULLNAME2 EMBODY  xml-struct-hidden::start
`spf4-64.f.xml          FIND-FULLNAME2 EMBODY

emu64 ALSO! DEFINITIONS

 ORDER

 \ данные в словаре emu64 слова (лексикон 64x форт-процессора) требуют,
 \ чтобы ячейки стека возвратов тоже были 64x,
 \ поэтому их нельзя откладывать штатным кодогенератором.

  10. 20. 30. 2. PICK D. 2DROP DROP CR
  \ --> 10
