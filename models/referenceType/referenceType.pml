/* #define DELETION_BARRIER 1 */

#define N 3  /* objects */
#define M 1  /* mutators */

mtype {NORMAL, TRACING, CLEANING, REPEAT,  /* refState */
       WHITE, GRAY, BLACK, RECLAIMED       /* mark */
}

int root[M];       /* mutator's root */
int dirty;         /* is root dirty? valid only with insertion barrier */
byte reference[N]; /* true -> not cleared, false -> null */
mtype mark[N];     /* color of object i */
mtype refState;

/* handshake */
bool req[M];       /* handshake request */

/* check */
int getReferent_arg = -1; /* to advatise the return value of get() */
int getReferent_ret = -1; /* to advatise the return value of get() */
bool in_gc = false;       /* is in GC? */

#define RETNULL(i) (getReferent_arg == i && getReferent_ret == -1)
#define RETNONNULL(i) (getReferent_arg == i && getReferent_ret != -1)

/* termination: GC eventually terminates */
ltl p_termination { [](in_gc -> <>!in_gc) }

/* safety: a mutator will never see a reclaimed object */
ltl p_safety0 { [](reference[0] -> (mark[0] != RECLAIMED)) }
ltl p_safety1 { [](reference[1] -> (mark[1] != RECLAIMED)) }
ltl p_safety2 { [](reference[2] -> (mark[2] != RECLAIMED)) }

/* consistency: Once a get() method on a reference object returns
 *              null, a mutator will never see the object that
 *              the referent of the reference object.
 * note: test only the root of mutator 0 since mutators are symmetric
 */
ltl p_consistency0 { [](RETNULL(0) -> !<> (root[0] == 0)) }
ltl p_consistency1 { [](RETNULL(1) -> !<> (root[0] == 1)) }
ltl p_consistency2 { [](RETNULL(2) -> !<> (root[0] == 2)) }

/* monotonicity: Once a get() returns null, it never returns non-null */
ltl p_monotonicity0 { [](RETNULL(0) -> !<> RETNONNULL(0)) }
ltl p_monotonicity1 { [](RETNULL(1) -> !<> RETNONNULL(1)) }
ltl p_monotonicity2 { [](RETNULL(2) -> !<> RETNONNULL(2)) }

#define CAS(var,old,new,success,fail) \
  if \
  :: atomic {(var == old) -> var = new}; success \
  :: else -> fail \
  fi

#define REFERENT(i) (i)

inline setup()
{
  i = 0;
  do
    :: (i < M) ->
       root[i] = -1;
       i = i + 1
    :: else -> break
  od;
  i = 0;
  do
    :: (i < N) ->
       mark[i] = WHITE;
       reference[i] = true;
       i = i + 1
    :: else -> break
  od;
  refState = NORMAL;
}

inline transitiveClosure()
{
  printf("transitiveClosure\n");
  i = 0;
  do
    :: (i < N) ->
       if
         :: (i < N - 1 && mark[i] == GRAY) ->
            if
              :: (mark[i + 1] == WHITE) ->
                 mark[i + 1] = GRAY
              :: else -> skip
            fi;
            mark[i] = BLACK
         :: (i == N - 1 && mark[i] == GRAY) ->
            mark[i] = BLACK
         :: else -> skip
       fi;
       i = i + 1
    :: else -> break
  od
}

inline scanRoot()
{
  printf("scanRoot\n");
  i = 0;
  dirty = false;
  do
    :: (i < M) ->
       r = root[i];
       if
         :: (r != -1 && mark[r] == WHITE) ->
            mark[r] = GRAY;
#ifndef DELETION_BARRIER
            dirty = true;
#endif
         :: else -> skip
       fi;
       i = i + 1
    :: else -> break
  od
}

inline clearReferences()
{
  printf("clearReference\n");
  i = 0;
  do
    :: (i < N) ->
       assert(mark[REFERENT(i)] != GRAY);
       if
         :: (mark[REFERENT(i)] != BLACK) ->
            reference[i] = false
         :: else -> skip
       fi;
       i = i + 1
    :: else -> break
  od
}

inline reclaim()
{
  printf("reclaim\n");
  i = 0;
  do
    :: (i < N) ->
       assert(mark[i] != GRAY);
       if
         :: (mark[i] == WHITE) ->
            mark[i] = RECLAIMED
         :: (mark[i] == BLACK) ->
            mark[i] = WHITE
         :: else -> skip
       fi;
       i = i + 1
    :: else -> break
  od
}

inline handshake()
{
  i = 0;
  do
    :: (i < M) ->
       req[i] = true;
       i = i + 1
    :: else -> break
  od;
  i = 0;
  do
    :: (i < M) ->
       (req[i] == false);
       i = i + 1
    :: else -> break
  od
}

#ifdef DELETION_BARRIER
proctype collector()
{
  int i, r;

endcollector:
  do
    :: in_gc = true;
       scanRoot();
       transitiveClosure();
       refState = TRACING;
       handshake();
       scanRoot();
       do
         :: refState = TRACING;
            handshake();
            transitiveClosure();
            if
              :: !dirty ->
                 CAS(refState, TRACING, CLEANING, break, skip);
              :: else -> skip
            fi
       od;
       clearReferences();
       assert(refState == CLEANING);
       refState = NORMAL;
       handshake();
       reclaim();
       in_gc = false
  od
}
#else
proctype collector()
{
  int i, r;

endcollector:
  do
    :: in_gc = true;
       scanRoot();
       transitiveClosure();
       do
         :: refState = TRACING;
            handshake();
            transitiveClosure();
            scanRoot();
            if
              :: !dirty ->
                 CAS(refState, TRACING, CLEANING, break, skip);
              :: else -> skip
            fi
       od;
       clearReferences();
       assert(refState == CLEANING);
       refState = NORMAL;
       handshake();
       reclaim();
       in_gc = false
  od
}
#endif

inline getReferent(i, ref)
{
  do
    :: (refState == NORMAL) ->
       if
         :: (reference[i] == true) ->
            ref = REFERENT(i)
         :: else ->
            ref = -1
       fi;
       break
    :: (refState == REPEAT) ->
#ifdef DELETION_BARRIER
       if
         :: (reference[i] == true) ->
            if
              :: (mark[REFERENT(i)] == WHITE) ->
                 mark[REFERENT(i)] = GRAY;
              :: else -> skip
            fi;
            ref = REFERENT(i);
         :: else ->
            ref = -1;
       fi;
       break
#else
       if
         :: (reference[i] == true) ->
            ref = REFERENT(i)
         :: else ->
            ref = -1
       fi;
       break
#endif
    :: (refState == TRACING) ->
       if
         :: (reference[i] == true) ->
            if
              :: (mark[REFERENT(i)] == WHITE) ->
                 CAS(refState, TRACING, REPEAT, skip, skip)
                 /* continue */
              :: else ->
                 ref = REFERENT(i);
                 break
            fi
         :: else ->
            ref = -1;
            break
       fi
    :: (refState == CLEANING) ->
       if
         :: (reference[i] == true) ->
            assert(mark[REFERENT(i)] != RECLAIMED);
            assert(mark[REFERENT(i)] != GRAY);
            if
              :: (mark[REFERENT(i)] == WHITE) ->
                 ref = -1
              :: else ->
                 ref = REFERENT(i)
            fi;
         :: else ->
            ref = -1
       fi;
       break
  od;
  printf("getReferent(%d) => %d\n", i, ref);
  d_step{
    getReferent_arg = i;
    getReferent_ret = ref
  };
}

proctype mutator(int id)
{
  int ref;
  int i;

  i = 0;
endmutator:
  do
    :: (req[id] == true) ->
       req[id] = false
    :: else ->
       if
         :: ref = -1;
            getReferent(i, ref);
            root[id] = ref
         :: root[id] = -1
         :: (root[id] != -1 && root[id] < N - 1) ->
            root[id] = root[id] + 1
         :: (i < N - 1) -> i = i + 1
         :: (i == N - 1) -> i = 0
       fi
  od
}

init {
  int i;
  atomic {
    setup();
    i = 0;
    do
      :: (i < M) ->
         run mutator(i);
         i = i + 1
      :: else -> break
    od;
    run collector();
  }
}
