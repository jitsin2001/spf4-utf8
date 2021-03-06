\ 2006-12-09 ~mOleg

      Есть несколько подходов, применяемых для вывода сообщений на
экран ( в том числе сообщений об ошибках).

Можно писать ошибки в расшифрованном виде в тексте определений:
      Abort" the error message" - это наглядно, но не всегда удобно,
      так как одно и то же сообщение может быть вызвано целым рядом
      определений - то есть налицо перерасход памяти;

      можно создавать отдельные определения с именами ошибок:
      : err007 Abort" ошибка номер семь" ; - и дальше использовать
      ссылку на такое определение - перерасход имен, из текста сложно
      понять что же все-таки за ошибка здесь приключиться должна;

      можно создать список ошибок, каждой присвоить собственный
      номер, и при возникновении ошибки искать ее в списке ( так
      делает много фортов, включая СПФ ). Список ошибок можно хранить
      в файле. Но недостатком такого подхода является необходимость
      отслеживания ошибок по их номерам - то есть та же проблема,
      что и во втором случае.

      Я предлагаю поступить иначе. Я создаю список сообщений (в данном
случае используется отдельный файл, но можно и в памяти его хранить.
Сами сообщения об ошибках я пишу в тексте определения: Error" a message".
Далее сообщение ищется в списке, если такого сообщения еще не было, то
новое сообщение добавляется, ему присваивается номер, номер компилируется
в текст сообщения. При необходимости вывести сообщение, оно ищется в
списке по своему номеру, и выдается куда следует. Если, вдруг, список
будет утерян, то куда надо будут выводиться номера ошибок, как это
сделано в СПФ. Если нужно будет изменить старое сообщение на новое -
достаточно изменить старое сообщение в файле сообщений.


      Использую медленную методику - каждый раз все сообщения
перечитываются из файла заново. Но я рассчитываю, что сообщений будет
не больше нескольких сотен, если будет нужда в обработке большего
кол-ва сообщений, то можно будет создать уже реальную базу данных
сообщений. Но это лишняя морока, по крайней мере мне пока ненужная.
