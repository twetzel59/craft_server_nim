import
  std / [ math ],
  common

type
  PosRot* = tuple[x, y, z, rx, ry: float32]

  Player* = object {.requiresInit.}
    transform*: PosRot

func initPlayer*(): Player =
  Player() # default for now

func check*(pr: PosRot): bool =
  # Ensure that a PosRot is valid.
  # Subnormal, NaN and +/- infinate
  # components are not allowed.

  template ck(x: float32): bool =
    case classify x:
    of fcNormal: true
    of fcSubnormal: false
    of fcZero: true
    of fcNegZero: true
    of fcNan: false
    of fcInf: false
    of fcNegInf: false
  
  ck(pr.x) and ck(pr.y) and ck(pr.z) and
    ck(pr.rx) and ck(pr.ry)

func `$`*(pr: PosRot): string =
  $pr.x & sep &
    $pr.y & sep &
    $pr.z & sep &
    $pr.rx & sep &
    $pr.ry
