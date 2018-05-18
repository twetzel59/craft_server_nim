import
  options, strformat, strutils,
  client, utils, vec
from client import ClientId
from utils import notNilOrDie
from vec import nil

const
  DELIMITER = ','
  ID_POSITION = 'P'
  ID_TALK = 'T'

type
  PacketType* = enum
    ptPosition,
    ptYou,
    ptDisconnect,
    ptTime,
    ptTalk,
    ptNick

  PkPosition* = object
    id*: ClientId
    x*, y*, z*, rx*, ry*: float

  PkYou* = object
    id*: ClientId
    x*, y*, z*, rx*, ry*: float

  PkDisconnect* = object
    id*: ClientId

  PkTime* = object
    current*: float
    dayLength*: int

  PkTalk* = object
    message*: string
  
  PkNick* = object
    id*: ClientId
    nick*: string

  Packet* = object
    case kind: PacketType
    of ptPosition:
      pos*: PkPosition
    of ptYou:
      you*: PkYou
    of ptDisconnect:
      disco*: PkDisconnect
    of ptTime:
      time*: PkTime
    of ptTalk:
      talk*: PkTalk
    of ptNick:
      nick*: PkNick

iterator countSplit(original: string not nil):
    tuple[idx: Natural, str: string not nil] =
  var counter = 0
  for i in original.split(DELIMITER):
    yield (idx: counter.Natural, str: notNilOrDie i)
    inc counter

template kind*(p: Packet): PacketType =
  p.kind

converter toPos3Rot2f*(p: PkPosition): vec.Pos3Rot2f =
  (pos: (x: p.x, y: p.y, z: p.z), rot: (x: p.rx, y: p.ry))

proc initPkPosition*(id: ClientId; transform: Pos3Rot2f): PkPosition =
  PkPosition(
    id: id,
    x: transform.pos.x, y: transform.pos.y, z: transform.pos.z,
    rx: transform.rot.x, ry: transform.rot.y
  )

proc initPkYou*(id: ClientId; transform: Pos3Rot2f): PkYou =
  PkYou(
    id: id,
    x: transform.pos.x, y: transform.pos.y, z: transform.pos.z,
    rx: transform.rot.x, ry: transform.rot.y
  )

proc initPkDisconnect*(id: ClientId): PkDisconnect =
  PkDisconnect(id: id)

proc initPkTime*(currentEpochTime: float; dayLength: int): PkTime =
  PkTime(current: currentEpochTime, dayLength: dayLength)

proc initPkTalk*(message: string): PkTalk =
  PkTalk(message: message)

proc initPkNick*(id: ClientId; nickname: string): PkNick =
  PkNick(id: id, nick: nickname)

proc `$`*(p: PkPosition): string not nil =
  result = notNilOrDie(&"P,{p.id},{p.x},{p.y},{p.z},{p.rx},{p.ry}\n")

proc `$`*(u: PkYou): string not nil =
  result = notNilOrDie(&"U,{u.id},{u.x},{u.y},{u.z},{u.rx},{u.ry}\n")

proc `$`*(d: PkDisconnect): string not nil =
  result = notNilOrDie(&"D,{d.id}\n")

proc `$`*(t: PkTime): string not nil =
  result = notNilOrDie(&"E,{t.current},{t.dayLength}\n")

proc `$`*(t: PkTalk): string not nil =
  discard notNilOrDie(t.message)
  result = notNilOrDie(&"T,{t.message}\n")

proc `$`*(n: PkNick): string not nil =
  discard notNilOrDie(n.nick)
  result = notNilOrDie(&"N,{n.id},{n.nick}\n")

proc `$`*(pack: Packet): string not nil =
  case pack.kind:
  of ptPosition:
    result = $pack.pos
  of ptYou:
    result = $pack.you
  of ptDisconnect:
    result = $pack.disco
  of ptTime:
    result = $pack.time
  of ptTalk:
    result = $pack.talk
  of ptNick:
    result = $pack.nick

proc parsePosition(idx: ClientId, data: string not nil): Option[Packet] =
  var pack: PkPosition

  try:
    pack.id = idx

    for idx, str in countSplit(data):
      case idx:
      of 0:
        # packet id
        continue
      of 1:
        pack.x = parseFloat(str)
      of 2:
        pack.y = parseFloat(str)
      of 3:
        pack.z = parseFloat(str)
      of 4:
        pack.rx = parseFloat(str)
      of 5:
        pack.ry = parseFloat(str)
      else:
        # invalid packet, too long
        return none(Packet)
  except ValueError:
    return none(Packet)

  some(Packet(kind: ptPosition, pos: pack))

proc parseTalk(data: string not nil): Option[Packet] =
  var pack: PkTalk

  for idx, str in countSplit(data):
    case idx:
    of 0:
      # packet id
      continue
    of 1:
      pack.message = str
    else:
      # invalid packet, too long
      return none(Packet)
  
  some(Packet(kind: ptTalk, talk: pack))

proc parsePacket*(idx: ClientId, data: string not nil): Option[Packet] =
  case data[0]:
  of ID_POSITION:
    result = parsePosition(idx, data)
  of ID_TALK:
    result = parseTalk(data)
  else:
    result = none(Packet)
