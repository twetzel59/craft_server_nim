import
  std / [ options, strutils ],
  client, common, entity

const
  headerDisconnect = 'D'
  headerPosition = 'P'
  headerTalk = 'T'
  headerTime = 'E'
  headerVersion = 'V'
  headerYou = 'U'

type
  PacketKind* = enum
    Disconnect,
    Position,
    Talk,
    Time,
    Version,
    You

  Packet* = object
    case kind*: PacketKind:
    of Disconnect:
      # Outbound only
      discoId: ClientId
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
func initDisconnect*(id: ClientId): Packet =
  Packet(kind: Disconnect, discoId: id)

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
  of Disconnect:
    #D,<client id: unsigned>
    headerDisconnect & sep & $pack.discoId & tail
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

func parsePacket*(senderId: ClientId; packStr: string): Option[Packet] =
  if packStr.len < 3:
    return none(Packet)
  
  let pieces = split(packStr, sep)

  case packStr[0]:
  of headerPosition:
    if pieces.len == 6:
      try:
        let pr = (
          x:  parseFloat(pieces[1]).float32,
          y:  parseFloat(pieces[2]).float32,
          z:  parseFloat(pieces[3]).float32,
          rx: parseFloat(pieces[4]).float32,
          ry: parseFloat(pieces[5]).float32,
        )

        if check pr:
          return some(initPosition(senderId, pr))
        else:
          return none(Packet)
      except ValueError:
        discard
  of headerTalk:
    if pieces.len == 2:
      return some(initTalk(pieces[1]))
  of headerVersion:
    if pieces.len == 2:
      try:
        return some(initVersion(parseInt(pieces[1])))
      except ValueError:
        discard
  else:
    discard

  none(Packet)
