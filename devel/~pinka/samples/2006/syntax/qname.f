\ 10.Feb.2006 Fri 20:05
\ здесь qname -- quoted name

REQUIRE enqueueNOTFOUND ~pinka/samples/2006/core/trans/nf-ext.f 

REQUIRE AsQName ~pinka/samples/2006/syntax/qname.core.f

' AsQName preemptNOTFOUND

\ Упрощение, вместо записи S" name" теперь можно записать `name
\ (отличать от 'name ! )
