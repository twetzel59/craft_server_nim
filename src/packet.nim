import
  client, common, entity

type
  PacketKind = enum
    Talk,
    Time,
    You

  Packet* = object
    case kind: PacketKind:
    of Talk:
      msg: string
    of Time:
      time: float
      dayLength: int
    of You:
      id: ClientId
      transform: PosRot

func initTalk*(msg: string): Packet =
  Packet(kind: Talk, msg: msg)

func initTime*(current: float; dayLength: int): Packet =
  Packet(kind: Time, time: current, dayLength: dayLength)

func initYou*(id: ClientId; pr: PosRot): Packet =
  Packet(kind: You, id: id, transform: pr)

func `$`*(pack: Packet): string =
  case pack.kind:
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
    # U,<client id: unsigned>,<player x: fractional>,<y>,<z>,<rx>,<ry>
    'U' & sep &
      $pack.id & sep &
      $pack.transform & tail
