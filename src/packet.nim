import
  client, common, entity

type
  PacketKind = enum
    Position,
    Talk,
    Time,
    You

  Packet* = object
    case kind: PacketKind:
    of Position:
      posId: ClientId
      posTransform: PosRot
    of Talk:
      msg: string
    of Time:
      time: float
      dayLength: int
    of You:
      youId: ClientId
      youTransform: PosRot

func initPosition*(id: ClientId; pr: PosRot): Packet =
  Packet(kind: Position, posId: id, posTransform: pr)

func initTalk*(msg: string): Packet =
  Packet(kind: Talk, msg: msg)

func initTime*(current: float; dayLength: int): Packet =
  Packet(kind: Time, time: current, dayLength: dayLength)

func initYou*(id: ClientId; pr: PosRot): Packet =
  Packet(kind: You, youId: id, youTransform: pr)

func `$`*(pack: Packet): string =
  case pack.kind:
  of Position:
    # P,<client id: unsigned>,<player x: fractional>,<y>,<z>,<rx>,<ry>\n
    'P' & sep &
      $pack.posId & sep &
      $pack.posTransform & tail
  of Talk:
    # T,<message: string>\n
    'T' & sep &
      pack.msg & tail
  of Time:
    # E,<current time: fractional>,<day length: unsigned>\n
    'E' & sep &
      $pack.time & sep &
      $pack.dayLength & tail
  of You:
    # U,<client id: unsigned>,<player x: fractional>,<y>,<z>,<rx>,<ry>\n
    'U' & sep &
      $pack.youId & sep &
      $pack.youTransform & tail
