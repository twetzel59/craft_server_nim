import std / [ asyncnet ]

type
  Client* = ref object
    ipStr: string
    socket: AsyncSocket
    connected: bool
  
  ClientId* = distinct Natural

  IdGenerator* = object
    current: ClientId

func newClient*(accepted: tuple[address: string; client: AsyncSocket]): Client =
  Client(
    ipStr: accepted[0],
    socket: accepted[1],
    connected: true
  )

func ipStr*(cl: Client): string =
  cl.ipStr

func socket*(cl: Client): AsyncSocket =
  cl.socket

proc sendInitial*(cl: Client) =
  echo "Should Send Handshake"

proc `$`*(a: ClientId): string {.borrow.}
proc `==`*(a, b: ClientId): bool {.borrow.}

func nextId*(gen: var IdGenerator): ClientId =
  result = gen.current
  inc gen.current
