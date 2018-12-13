import
  std / [ asyncdispatch, asyncnet, options, tables ],
  client

const
  craftPort = Port(4080)

type
  Server = ref object
    socket: AsyncSocket
    clients: Table[ClientId, Client]
    idGen: IdGenerator

func newServer(servSocket: AsyncSocket): Server =
  Server(
    socket: servSocket,
    clients: initTable[ClientId, Client](),
    idGen: initIdGenerator(),
  )

proc clientLoop(cl: Client) {.async.} =
  sendInitial cl

  while true:
    let line = await recvLine cl.socket

    if len(line) == 0:
      # Client disconnected.
      echo "Disconnecting: ", cl.ipStr
      return
    #else:
    #  echo "Incoming [", cl.ipStr, "]: ", line 

proc serverLoop(se: Server) {.async.} =
  bindAddr se.socket, craftPort
  listen se.socket

  while true:
    let
      id = get nextId se.idGen # TODO: Handle exception. Full server??
      accepted = await acceptAddr se.socket
      client = newClient accepted
    
    echo "Connecting: ", accepted[0]

    se.clients[id] = client

    asyncCheck clientLoop(client)

proc main() =
  let se = newServer newAsyncSocket()
  waitFor serverLoop se

when isMainModule:
  main()
