import
  std / [ options, strutils ],
  client, common, entity

const
  headerPosition = 'P'
  headerTalk = 'T'
  headerTime = 'E'
  headerVersion = 'V'
  headerYou = 'U'

type
  PacketKind* = enum
    Position,
    Talk,
    Time,
    Version,
    You

  Packet* = object
    case kind*: PacketKind:
    of Position:
      # In/Out
      posId*: ClientId
      posTransform*: PosRot
    of Talk:
      # In/Out
      msg*: string
    of Time:
      # Outbound only
      time: float
      dayLength: int
    of Version:
      # Inbound only
      version*: int
    of You:
      # Outbound only
      youId: ClientId
      youTransform: PosRot

# Public constructors
func initPosition*(id: ClientId; pr: PosRot): Packet =
  Packet(kind: Position, posId: id, posTransform: pr)

func initTalk*(msg: string): Packet =
  Packet(kind: Talk, msg: msg)

func initTime*(current: float; dayLength: int): Packet =
  Packet(kind: Time, time: current, dayLength: dayLength)

func initYou*(id: ClientId; pr: PosRot): Packet =
  Packet(kind: You, youId: id, youTransform: pr)

# Private constructors
func initVersion(version: int): Packet =
  Packet(kind: Version, version: version)

func `$`*(pack: Packet): string =
  case pack.kind:
  of Position:
    # P,<client id: unsigned>,<player x: fractional>,<y>,<z>,<rx>,<ry>\n
    headerPosition & sep &
      $pack.posId & sep &
      $pack.posTransform & tail
  of Talk:
    # T,<message: string>\n
    headerTalk & sep &
      pack.msg & tail
  of Time:
    # E,<current time: fractional>,<day length: unsigned>\n
    headerTime & sep &
      $pack.time & sep &
      $pack.dayLength & tail
  of Version:
    raise newException(ValueError, "Stringify: Version packets are not outbound")
  of You:
    # U,<client id: unsigned>,<player x: fractional>,<y>,<z>,<rx>,<ry>\n
    headerYou & sep &
      $pack.youId & sep &
      $pack.youTransform & tail

func parsePacket*(packet: string): Option[Packet] =
  if packet.len < 3:
    return none(Packet)
  
  let pieces = split(packet, sep)

  case packet[0]:
  of headerVersion:
    if pieces.len == 2:
      try:
        return some(initVersion(parseInt(pieces[1])))
      except ValueError:
        discard
  else:
    discard

  none(Packet)
