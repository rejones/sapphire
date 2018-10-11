PERIODIC TESTS

This directory contains the periodic test programs used in section 
13.5 Responsivesess of "Transactional Sapphire: Lessons in High Performance,
On-the-fly Garbage Collection", Tomoharu Ugawa, Carl G. Ritson and Richard
Jones, ACM TOPLAS 40(4), December 2018. http://kar.kent.ac.uk/67207/ 

The tests rely on the TestThread implementation in Sapphire.
See: jikesrvm/rvm/src/org/jikesrvm/scheduler/TestThread.java
I think it wouldn't be too hard to port to other versions/copies of Jikes.

The task is configured by command line parameters, e.g.
'-X:test:class=SmallTreeTask'
'-X:test:period=1000000'
'-X:test:prefix=-^-'
'-X:test:priority=0'
'-X:test:busy_wait=true'

At the end of a run, the stats are printed directly from the binary buffer:
-^- === Test Thread Stats
-^- 0x00000001 0x000e0000 0x14e1717c60d5d118 0x14e1717c60e45e51

So you need a program/script to decode them; the simple format is
described in the TestThread.java:
/**
* Record layout:
* Word header
* Word flags
* long start
* long end
*/
Also look at the code for storeTestRecord for the contents of flags for tests.
