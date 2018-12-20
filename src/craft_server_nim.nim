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
  # Tell the Client what its ID is, and what time it is
  # on the server.
  await send(cl.socket, $initYou(id, cl.player.transform))
  await send(cl.socket, $initTime(epochTime(), dayLength))

  # If the welcome message in the common module is not None,
  # send it to the Client.
  if welcome.isSome:
    await send(cl.socket, $initTalk(welcome.get))

proc clientLoop(id: ClientId; cl: Client) {.async.} =
  # Perform the standard Craft handshake.
  await sendInitial(id, cl)

  while true:
    # Wait for network packet to arrive.
    let line = await recvLine cl.socket

    if len(line) == 0:
      # If the line length is zero, th Client has
      # disconnected from the server.
      echo "Disconnecting: ", cl.ipStr
      return
    #else:
    #  echo "Incoming [", cl.ipStr, "]: ", line 

proc serverLoop(se: Server) {.async.} =
  # Bind the TCP server socket to a default localhost
  # address at Craft's port. Then, mark the socket
  # as accepting new connections.
  bindAddr se.socket, craftPort
  listen se.socket

  while true:
    # Wait for a new client to connect, but first,
    # generate the ID the new client will have.
    # Accept any incoming connection.
    let
      id = get nextId se.idGen # TODO: Handle exception. Full server??
      accepted = await acceptAddr se.socket
      client = newClient accepted
    
    echo "Connecting: ", accepted[0]

    # Add the new client to the server's hash table of IDs => Clients.
    se.clients[id] = client

    # Start the Client's asyncronous event loop.
    asyncCheck clientLoop(id, client)

proc main() =
  # Create a new Server and start the main listening loop.
  let se = newServer newAsyncSocket()
  waitFor serverLoop se

when isMainModule:
  main()
