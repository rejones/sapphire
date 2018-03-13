#define N_MUTATORS 3

/* address */
#define INVALID 2

/* hash state */
mtype { UNHASHED, HASHED, MOVED }

/* phase */
#define INACTIVE   0
#define MARK_ALLOC 1
#define COPY       2
#define FLIP       3
#define RECLAIM     4

/* property */
ltl p_consistency  {
    [](hash == 0 -> [](hash == 0)) &&
    [](hash == 1 -> [](hash == 1))
}
ltl p_hash0 {
    [](hashState[0] == HASHED -> [](hash == INVALID || hash == 0))
}
ltl p_hash1 {
    [](hashState[1] == HASHED -> [](hash == INVALID || hash == 1))
}

mtype hashState[2];
byte hashcode[2];
bit forwarded[2];
bit busy[2];

bit currentFromSpace;

int g_phase;
bit m_phase_behind[N_MUTATORS];

/* hashcode that the mutator has ever seen */
int hash = INVALID;
/* a slot in the mutator's root */
int root[N_MUTATORS];

#define IS_UNHASHED(o)     (hashState[o] == UNHASHED)
#define IS_HASHED(o)       (hashState[o] == HASHED)
#define IN_GC_CYCLE()      ((m_phase_behind[id] && g_phase != MARK_ALLOC) || \
   			   (!m_phase_behind[id] && g_phase != INACTIVE))
#define IN_FROM_SPACE(o)   ((o) == currentFromSpace)
#define FWD(o) (1 - (o))

inline initObject(i) {
    hashState[i] = UNHASHED;
    hashcode[i] = INVALID;
    forwarded[i] = 0;
    busy[i] = 0;
}

inline getObjectHashCode(o, r) {
  int pseudo1;
  hashByAddress(o, pseudo1);
  if
  ::IS_HASHED(pseudo1) -> r = pseudo1
  ::else -> r = hashcode[pseudo1]
  fi
}

inline setHashed(o) {
  hashState[o] = HASHED;
}

inline metaLockObject(o, oo) {
  if
  ::!IN_GC_CYCLE() || !IN_FROM_SPACE(o) ->
    assert(0);  /* guarantee correctness of optimization */
    oo = o
  ::else -> 
    if
    ::forwarded[o] -> oo = FWD(o)
    ::atomic{(!forwarded[o] && busy[o] == 0) -> busy[o] = 1}; oo = o  /* CAS */
    fi
  fi
}

inline metaUnlockObject(o) {
  if
  ::!IN_GC_CYCLE() || !IN_FROM_SPACE(o) -> skip
  ::else -> busy[o] = 0
  fi
}

inline hashByAddress(o, r) {
  int pseudo;
  do
  ::if
    ::!IS_UNHASHED(o) -> r = o; break /* return */
    ::else -> skip
    fi;
    if
    ::!IN_GC_CYCLE() || !IN_FROM_SPACE(o) ->
      setHashed(o);
      r = o; break /* return */
    ::else -> skip
    fi;
    metaLockObject(o, pseudo);
    if
    ::IS_UNHASHED(pseudo) -> setHashed(pseudo)
    ::else -> skip
    fi;
    metaUnlockObject(pseudo);
    r = pseudo; break /* return */
  od
} 

inline advancePhase(newPhase) {
#if 0
atomic {
    g_phase = newPhase;
    i = 0;
    do
    ::(i == N_MUTATORS) -> break
    ::else -> m_phase_behind[i] = 1; i++
    od;
    i=0;
    do
    ::(i == N_MUTATORS) -> break
    ::(i < N_MUTATORS && !m_phase_behind[i]) -> i++
    od;
    i = 0
  }
#else
  atomic {
    g_phase = newPhase;
    i = 0;
    do
    ::(i == N_MUTATORS) -> break
    ::else -> m_phase_behind[i] = 1; i++
    od;
    i=0;
  };
  do
  ::atomic{
      i = 0;
      do
      ::(i == N_MUTATORS) -> i = 0; goto phase_changed
      ::(i < N_MUTATORS && !m_phase_behind[i]) -> i++
      ::(i < N_MUTATORS && m_phase_behind[i]) -> break
      od;
      i = 0
    }
  od
phase_changed:
#endif
}

inline collection()
{
  int i = 0;
  int o = currentFromSpace;  /* the live object */

  advancePhase(MARK_ALLOC);
  atomic{!busy[o] -> busy[o] = 1};  /* assume CAS succeeds */
  forwarded[FWD(o)] = 0;
  if
  ::(hashState[o] == UNHASHED)-> hashState[FWD(o)] = UNHASHED
  ::(hashState[o] == HASHED) ->  hashState[FWD(o)] = MOVED;
                                 hashcode[FWD(o)] = o
  ::(hashState[o] == MOVED) ->   hashState[FWD(o)] = MOVED;
                                 hashcode[FWD(o)] = hashcode[o]
  fi;
  forwarded[o] = 1;
  busy[o] = 0;

  advancePhase(COPY);

  advancePhase(FLIP);
  i = 0;
  do
  ::(i == N_MUTATORS) -> break
  ::else ->
    root[i] = FWD(root[i]); /* flip mutator's root */
    i = i + 1
  od;i = 0;

  advancePhase(RECLAIM);
  currentFromSpace = 1 - currentFromSpace;

  advancePhase(INACTIVE)
}

proctype collector()
{
  do
  ::collection()
  od
}

proctype mutator(byte id)
{
  int hc, rt;
  do
  ::m_phase_behind[id] -> m_phase_behind[id] = 0
  ::true -> rt = root[id];getObjectHashCode(rt, hc);hash = hc
  od
}

init
{
  byte i;

  atomic {
    i = 0;
    do
    ::(i < 2) -> initObject(i); i = i + 1
    ::else -> break
    od;

    currentFromSpace = 0;
    g_phase = INACTIVE;

    i = 0;
    do
    ::(i < N_MUTATORS) ->
      root[i] = 0;
      m_phase_behind[i] = 0;
      i = i + 1
    ::else -> break
    od
  }

  run collector();
  i = 0;
  do
  ::(i < N_MUTATORS) -> run mutator(i); i = i + 1
  ::else -> break
  od
}
