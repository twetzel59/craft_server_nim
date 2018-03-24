type
  Vec2*[T] = tuple[x, y: T]
  Vec2f* = Vec2[float]

  Vec3*[T] = tuple[x, y, z: T]
  Vec3f* = Vec3[float]

  Pos3Rot2*[T] = tuple[pos: Vec3[T], rot: Vec2[T]]
  Pos3Rot2f* = Pos3Rot2[float]
