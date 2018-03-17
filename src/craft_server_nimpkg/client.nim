import asyncnet, options

type
  ClientId* = distinct Natural

  Client* = object
    ip: string
    socket: Option[AsyncSocket]

proc `==`*(a, b: ClientId): bool {.borrow.}
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

template withSocketIfAlive*(cl: Client, body: untyped): untyped {.dirty.} =
  if cl.alive:
    let socket = cl.socket.unsafeGet()
    body
