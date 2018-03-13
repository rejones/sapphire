#define N_MUTATORS 3

/* flag */
#define FALSE 0
#define TRUE 1

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

int g_phase;

/* property */
ltl p_consistency {
   [](hash[0] == INVALID ->
     []((hash[0] == 0 -> [](hash[0] == 0 && hash[1] != 1)) &&
        (hash[0] == 1 -> [](hash[0] == 1 && hash[1] != 0)))) }

mtype hashState[2];
byte hashcode[2];
bit forwarded[2];
byte replica[2];
bit busy[2];

bit fromSpace;

bit  hsReq[N_MUTATORS];
byte hsAck;

#define IS_HASHED(o) (hashState[o] == HASHED || hashState[o] == MOVED)
#define WILL_NOT_MOVE(o) (o != fromSpace)
#define HAS_MOVED(o) (forwarded[o] == TRUE)

inline initObject(i)
{
    hashState[i] = UNHASHED;
    hashcode[i] = INVALID;
    forwarded[i] = FALSE;
    replica[i] = INVALID;
    busy[i] = FALSE;
}

#define getForwardingPointer(o)  replica[o]

inline setHashedAtomic(o)
{
/*
  atomic {
  if
  ::(hashState[o] == UNHASHED) -> hashState[o] = HASHED;
  ::else -> skip
  fi
  }
*/
  hashState[o] = HASHED;
}

inline markBusyAtomic(o)
{
  atomic {
    (busy[o] == FALSE) -> busy[o] = TRUE
  }
}

inline clearBusy(o)
{
  busy[o] = FALSE
}

inline getObjectHashCode(o, r)
{
  bit oo;

  hashByAddress(o);
  printf("oo = %d %e\n", oo, hashState[oo]);
  assert(hashState[oo] == HASHED || hashState[oo] == MOVED);
  if
    ::(hashState[oo] == HASHED) -> r = oo;
    ::(hashState[oo] == MOVED) ->
      atomic {
        assert(hashcode[oo] != INVALID);
        r = hashcode[oo];
     }
  fi
}

inline hashByAddress(o)
{
  do
  ::
    if
    ::IS_HASHED(o) -> oo = o; break
    ::else -> skip
    fi;

    if
    ::WILL_NOT_MOVE(o) ->
      setHashedAtomic(o);
      oo = o;
      break
    ::else -> skip
    fi;

    if
    ::HAS_MOVED(o) ->
      if
      ::IS_HASHED(o) -> oo = o; break
      ::else ->
	assert(forwarded[o] == TRUE);
        oo = replica[o];
        setHashedAtomic(oo);
        break
      fi;
    ::else -> skip
    fi;

    markBusyAtomic(o);
    if
    ::HAS_MOVED(o) -> skip
    ::else ->
      setHashedAtomic(o);
      oo = o;
      clearBusy(o);
      break;
    fi;
    clearBusy(o);

    if
    ::IS_HASHED(o) -> oo = o; break
    ::else -> skip
    fi;
    
    oo = getForwardingPointer(o);
    setHashedAtomic(oo);
    break;
  od
}

inline startHandshake()
{
  atomic{
  i = 0;
  hsAck = 0;
  do
  ::(i == N_MUTATORS) -> break
  ::else -> hsReq[i] = TRUE; i = i + 1
  od
  };
  (hsAck == N_MUTATORS);
  hsAck = 0;
}

/* hashcode that the mutator has ever seen */
int hash[N_MUTATORS];
/* a slot in the mutator's root */
int root[N_MUTATORS];

inline collection()
{
  int i = 0;
  /* initialise to-space */
  /*  atomic { initObject(1 - fromSpace) } */

  g_phase = MARK_ALLOC;
  startHandshake(); 

  forwarded[1 - fromSpace] = FALSE;
  markBusyAtomic(fromSpace);
  if
  ::(hashState[fromSpace] == UNHASHED)->
    hashState[1 - fromSpace] = UNHASHED;
  ::(hashState[fromSpace] == HASHED) ->
    hashState[1 - fromSpace] = MOVED;
    hashcode[1 - fromSpace] = fromSpace;
  ::(hashState[fromSpace] == MOVED) ->
    hashState[1 - fromSpace] = MOVED;
    hashcode[1 - fromSpace] = hashcode[fromSpace];
  fi;
  replica[fromSpace] = 1 - fromSpace;
  forwarded[fromSpace] = TRUE;
  clearBusy(fromSpace);

  g_phase = COPY; 
  startHandshake();

  g_phase = FLIP;
  startHandshake();
  i = 0;
  do
  ::(i < N_MUTATORS) ->
    root[i] = 1 - fromSpace; /* flip mutator's root */
    i = i + 1
  ::else -> break
  od;
  i = 0;

  g_phase = RECLAIM;
  startHandshake();

  fromSpace = 1 - fromSpace;
  g_phase = INACTIVE;
  startHandshake();
}

proctype collector()
{
  do
  ::collection()
  od
}

#define safepoint() \
  (hsReq[id] == TRUE) -> \
      hsReq[id] = FALSE; \
      hsAck = hsAck + 1

proctype mutator(byte id)
{
  int hc, rt;
  do
  ::safepoint();
  ::rt = root[id];getObjectHashCode(rt, hc);hash[id] = hc;
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

    fromSpace = 0;
    hsAck = 0;
    g_phase = INACTIVE;

    i = 0;
    do
    ::(i < N_MUTATORS) ->
      hash[i] = INVALID;
      root[i] = 0;
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
