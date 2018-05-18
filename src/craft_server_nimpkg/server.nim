import std / net
import client, settings
from utils as ut import nil

type
  ServerSocket = Socket not nil

  Server = object
    clients: ut.Seq[Client]
    socket: ServerSocket

proc initServer(): Server =
  Server(clients: @[], socket: newSocket())

proc bindListen(s: Server; settings: Settings) =
  s.socket.bindAddr(settings.port)
  s.socket.listen()

proc serverBegin*(settings: Settings) =
  echo "Using world file: ", settings.worldFile
  echo "Using port: ", $int16(settings.port)

  var s = initServer()
  s.bindListen(settings)

  while true:
    var clientSocket = new Socket
    var address = ""
    s.socket.acceptAddr(clientSocket, address)

    echo address, " is connecting"
