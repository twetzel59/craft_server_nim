import
  asyncnet, options,
  vec

type
  ClientId* = distinct uint8

  Client* = object
    ip: string
    socket: Option[AsyncSocket]
    transform*: Pos3Rot2f

proc `==`*(a, b: ClientId): bool {.borrow.}
proc `<=`*(a, b: ClientId): bool {.borrow.}
proc `$`*(idx: ClientId): string {.borrow.}

proc ip*(cl: Client): string = 
  cl.ip

proc socket*(cl: Client): Option[AsyncSocket] =
  cl.socket

proc initClient*(ip: string not nil, socket: AsyncSocket): Client =
  result = Client(
    ip: ip,
    socket: some(socket),
  )

proc closeSocketMarkDead*(cl: var Client) {.raises: [].} =
  try:
    if cl.socket.isSome:
      cl.socket.get().close()
      cl.socket = none(AsyncSocket)
  except:
    discard

proc alive*(cl: Client): bool =
  cl.socket.isSome

template withSocketIfAlive*(cl: Client, body: untyped): untyped =
  if cl.alive:
    let socket {.inject.} = cl.socket.unsafeGet()
    body
