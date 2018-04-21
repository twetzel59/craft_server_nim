import
  net, streams, tables
from os import existsFile

const
  NICK_FILE = "nicks.txt"

type
  NickManager* = object {.requiresInit.}
    map: Table[IpAddress, string]
    file: FileStream not nil

proc createFile();

proc initNickManager*(): NickManager =
  createFile()

  NickManager(
    map: initTable[IpAddress, string](),
    file: openFileStream(NICK_FILE, fmReadWriteExisting)
  )

proc createFile() =
  if not existsFile(NICK_FILE):
    let f = open(NICK_FILE, fmAppend)
    f.close()
