type
  PosRot* = tuple[x, y, z, rx, ry: float32]

  Player* = object {.requiresInit.}
    transform: PosRot

func initPlayer*(): Player =
  Player() # default for now