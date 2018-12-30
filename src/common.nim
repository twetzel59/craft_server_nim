import
  std / [ options ]

const
  # Server
  logFile* = "log.txt"
  nickFile* = "nicks.txt"

  # Game
  dayLength* = 600
  welcome* = some("Welcome to our very *Nimble* Craft server!")

  # Network
  protocolVer* = 1
  sep* = ','
  tail* = '\n'
