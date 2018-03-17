from nativesockets import Port

const
  defaultWorldFile* = "world.db"
  defaultPort* = 4080.Port

type
  Settings* = object
    worldFile*: string not nil
    port*: Port

proc initSettings*(): Settings =
  result = Settings(
    worldFile: defaultWorldFile,
    port: defaultPort
  )

proc verify*(s: Settings): bool =
  if s.worldFile.len == 0:
    return false

  true
