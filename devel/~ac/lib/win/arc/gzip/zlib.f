( gzip [ addr u -- addr2 u2 ] - сжать переданный буфер
  в формате GZIP [RFC1952].
  Для исключения собственно файловых операций 
  применена ручная конвертация формата zlib->gzip.
  При записи полученного буфера в файл получается обычный
  .gz файл [без указания имени и даты исходного файла,
  т.к. сжимается не файл, а буфер]
  При записи в сокет удовлетворяет спецификации
  Content-Encoding: gzip, т.е. непосредственно может
  вставляться в тело http-ответа.

  gzip_write [ addr u -- ] - для использования вместо 
  WRITE-FILE, WriteSocket или TYPE
  - сжимает переданный буфер и записывает в формате GZIP [RFC1952]
  При записи используется слово VECT gzip_write_function,
  которое по умолчанию выполняет TYPE.
  gzip_write экономнее, чем gzip[] за счет исключения
  операций копирования в памяти и выделения дополнительной памяти.

  zlib_compress и zlib_uncompress [ addr u -- addr2 u2 ]
  используют формат zlib deflate [RFC1950]

  [Добавление 01.10.2007] dll удален с CVS. Если не можете найти,
  где скачать, то можно отсюда: http://www.forth.org.ru/ext/zlib.dll [версия 1.1.4 от 2003г]
  или http://www.zlib.net/ [текущая 1.2.3]
)

WINAPI: compress   zlib1.dll
WINAPI: uncompress zlib1.dll
WINAPI: crc32      zlib1.dll
WINAPI: adler32    zlib1.dll
WINAPI: zlibVersion zlib1.dll

\ int compress (Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen); 
\ Compresses the source buffer into the destination buffer. 
\ sourceLen is the byte length of the source buffer. Upon entry, 
\ destLen is the total size of the destination buffer, which must 
\ be at least 0.1% larger than sourceLen plus 12 bytes. Upon exit, 
\ destLen is the actual size of the compressed buffer.
\ This function can be used to compress a whole file at once if the 
\ input file is mmap'ed.
\ compress returns Z_OK if success, Z_MEM_ERROR if there was not 
\ enough memory, Z_BUF_ERROR if there was not enough room in the 
\ output buffer.

 0 CONSTANT Z_OK
-4 CONSTANT Z_MEM_ERROR
-5 CONSTANT Z_BUF_ERROR

: zlib_compress ( addr u -- addr2 u2 )
  SWAP OVER 110 100 */ 12 +
  DUP ALLOCATE THROW DUP >R SWAP >R
  RP@ SWAP
  compress >R 2DROP 2DROP R>
  Z_OK = IF 2R> ELSE 2R> DROP FREE THROW S" " THEN
;
: zlib_uncompress ( addr u -- addr2 u2 )
  SWAP OVER 10000 100 */
  DUP ALLOCATE THROW DUP >R SWAP >R
  RP@ SWAP
  uncompress >R 2DROP 2DROP R>
  Z_OK = IF 2R> ELSE 2R> DROP FREE THROW S" " THEN
;
: CRC32 ( addr u -- crc32 )
  SWAP 0 crc32 >R DROP 2DROP R> \ crc32
;
: ADLER32 ( addr u -- crc32 )
  SWAP 1 adler32 >R DROP 2DROP R> \ adler32 в zlib-формате записывается в big endian
;
CREATE gzip_header
0x1F C, 0x8B C, \ gzip_id
08 C,           \ compression=deflate
0 C,            \ flags 1=text, 2=hcrc, 4=extra, 8=fname, 16=comment
0 ,             \ unix mtime
0 C,            \ xfl
0 C,            \ OS: win=0, unix=3
HERE gzip_header - CONSTANT /gzip_header

VECT gzip_write_function ' TYPE TO gzip_write_function

( двухбайтовый заголовок zlib-формата:
section 2.2 in rfc1950:
CMF: 0x78
bits 0 to 3: compression method 8 = deflate
bits 4 to 7: window size 32kB
FLG: 0x9C
bits 0 to 4: check bits, 0x789C = 30876, which is a multiple of 31
bit 5: no preset dictionary
bits 6 to 7: compression level 2, irrelevant for decompression 
)

: zlib_data ( addr u -- addr2 u2 ) \ zlib specification [RFC-1950], deflate specification [RFC-1951]
\ срезать zlib/deflate-обёртку c результата работы zlib_compress
\ для преобразования в gzip-формат
\ либо для выдачи http-клиенту с заголовком Content-Encoding: deflate (все браузеры кроме IE умеют сами отрезать 789C :)
  6 - SWAP 2+ SWAP \ отрезаем 2 байта в начале
                   \ 0x78 - Compression method/flags code
                   \ 0x9C - Additional flags/check bits
                   \ и 4 байта в конце (Adler-32 checksum)
;
: gzip
  DUP >R
  2DUP CRC32 >R
  zlib_compress OVER >R \ потом освободим
  zlib_data             \ сжатый блок
  DUP /gzip_header + 2 CELLS + DUP >R \ размер полного gzip
  ALLOCATE THROW >R
  gzip_header R@ /gzip_header CMOVE
  R@ /gzip_header + SWAP CMOVE
  R> R> R> FREE THROW
  2DUP + R> OVER 8 - ! R> SWAP 4 - !
;
: gzip_write ( addr u -- )
  DUP >R
  2DUP CRC32 >R
  gzip_header /gzip_header gzip_write_function
  zlib_compress
  zlib_data
  gzip_write_function
  RP@ 4 gzip_write_function \ crc
  RDROP RP@ 4 gzip_write_function \ size
  RDROP
;

(
REQUIRE STR@                ~ac/lib/str2.f
: TEST
  H-STDOUT >R
  S" test.gz" R/W CREATE-FILE THROW TO H-STDOUT
  S" rfc2616.txt" FILE gzip TYPE \ gzip_write
  H-STDOUT CLOSE-FILE THROW
  R> TO H-STDOUT
; TEST
)
