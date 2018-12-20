import
  std / [ asyncdispatch, asyncnet, options, tables, times ],
  client, common, packet

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

proc sendInitial*(id: ClientId; cl: Client) {.async.} =
  await send(cl.socket, $initYou(id, cl.player.transform))
  await send(cl.socket, $initTime(epochTime(), dayLength))

proc clientLoop(id: ClientId; cl: Client) {.async.} =
  await sendInitial(id, cl)

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

    asyncCheck clientLoop(id, client)

proc main() =
  let se = newServer newAsyncSocket()
  waitFor serverLoop se

when isMainModule:
  main()
