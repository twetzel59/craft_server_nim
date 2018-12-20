import
  client, common, entity

type
  PacketKind = enum
    Talk,
    You

  Packet* = object
    case kind: PacketKind:
    of Talk:
      msg: string
    of You:
      id: ClientId
      transform: PosRot

func initTalk*(msg: string): Packet =
  Packet(kind: Talk, msg: msg)

func initYou*(id: ClientId; pr: PosRot): Packet =
  Packet(kind: You, id: id, transform: pr)

func `$`*(pack: Packet): string =
  case pack.kind:
  of Talk:
    "T" & sep &
      pack.msg & tail
  of You:
    "U" & sep &
      $pack.id & sep &
      $pack.transform & tail
