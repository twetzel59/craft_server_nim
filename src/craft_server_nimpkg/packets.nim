import
  options, strformat, strutils,
  client, utils, vec
from client import ClientId
from utils import notNilOrDie
from vec import nil

const
  DELIMITER = ','
  ID_POSITION* = 'P'
  ID_YOU* = 'U'

type
  PacketType* = enum
    ptPosition,
    ptYou,
    ptDisconnect

  PkPosition* = object
    id*: ClientId
    x*, y*, z*, rx*, ry*: float

  PkYou* = object
    id*: ClientId
    x*, y*, z*, rx*, ry*: float

  PkDisconnect = object
    id*: ClientId

  Packet* = object
    case kind: PacketType
    of ptPosition:
      pos*: PkPosition
    of ptYou:
      you*: PkYou
    of ptDisconnect:
      disco*: PkDisconnect

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

proc initPacket*(p: PkPosition): Packet =
  result = Packet(kind: ptPosition, pos: p)

proc initPacket*(u: PkYou): Packet =
  result = Packet(kind: ptYou, you: u)

proc initPacket*(d: PkDisconnect): Packet =
  result = Packet(kind: ptDisconnect, disco: d)

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

proc `$`*(p: PkPosition): string not nil =
  result = notNilOrDie(&"P,{p.id},{p.x},{p.y},{p.z},{p.rx},{p.ry}\n")

proc `$`*(u: PkYou): string not nil =
  result = notNilOrDie(&"U,{u.id},{u.x},{u.y},{u.z},{u.rx},{u.ry}\n")

proc `$`*(d: PkDisconnect): string not nil =
  result = notNilOrDie(&"D,{d.id}\n")

proc `$`*(pack: Packet): string not nil =
  case pack.kind:
  of ptPosition:
    result = $pack.pos
  of ptYou:
    result = $pack.you
  of ptDisconnect:
    result = $pack.disco

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

proc parsePacket*(idx: ClientId, data: string not nil): Option[Packet] =
  case data[0]:
  of ID_POSITION:
    result = parsePosition(idx, data)
  else:
    result = none(Packet)
