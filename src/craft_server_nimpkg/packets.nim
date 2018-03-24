import
  options, strformat, strutils,
  client, utils

const
  DELIMITER = ','
  ID_POSITION* = 'P'
  ID_YOU* = 'U'

type
  PacketType* = enum
    ptPosition,
    ptYou,

  PkPosition* = object
    id*: ClientId
    x*, y*, z*, rx*, ry*: float

  PkYou* = object
    id*: ClientId
    x*, y*, z*, rx*, ry*: float

  Packet* = object
    case kind: PacketType
    of ptPosition:
      pos*: PkPosition
    of ptYou:
      you*: PkYou

iterator countSplit(original: string not nil):
    tuple[idx: Natural, str: string not nil] =
  var counter = 0
  for i in original.split(DELIMITER):
    yield (idx: counter.Natural, str: notNilOrDie i)
    inc counter

proc initPacket*(p: PkPosition): Packet =
  result = Packet(kind: ptPosition, pos: p)

proc initPacket*(u: PkYou): Packet =
  result = Packet(kind: ptYou, you: u)

proc `$`*(p: PkPosition): string not nil =
  result = notNilOrDie(&"P,{p.id},{p.x},{p.y},{p.z},{p.rx},{p.ry}\n")

proc `$`*(u: PkYou): string not nil =
  result = notNilOrDie(&"U,{u.id},{u.x},{u.y},{u.z},{u.rx},{u.ry}\n")

proc `$`*(pack: Packet): string not nil =
  case pack.kind:
  of ptPosition:
    result = $pack.pos
  of ptYou:
    result = $pack.you

proc kind*(p: Packet): PacketType =
  p.kind

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
