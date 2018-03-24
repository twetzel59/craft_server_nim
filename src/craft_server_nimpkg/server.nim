import
  asyncdispatch, asyncnet, options, tables,
  client, packets, settings, utils

from os import sleep

type
  ServSocket = AsyncSocket not nil

  Server = ref object
    servSocket: ServSocket
    clients: Table[ClientId, Client]

proc sendInitial(idx: ClientId, cl: Client) {.async.} =
  withSocketIfAlive(cl):
    await socket.send($initPacket(PkYou(
      id: idx,
      x: 0, y: 0, z: 0,
      rx: 0, ry: 0, 
    )))

proc handlePacket(se: Server; idx: ClientId; pack: Packet) {.async.} =
  case pack.kind:
  of ptPosition:
    let msg = $pack
    for id, client in se.clients.mpairs():
      #echo $client.transform

      if id == idx:
        client.transform = (pos: (x: pack.pos.x,
                                  y: pack.pos.y,
                                  z: pack.pos.z),
                            rot: (x: pack.pos.rx,
                                  y: pack.pos.ry))
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
        return

proc listenIncoming(se: Server) {.async.} =
  while true:
    let (clientAddr, clientSocket) = await se.servSocket.acceptAddr()

    if not clientAddr.isNil:
      echo "Connecting: ", clientAddr

      let idx = ClientId(se.clients.len)
      let client = initClient(clientAddr, clientSocket)
      asyncCheck sendInitial(idx, client)
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
