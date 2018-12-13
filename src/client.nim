import std / [ asyncnet, options ], entity, packet

type
  Client* = ref object
    ipStr: string
    socket: AsyncSocket
    connected*: bool
    player*: Player
  
  ClientId* = distinct uint16

  IdGenerator* = object {.requiresInit.}
    available: set[ClientId]

func newClient*(accepted: tuple[address: string; client: AsyncSocket]): Client =
  Client(
    ipStr: accepted[0],
    socket: accepted[1],
    connected: true,
    player: initPlayer(),
  )

func ipStr*(cl: Client): string =
  cl.ipStr

func socket*(cl: Client): AsyncSocket =
  cl.socket

proc sendInitial*(cl: Client) =
  echo "Should Send Handshake"

proc `$`*(a: ClientId): string {.borrow.}
proc `==`*(a, b: ClientId): bool {.borrow.}

func initIdGenerator*(): IdGenerator =
  # At the beginning of the server's life
  # all IDs are available.
  var available: set[ClientId]

  for i in 0'u16..high(uint16):
    incl available, ClientId i
  
  IdGenerator(available: available)

func nextId*(gen: var IdGenerator): Option[ClientId] =
  for id in gen.available:
    excl gen.available, id
    return some(id)
  
  none(ClientId)

func releaseId*(gen: var IdGenerator, id: ClientId) =
  incl gen.available, id

#iterator items*(gen: IdGenerator): ClientId =
#  for i in gen.available:
#    yield i
