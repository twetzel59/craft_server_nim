import
  asyncdispatch, asyncnet, options, tables,
  client, nicknames, packets, settings, strutils
from math import fmod
from times import epochTime
from utils import notNilOrDie

const
  DAY_LENGTH = 600

type
  Command = enum
    cmdTime,
    cmdNick

  ServSocket = AsyncSocket not nil

  Server = ref object
    servSocket: ServSocket
    clients: Table[ClientId, Client]
    nicks: NickManager
    unusedIds: set[ClientId]
    timeOffset: float

proc sendDisconnect(se: Server; idx: ClientId) {.async.} =
  for id, client in se.clients:
    if id != idx:
      withSocketIfAlive(client):
        await socket.send($initPkDisconnect(idx))

proc sendTime(se: Server; socket: AsyncSocket) {.async.} =
  await socket.send($initPkTime(epochTime() + se.timeOffset, DAY_LENGTH))

proc sendNicks(se: Server; socket: AsyncSocket) {.async.} =
  for idx, client in se.clients:
    let nick: nil string = se.nicks.getOrNil(client.ip)
    if not nick.isNil:
      await socket.send($initPkNick(idx, nick))

proc sendNickUpdate(se: Server; idx: ClientId) {.async.} =
  let nick: nil string = se.nicks.getOrNil(se.clients[idx].ip)
  if not nick.isNil:
    for client in se.clients.values():
      withSocketIfAlive(client):
        await socket.send($initPkNick(idx, nick))

proc sendInitial(se: Server; idx: ClientId; cl: Client) {.async.} =
  withSocketIfAlive(cl):
    await socket.send($initPkYou(idx, cl.transform))
    await se.sendTime(socket)

    for id, otherClient in se.clients:
      await socket.send($initPkPosition(id, otherClient.transform))

    await se.sendNicks(socket)

proc handleInvalidCommand(se: Server; command: Command; idx: ClientId) {.async.} =
  const messages: array[Command, string not nil] = [
    notNilOrDie "Usage: /time <daytime: float>",
    notNilOrDie "Usage: /nick <nickname: string>",
  ]

  withSocketIfAlive(se.clients[idx]):
    await socket.send($initPkTalk(messages[command]))

proc handleChatCommand(se: Server; idx: ClientId; msg: string not nil) {.async.} =
  echo "command: ", msg
  let parts = msg.splitWhitespace()

  case parts[0]:
  of "/time":
    if parts.len == 2:
      var newTime = none(float)

      try:
        newTime = some(parts[1].parseFloat())
      except ValueError:
        discard

      if newTime.isSome():
        withSocketIfAlive(se.clients[idx]):
          await socket.send($initPkTalk("Set time to " & $newTime.get()))
          se.timeOffset = fmod(newTime.get(), DAY_LENGTH) - epochTime()
          for client in se.clients.values():
            withSocketIfAlive(client):
              await se.sendTime(socket)
      else:
        await se.handleInvalidCommand(cmdTime, idx)
    else:
      await se.handleInvalidCommand(cmdTime, idx)
  of "/nick":
    if parts.len == 2:
      if parts[1].isAlphaNumeric():
        withSocketIfAlive(se.clients[idx]):
          await socket.send($(initPkTalk("Set nickname to " & parts[1])))
          #for client in se.clients.values():
          #  withSocketIfAlive(client):
          #    await se.sendNick(socket)
      else:
        await se.handleInvalidCommand(cmdNick, idx)
    else:
      await se.handleInvalidCommand(cmdNick, idx)
  else:
    discard

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
  of ptTalk:
    if not pack.talk.message.isNil:
      if pack.talk.message.startsWith('/'):
        await handleChatCommand(se, idx, pack.talk.message)
      else:
        let msg = $pack
        for client in se.clients.values():
          withSocketIfAlive(client):
            await socket.send(msg)
  else:
    discard

proc clientLoop(se: Server; idx: ClientId) {.async.} =
  template cl(): untyped = se.clients[idx]

  await se.sendNickUpdate(idx)

  while true:
    withSocketIfAlive(cl):
      let line = notNilOrDie await socket.recvLine()
      #echo line

      let packet = parsePacket(idx, line)
      if packet.isSome:
        await handlePacket(se, idx, packet.get())

      if line.len == 0:
        # Disconnect
        await se.sendDisconnect(idx)
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
      await sendInitial(se, idx, client)
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
    nicks: newNickManager(),
  )

proc cleanup(se: Server) =
  se.servSocket.close()

proc serverBegin*(settings: Settings) =
  let s = newServer(settings)
  defer: s.cleanup()

  echo "Using world file: ", settings.worldFile
  echo "Using port: ", $int16(settings.port)

  waitFor listenIncoming(s)
