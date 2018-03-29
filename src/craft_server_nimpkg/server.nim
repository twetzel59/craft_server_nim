import
  asyncdispatch, asyncnet, options, tables,
  client, packets, settings, utils

from os import sleep

type
  ServSocket = AsyncSocket not nil

  Server = ref object
    servSocket: ServSocket
    clients: Table[ClientId, Client]
    unusedIds: set[ClientId]

proc sendInitial(se: Server; idx: ClientId; cl: Client) {.async.} =
  withSocketIfAlive(cl):
    await socket.send($initPkYou(idx, cl.transform))

    for id, client in se.clients:
      if id != idx:
        await socket.send($initPkPosition(id, client.transform))

proc handlePacket(se: Server; idx: ClientId; pack: Packet) {.async.} =
  case pack.kind:
  of ptPosition:
    let msg = $pack
    for id, client in se.clients.mpairs():
      #echo $client.transform

      if id == idx:
        client.transform = pack.pos.toPos3Rot2f()
      else:
        withSocketIfAlive(client):
          await socket.send(msg)
  else:
    discard

proc clientLoop(se: Server; idx: ClientId) {.async.} =
  template cl(): untyped = se.clients[idx]

  while true:
    withSocketIfAlive(cl):
      let line = notNilOrDie await socket.recvLine()
      #echo line

      let packet = parsePacket(idx, line)
      try:
        let packet = packet.get()
        asyncCheck handlePacket(se, idx, packet)
      except:
        discard

      if line.len == 0:
        # Disconnect
        cl.closeSocketMarkDead()
        se.clients.del(idx)
        se.unusedIds.incl(idx)
        return

proc nextClientId(se: Server): ClientId =
  result = ClientId(se.clients.len)
  
  for i in se.unusedIds:
    if i <= result:
      result = i
      se.unusedIds.excl(i)
      break

proc listenIncoming(se: Server) {.async.} =
  while true:
    let (clientAddr, clientSocket) = await se.servSocket.acceptAddr()

    if not clientAddr.isNil:
      echo "Connecting: ", clientAddr

      let idx = se.nextClientId()
      let client = initClient(clientAddr, clientSocket)
      asyncCheck sendInitial(se, idx, client)
      se.clients.add(idx, client)
      asyncCheck se.clientLoop(idx)

proc createSocket(port: Port): AsyncSocket =
  result = newAsyncSocket()
  result.bindAddr(port)
  result.listen

proc newServer(settings: Settings): Server =
  result = Server(
    servSocket: createSocket(settings.port),
    clients: initTable[ClientId, Client](),
  )

proc cleanup(se: Server) =
  se.servSocket.close()

proc serverBegin*(settings: Settings) =
  let s = newServer(settings)
  defer: s.cleanup()

  echo "Using world file: ", settings.worldFile
  echo "Using port: ", $int16(settings.port)

  waitFor listenIncoming(s)
