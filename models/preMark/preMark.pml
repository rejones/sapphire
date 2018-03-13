/* #define TYPE_II 1 */

/*
Each mutator has two local variables: root0 and root1.
Initially, there is a single object in the heap, which
is refered to from root0 of every mutator.  root1 of
every mutator is NULL.

Each mutator performs the following atomic actions repeatedly:
- read:     a = b.slot
- write:    a.slot = b
- allocate: a = new object;
- catch up to the global phase

Limitation:
At most N_OBJECTS can be allocated.
Every heap object has a single slot, `slot'.

Modelling:

Each object has two properties: colour and the value of `slot',
each of which is stored an array colour and slot, respectively.
These are indexed by the object ID, which is model of address.
Object's colour is one of the standard tri-colours and NOT_ALLOCATED,
indicating that the object has not been allocated.

We made read and write operations are atomic because we assumed data-race
free programs.  Though our modelling imposed a stronger restriction than
the DRF requirement.
*/


#define N_MUTATORS 2
#define N_OBJECTS  3

#define NULL 0

mtype {
  NOGC_PHASE, PREMARK1_PHASE, PREMARK2_PHASE, MARK_PHASE,
  WHITE, GREY, BLACK, NOT_ALLOCATED
};

mtype g_phase = NOGC_PHASE;
mtype m_phase[N_MUTATORS];

mtype colour[N_OBJECTS];
int   slot[N_OBJECTS];
int   free_ptr = 2;
#define IS_HEAP_FULL()  (free_ptr > N_OBJECTS)

#define SLOT(x)   slot[x-1]
#define COLOUR(x) colour[x-1]

inline checkAndEnqueue(q) {
  if
    ::(m_phase[id] != NOGC_PHASE &&
       q != NULL && COLOUR(q) == WHITE) -> COLOUR(q) = GREY
    ::else -> skip
  fi
}

inline write(p, q) {
  printf("write %d <- %d\n", p, q);
  SLOT(p) = q;
  checkAndEnqueue(q);
}

inline read(p, retval) {
  printf("read %d -> %d\n", p, SLOT(p));
  retval = SLOT(p);
}

inline alloc(retval) {
  retval = free_ptr;
  free_ptr = free_ptr + 1;
  if
    ::(m_phase[id] == PREMARK2_PHASE || m_phase[id] == MARK_PHASE) ->
      COLOUR(retval) = BLACK;
    ::else ->
      COLOUR(retval) = WHITE;
  fi;
  SLOT(retval) = NULL;
  printf("alloc -> %d\n", retval);
}

proctype mutator(int id) {
  int root0 = 1;
  int root1 = NULL;

end_mutator:
  do
    /* handshake */
    ::atomic{
      (g_phase != m_phase[id]) -> m_phase[id] = g_phase;
      printf("mut phase -> %e\n", g_phase);
    };
    ::atomic{(root0 != NULL) -> read(root0, root0)}
    ::atomic{(root1 != NULL) -> read(root1, root1)}
    ::atomic{(root0 != NULL) -> read(root0, root1)}
    ::atomic{(root1 != NULL) -> read(root1, root0)}
    ::atomic{(root0 != NULL) -> write(root0, root0)}
    ::atomic{(root1 != NULL) -> write(root1, root1)}
    ::atomic{(root0 != NULL) -> write(root0, root1)}
    ::atomic{(root1 != NULL) -> write(root1, root0)}
    ::atomic{!IS_HEAP_FULL() -> alloc(root0)}
    ::atomic{!IS_HEAP_FULL() -> alloc(root1)}
  od
}

inline waitForMutators() {
  int i = 0;
  do
    ::(i < N_MUTATORS) ->
      (m_phase[i] == g_phase) -> i++
    ::else -> break
  od
}

proctype collector() {
  atomic {
#ifdef TYPE_II
  g_phase = PREMARK1_PHASE;
  waitForMutators();
#endif /* TYPE_II */
  g_phase = PREMARK2_PHASE;
  waitForMutators();
  g_phase = MARK_PHASE;
  waitForMutators();
  }
}

proctype observer() {
  int i = 1;
  atomic {
    do
    ::(i <= N_OBJECTS) ->
      assert(COLOUR(i) != BLACK || SLOT(i) == NULL || COLOUR(SLOT(i)) != WHITE);
      i = i + 1
    ::else -> break
    od
  }
}

init {
  int i;
  COLOUR(1) = WHITE;
  SLOT(1) = NULL;
  g_phase = NOGC_PHASE;
  m_phase[0] = NOGC_PHASE;
  m_phase[1] = NOGC_PHASE;

  i = 2;
  do
  ::(i <= N_OBJECTS) ->
    COLOUR(i) = NOT_ALLOCATED;
    SLOT(i) = NULL;
    i = i + 1
  ::else -> break
  od;

  run observer();
  run mutator(0);
  run mutator(1);
  run collector();
}