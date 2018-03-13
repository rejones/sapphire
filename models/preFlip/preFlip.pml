/* #define TYPE_II 1 */

/*

There are three objects in the heap; two objects in
the replicating space and one in the non-replicating
space.  

Each mutator has two local variables: root0 and root1.
Initially, there is a single object in the heap, which
is refered to from root0 of every mutator.  root1 of
every mutator is NULL.

*/

#define N_MUTATORS 2
#define N_OBJECTS  2
#define N_NONREPL  1

#define N_ADDRS    (N_OBJECTS * 2 + N_NONREPL)

mtype {
  /* phase */
   COPY_PHASE, PREFLIP1_PHASE, PREFLIP2_PHASE, FLIP_PHASE
}

mtype g_phase = COPY_PHASE;
mtype m_phase[N_MUTATORS];

/* address
 * 0, 1 : from
 * 2, 3 : to
 * 4    : no_repl
 */

int mem[N_ADDRS];

#define FROM_SPACE_OBJECT(i) mem[i]
#define TO_SPACE_OBJECT(i)   mem[N_OBJECTS + i]
#define NON_REPL_OBJECT(i)   mem[2 * N_OBJECTS + i]

#define IN_FROM_SPACE(x) (0 <= (x) && (x) < N_OBJECTS)
#define IN_TO_SPACE(x)   (N_OBJECTS <= (x) && (x) < 2 * N_OBJECTS)
#define FORWARD(x)       if ::IN_FROM_SPACE(x) -> x = x + N_OBJECTS \
                            ::IN_TO_SPACE(x)   -> x = x - N_OBJECTS \
			    ::else -> skip fi

inline init_heap() {
  atomic {
    int i, j;
    i = 0;
    do
      ::(i < N_OBJECTS) ->
        j = 0;
	do
          ::(j < N_OBJECTS) ->
	    FROM_SPACE_OBJECT(i) = j;
	    TO_SPACE_OBJECT(i) = j;
	    FORWARD(TO_SPACE_OBJECT(i));
	    break
	  ::(j < N_OBJECTS) -> j = j + 1
	  ::else            ->
	    FROM_SPACE_OBJECT(i) = 2 * N_OBJECTS;
	    TO_SPACE_OBJECT(i) = 2 * N_OBJECTS;
	    break
	od;
        i = i + 1
      ::else -> break
    od;
    do
    ::(j < N_OBJECTS) ->
      NON_REPL_OBJECT(0) = FROM_SPACE_OBJECT(j);
      break
    ::(j < N_OBJECTS) -> j = j + 1
    ::else ->
      NON_REPL_OBJECT(0) = NON_REPL_OBJECT(0);
      break
    od;
    i = 0;
    do
    ::(i < N_ADDRS) ->
      printf("addr %d: %d\n", i, mem[i]);
      i = i + 1
    ::else ->
      break
    od;  
    i = 0;
    j = 0;
  }
}
  
inline read(obj, readval) {
  p = obj;
  readval = mem[obj];
  printf("read %d val %d\n", p, readval);
  p = 0;
}

inline raw_write(p, q) {
  mem[p] = q;
  printf("raw_write %d val %d\n", p, q);
}

inline write_copy(p, q) {
  raw_write(p, q);
  if
    ::(IN_FROM_SPACE(p)) ->
      FORWARD(p);
      if
        ::(IN_FROM_SPACE(q)) -> FORWARD(q); raw_write(p, q)
	::else ->               raw_write(p, q)
      fi
    ::else -> skip
  fi
}

inline write_preflip(p, q) {
  if
    ::(IN_FROM_SPACE(q) && IN_TO_SPACE(p)) -> FORWARD(q)
    ::else -> skip
  fi;
  raw_write(p, q);
  if
    ::(IN_FROM_SPACE(p) || IN_TO_SPACE(p)) ->
      FORWARD(p);
      if
        ::(IN_FROM_SPACE(q) || (IN_TO_SPACE(q) && IN_FROM_SPACE(p))) ->
	  FORWARD(q);
	  raw_write(p, q)
	::else ->
	  raw_write(p, q);
      fi
    ::else -> skip
  fi
}

inline write_flip(p, q) {
  if
    ::(IN_FROM_SPACE(q)) -> FORWARD(q)
    ::else -> skip
  fi;
  raw_write(p, q);
  if
    ::(IN_FROM_SPACE(p) || IN_TO_SPACE(p)) ->
      FORWARD(p);
      raw_write(p, q);
    ::else -> skip
  fi
}

inline write(obj, val) {
  printf("write %d val %d\n", obj, val);
  p = obj;
  q = val;
  if
    :: (m_phase[id] == COPY_PHASE) -> write_copy(p, q);
    :: (m_phase[id] == PREFLIP1_PHASE) -> write_preflip(p, q);
    :: else -> write_flip(p, q);
  fi;
  p = 0; q = 0
}

inline normalise() {
  if
  ::(root0 > root1) ->
    printf("normalise: root0(%d) <-> root1(%d)\n", root0, root1);
    tmp = root0;
    root0 = root1;
    root1 = tmp
  ::else -> skip
  fi
}

proctype mutator(int id) {
  int root0 = FROM_SPACE_OBJECT(0);
  int root1 = FROM_SPACE_OBJECT(0);
  int tmp, p, q;

end_mutator:
  do
    /* handshake */ 
    ::atomic{(g_phase != m_phase[id]) -> m_phase[id] = g_phase; printf("new phase %e\n", m_phase[id]);}
    ::atomic{read(root0, root0);normalise()}
    ::atomic{read(root0, root1);normalise()}
    ::atomic{read(root1, root0);normalise()}
    ::atomic{read(root1, root1);normalise()}
    ::atomic{write(root0, root0)}
    ::atomic{write(root0, root1)}
    ::atomic{write(root1, root0)}
    ::atomic{write(root1, root1)}
  od
}

inline waitForMutators() {
  int i = 0;
  do
    :: (i < N_MUTATORS) ->
       (m_phase[i] == g_phase) -> i++;
    :: else -> break
  od;
}

proctype collector() {
  atomic{
#ifdef TYPE_II
    g_phase = PREFLIP1_PHASE;
    waitForMutators();
#endif /* TYPE_II */
    g_phase = PREFLIP2_PHASE;
    waitForMutators();
    g_phase = FLIP_PHASE;
    waitForMutators();
  }  
}

proctype observer() {
   atomic {
     int i = 0;
     do
     ::(i < N_OBJECTS) ->
       assert(!IN_FROM_SPACE(TO_SPACE_OBJECT(i)));
       i = i + 1
     ::else -> break
     od
   }
}

init {
    init_heap();
    g_phase = COPY_PHASE;
    m_phase[0] = COPY_PHASE;
    m_phase[1] = COPY_PHASE;
    run observer();
    run mutator(0);
    run mutator(1);
    run collector();
}
