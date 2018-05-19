from nativesockets import Port
import
  parseopt, strutils,
  craft_server_nimpkg / [server, settings, utils]

type
  InvalidArgsError = object of ValueError

const usage = "Usage:\tcraft_server_nim [-w:world_file] [-p:port]\tOR\n" &
                "\tcraft_server_nim [--worldFile:world_file] [--port:port]\n" &
                "world_file defaults to " & defaultWorldFile & "\n" &
                "port defaults to " & $int16(defaultPort)

proc printUsageDie() =
  echo usage
  raise newException(InvalidArgsError, "Invalid arguments")

proc handleArgs(): Settings =
  result = initSettings()

  for kind, key, val in getopt():
    case kind:
    of cmdShortOption:
      case key
      of "w":
        result.worldFile = notNil(val)
      of "p":
        result.port = val.parseInt().Port
      else:
        printUsageDie()
    of cmdLongOption:
      case key
      of "worldFile":
        result.worldFile = notNil(val)
      of "port":
        result.port = val.parseInt().Port
      else:
        printUsageDie()
    of cmdArgument:
      printUsageDie()
    of cmdEnd:
      break

  if not verify(result):
    printUsageDie()

proc start() =
  serverBegin(handleArgs())

when isMainModule:
  try:
    start()
  except ValueError:
    echo getCurrentExceptionMsg()
