import
  common

type
  PosRot* = tuple[x, y, z, rx, ry: float32]

  Player* = object {.requiresInit.}
    transform*: PosRot

func initPlayer*(): Player =
  Player() # default for now

func `$`*(pr: PosRot): string =
  $pr.x & sep &
    $pr.y & sep &
    $pr.z & sep &
    $pr.rx & sep &
    $pr.ry
