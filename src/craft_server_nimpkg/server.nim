import std / [net, tables]
import client, settings
from utils as ut import nil

type
  ServerSocket = Socket not nil

  Server = object
    socket: ServerSocket
    clients: Table[ClientId, Client]
    unusedIds: set[ClientId]

proc initServer(): Server =
  Server(
    socket: newSocket(),
    clients: initTable[ClientId, Client](),
    unusedIds: {0.ClientId .. high(ClientId).ClientId}
  )

proc bindListen(s: Server; settings: Settings) =
  s.socket.bindAddr(settings.port)
  s.socket.listen()

proc serverBegin*(settings: Settings) =
  echo "Using world file: ", settings.worldFile
  echo "Using port: ", $int16(settings.port)

  var s = initServer()
  s.bindListen(settings)
  echo "unused: ", s.unusedIds

  while true:
    var clientSocket = new Socket
    var address = ""
    s.socket.acceptAddr(clientSocket, address)

    echo address, " is connecting"
