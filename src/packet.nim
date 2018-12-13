type
  PacketKind = enum
    Talk

  Packet* = object
    case kind: PacketKind:
    of Talk:
      msg: string

func kindToHeader(kind: PacketKind): char =
  case kind:
  of Talk: 'T'

func initTalk(msg: string): Packet =
  Packet(kind: Talk, msg: msg)
