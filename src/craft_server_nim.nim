import asyncdispatch, asyncnet

const
  craftPort = Port(4080)

type
  Client = ref object
    ipStr: string
    socket: AsyncSocket
    id: int
    connected: bool

  Server = ref object
    socket: AsyncSocket
    clients: seq[Client]

func newClient(accepted: tuple[address: string, client: AsyncSocket]; id: int): Client =
  Client(
    ipStr: accepted[0],
    socket: accepted[1],
    id: id,
    connected: true
  )

func newServer(servSocket: AsyncSocket): Server =
  Server(socket: servSocket)

proc clientLoop(client: Client) {.async.} =
  while true:
    let line = await recvLine client.socket

    if len(line) == 0:
      # Client disconnected.
      echo "Disconnecting: ", client.ipStr
      return

proc servLoop(serv: Server) {.async.} =
  bindAddr serv.socket, craftPort
  listen serv.socket

  while true:
    let accepted = await acceptAddr serv.socket
    echo "Connecting: ", accepted[0]

    let client = newClient(accepted, len serv.clients)
    #add serv.clients, client

    asyncCheck clientLoop(client)

proc main() =
  let serv = newServer newAsyncSocket()
  waitFor servLoop serv

when isMainModule:
  main()
