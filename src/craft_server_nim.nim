import
  std / [ asyncdispatch, asyncnet, options, tables, times ],
  client, common, logging, nicks, packet

const
  craftPort = Port(4080)

type
  Server = ref object
    log: Logger
    nicks: NickManager
    socket: AsyncSocket
    clients: Table[ClientId, Client]
    idGen: IdGenerator

func newServer(log: Logger; nickMgr: NickManager; servSocket: AsyncSocket): Server =
  Server(
    log: log,
    nicks: nickMgr,
    socket: servSocket,
    clients: initTable[ClientId, Client](),
    idGen: initIdGenerator(),
  )

proc sendToAllImpl(se: Server; ignore: Option[ClientId]; pack: Packet) {.async.} =
  # Send the Packet to all the Clients on the server.

  # Stringify it first.
  let data = $pack

  # Send to each Client.
  for id, cl in se.clients:
    if isSome(ignore) and get(ignore) == id:
      continue
    
    await send(cl.socket, data)

template sendToAllExcept(se: Server; ignore: ClientId; pack: Packet): auto =
  sendToAllImpl se, some(ignore), pack

template sendToAll(se: Server; pack: Packet): auto =
  sendToAllImpl se, none(ClientId), pack

proc sendInitial(se: Server; id: ClientId; cl: Client) {.async.} =
  # Tell the Client what its ID is, and what time it is
  # on the server.
  await send(cl.socket, $initYou(id, cl.player.transform))
  await send(cl.socket, $initTime(epochTime(), dayLength))

  # If the welcome message in the common module is not None,
  # send it to the Client.
  if welcome.isSome:
    await send(cl.socket, $initTalk(welcome.get))
  
  # Send the client the positions of the other clients.
  # Other players are handled "lazily" by the Craft client.
  # The are created only when they are first referenced by a
  # Position packet.
  for otherId, otherClient in se.clients:
    # Skip sending our own position to ourself.
    if otherId != id:
      await send(cl.socket,
        $initPosition(otherId, otherClient.player.transform))

proc handleDisconnect(se: Server; id: ClientId; cl: Client) {.async.} =
  await log(se.log, "Disconnecting: ", cl.ipStr)

  let pack = initDisconnect(id)
  await sendToAllExcept(se, id, pack)

proc handleBadVersion(se: Server; id: ClientId; cl: Client; ver: int) {.async.} =
  await log(se.log, "Client ", cl.ipStr,
    " is running unsupported version [", ver,
    "] and will be kicked.")

proc removeClient(se: Server; id: ClientId, cl: Client) =
  # Close the Client's socket.
  close cl

  # Remove the Client from the server.
  del se.clients, id

  # Free the Client's ID.
  releaseId se.idGen, id

proc clientLoop(se: Server; id: ClientId; cl: Client) {.async.} =
  # Perform the standard Craft handshake.
  await sendInitial(se, id, cl)

  while true:
    # Wait for network packet to arrive.
    let line = await recvLine cl.socket

    if len(line) == 0:
      # If the line length is zero, the Client has
      # disconnected from the server.
      removeClient se, id, cl
      await handleDisconnect(se, id, cl)
      return
    else:
      #echo "Incoming [", cl.ipStr, "]: ", line
      try:
        let pack = parsePacket(id, line).get
        
        case pack.kind:
        of Position:
          cl.player.transform = pack.posTransform
          await sendToAllExcept(se, id, initPosition(pack.posId, pack.posTransform))
        of Talk:
          await sendToAll(se, initTalk(pack.msg))
        of Version:
          if pack.version != protocolVer:
            removeClient se, id, cl
            await handleBadVersion(se, id, cl, pack.version)
            return
        else:
          discard
      except UnpackError:
        discard

proc serverLoop(se: Server) {.async.} =
  # Log the server start with time and date.
  await log(se.log, '\n', getTime().format("yyyy-MM-dd hh:mm:ss"),
    " Starting server")

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
    
    await log(se.log, "Connecting: ", accepted[0])

    # Add the new client to the server's hash table of IDs => Clients.
    se.clients[id] = client

    # Start the Client's asyncronous event loop.
    asyncCheck clientLoop(se, id, client)

proc main() =
  # TODO: Clean exit is not yet supported, and files
  # are not cleaned up. Once chat commands are supported,
  # add /stop command to stop gracefully and close files.

  # Initialize the logger. The log file will be created if
  # it doesn't exist. Set the logger to close when the
  # server exits cleanly.
  let log = newLogger logFile
  defer: close log

  # Create the nickname manager. The nickname file will
  # be created if it doesn't exist. The nickmanager will
  # close when the server exits cleanly.
  let nickMgr = get newNickManager(log, nickFile)
  defer: close nickMgr

  # Create the server's socket, and allow reuse of the address to
  # prevent annoying "Address already in use" errors.
  let socket = newAsyncSocket()
  setSockOpt socket, OptReuseAddr, true

  # Create a new Server and start the main listening loop.
  let se = newServer(log, nickMgr, socket)
  waitFor serverLoop se

when isMainModule:
  main()
