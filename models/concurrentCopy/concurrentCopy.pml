/*
 * - A single object that has a single two-word field.
 * - Address = {0, 1, 2, 3, 4}
 *   - 0 for null
 *   - 1, 2 for slots of the from-space object
 *   - 3, 4 for slots of the to-space copy
 * - A mutator repeatedly writes either (0, 1) or (1, 0) to the two-word
 *   slot.
 * - The collector copies word by word.
 */

/*
#define NO_FENCE 1
#define STM 1
#define REFERENCE 1
#define DOUBLE_WORD 1
*/

#if defined(REFERENCE) && defined(DOUBLE_WORD)
#error both REFERENCE and DOUBLE_WORD are defined. Reference should be a single word.
#endif

/* the heap */
#define NULL 0

#ifdef DOUBLE_WORD
#define N_WORDS   2
#else  /* !DOUBLE_WORD */
#define N_WORDS   1
#endif /* DOUBLE_WORD */

#define N_ADDRS   (N_WORDS*2)

// FROM_SPACE_ADDR: SlotOffset -> Address
#define FROM_SPACE_ADDR(i) ((i)+1)
#define TO_SPACE_ADDR(i)   ((i)+1+N_WORDS)

// address of an object = address of its first word
#define FROM_SPACE_OBJECT  FROM_SPACE_ADDR(0)
#define TO_SPACE_OBJECT    TO_SPACE_ADDR(0)

#define IN_FROM_SPACE(x)   (0 < (x) && (x) <= N_WORDS)
#define IN_TO_SPACE(x)     (N_WORDS < (x))

#define FORWARD(x) if ::IN_FROM_SPACE(x) -> x = x + N_WORDS \
                      ::IN_TO_SPACE(x)   -> x = x - N_WORDS \
                      ::else             -> skip \
                   fi

byte shared[N_ADDRS];

/* verification */
bool flipped;

/* memory architecture */
#define N_THREADS 2

/* store load forwarding */
/* local latest value */
byte mutator_local_memory[N_ADDRS], collector_local_memory[N_ADDRS];
/* # of write instructions waiting in the store buffer.
 *   > 0: read should load local latest value
 *   = 0: read should load from memory
 */
byte mutator_queue_count[N_ADDRS], collector_queue_count[N_ADDRS];

/*   store buffer: queue of (space * value) */
chan mutator_queue = [N_THREADS] of {byte, byte};
chan collector_queue = [N_THREADS] of {byte, byte};

/*   store buffer emulation */
#define COMMIT_WRITE(q, count) \
  (len(q) > 0) -> \
  q?a,v -> \
  printf("commit[%d] = %d\n", a, v); \
  shared[(a)-1] = v; \
  count[(a)-1]--

active proctype memory() {
  byte a, v;
endmem:
  do
    ::atomic{COMMIT_WRITE(mutator_queue, mutator_queue_count)}
    ::atomic{COMMIT_WRITE(collector_queue, collector_queue_count)}
  od
}

#define MUTATOR_FENCE \
atomic { \
  do \
    ::COMMIT_WRITE(mutator_queue, mutator_queue_count) \
    ::else -> break \
  od \
}

#define COLLECTOR_FENCE \
atomic { \
  do \
    ::COMMIT_WRITE(collector_queue, collector_queue_count) \
    ::else -> break \
  od \
}

#define MUTATOR_READ(a, v) \
atomic { \
  if \
    ::mutator_queue_count[(a)-1] == 0 -> v = shared[(a)-1] \
    ::else -> v = mutator_local_memory[(a)-1] \
  fi; \
  printf("mut read[%d] = %d\n", a, v); \
}

#define MUTATOR_WRITE(a, v) \
atomic { \
  mutator_queue!a,v; \
  printf("mut write[%d] = %d\n", a, v); \
  mutator_local_memory[(a)-1] = v; \
  mutator_queue_count[(a)-1]++; \
}

#define COLLECTOR_READ(a, v) \
atomic { \
  if \
    ::collector_queue_count[(a)-1] == 0 -> v = shared[(a)-1] \
    ::else -> v = collector_local_memory[(a)-1] \
  fi; \
  printf("col read[%d] = %d\n", a, v); \
}

#define COLLECTOR_WRITE(a, v) \
atomic { \
  collector_queue!a,v; \
  printf("col write[%d] = %d\n", a, v); \
  collector_local_memory[(a)-1] = v; \
  collector_queue_count[(a)-1]++; \
}


#if defined(REFERENCE)
proctype mutator() {
  byte x, r, a, v;

  do
    ::true ->
      if
      ::true -> x = NULL
      ::true -> x = FROM_SPACE_OBJECT
      fi;
      r = x;
      MUTATOR_WRITE(FROM_SPACE_ADDR(0), r);
      FORWARD(r);
      MUTATOR_WRITE(TO_SPACE_ADDR(0), r);
      r = 0;
    ::true ->
      if
      ::!flipped ->
        MUTATOR_READ(FROM_SPACE_ADDR(0),r);
        assert(x == r)
      ::else ->
        MUTATOR_READ(TO_SPACE_ADDR(0),r);
	assert(x != NULL || r == NULL);
	assert(!IN_FROM_SPACE(x) || (x + N_WORDS) == r);
	assert(!IN_TO_SPACE(x) || x == r);
      fi;
      r = 0;
  od
}
#elif defined(DOUBLE_WORD)
proctype mutator() {
  byte x, r0, r1, a, v;

  do
    ::true ->
      if
      ::true -> x = 0  // [0, 1]
      ::true -> x = 1  // [1, 0]
      fi;
      r0 = x;
      r1 = 1 - x;
      MUTATOR_WRITE(FROM_SPACE_ADDR(0), r0);
      MUTATOR_WRITE(FROM_SPACE_ADDR(1), r1);
      MUTATOR_WRITE(TO_SPACE_ADDR(0), r0);
      MUTATOR_WRITE(TO_SPACE_ADDR(1), r1);
      r0 = 0;
      r1 = 0;
    ::true ->
      if
      ::!flipped ->
        MUTATOR_READ(FROM_SPACE_ADDR(0),r0);
        MUTATOR_READ(FROM_SPACE_ADDR(1),r1);
      ::else ->
        MUTATOR_READ(TO_SPACE_ADDR(0),r0);
        MUTATOR_READ(TO_SPACE_ADDR(1),r1);
      fi;
      assert(r0 == x && r1 == 1 - x);
      r0 = 0;
      r1 = 0;
  od
}
#else
proctype mutator() {
  byte x, r, a, v;

  do
    ::true ->
      if
      ::true -> x = 0
      ::true -> x = 1
      fi;
      r = x;
      MUTATOR_WRITE(FROM_SPACE_ADDR(0), r);
      MUTATOR_WRITE(TO_SPACE_ADDR(0), r);
      r = 0;
    ::true ->
      if
      ::!flipped ->
        MUTATOR_READ(FROM_SPACE_ADDR(0),r)
      ::else ->
        MUTATOR_READ(TO_SPACE_ADDR(0),r)
      fi;
      assert(r == x);
      r = 0;
  od
}
#endif

proctype collector()
{
  byte currentValue, toValue, tmp, a, v, i;
  byte buf[N_WORDS];

  i = 0;
#ifdef STM
  do
    ::(i < N_WORDS) ->
       COLLECTOR_READ(FROM_SPACE_ADDR(i), toValue);
#ifdef REFERENCE
       buf[i] = toValue;
       FORWARD(toValue);
#endif /* REFERENCE */
       COLLECTOR_WRITE(TO_SPACE_ADDR(i), toValue);
       i++
    ::else -> i = 0; break
  od;

#ifndef NO_FENCE
       COLLECTOR_FENCE
#endif

  do
    ::(i < N_WORDS) ->
#ifdef REFERENCE
       COLLECTOR_READ(FROM_SPACE_ADDR(i), currentValue);
       if
         ::(currentValue != buf[i]) -> goto FAIL
	 ::else -> skip
       fi;
#else
       COLLECTOR_READ(FROM_SPACE_ADDR(i), currentValue);
       COLLECTOR_READ(TO_SPACE_ADDR(i), toValue);
       if
         ::(currentValue != toValue) -> goto FAIL
         ::else -> skip
       fi;
#endif /* !REFERENCE */
       i++
    ::else -> i = 0; break
  od;
  goto SUCCESS;
FAIL:
#endif /* STM */

  /* copy with CAS */
  do
    ::(i < N_WORDS) ->
       COLLECTOR_READ(TO_SPACE_ADDR(i), currentValue);
       COLLECTOR_READ(FROM_SPACE_ADDR(i), toValue);
#ifdef REFERENCE
       FORWARD(toValue);
#endif /* REFERENCE */
       if
	 ::(toValue == currentValue) -> i++
	 ::else ->
           atomic { /* CAS */
     	     COLLECTOR_FENCE;
	     COLLECTOR_READ(TO_SPACE_ADDR(i), tmp);
	     if
	       ::(currentValue == tmp) ->
	         COLLECTOR_WRITE(TO_SPACE_ADDR(i), toValue)
	       ::else -> i++
	     fi;
     	     COLLECTOR_FENCE;
	   }
       fi
    ::else -> i = 0; break 
  od;
SUCCESS:
  COLLECTOR_FENCE;
  flipped = true;
}

init
{
  int i;
  atomic {
    i = 0;
    do
    ::(i < N_WORDS) ->
      mutator_queue_count[i] = 0;
      mutator_queue_count[N_WORDS + i] = 0;
      collector_queue_count[i] = 0;
      collector_queue_count[N_WORDS + i] = 0;
      shared[i] = i;
      shared[N_WORDS + i] = 0;
      i = i + 1
    ::else -> break
    od;
    flipped = false;
    run collector();
    run mutator();
  }
}
