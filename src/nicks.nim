import
  std / [ asyncdispatch, asyncfile, json, net, options, os, tables, unicode ],
  logging

type
  NickManager* = ref object
    # file to store nicknames
    file: AsyncFile

    # map from ip string to nickname
    table*: Table[string, string]
  
  ResultKind = enum
    Success,
    Fail
  
  Result = object
    case kind: ResultKind
    of Success:
      table: Table[string, string]
    of Fail:
      errMsg: string

func verify(nickname: string): bool =
  # Make sure that the supplied nickname is allowed.
  # Check for invalid characters. Only alphabetical,
  # numerical, and underscore characters are allowed.

  const otherAllowed = "0123456789_"

  for r in runes nickname:
    if not isAlpha(r) and r notin toRunes(otherAllowed):
      return false
  
  true

proc createOrOpen(filename: string): AsyncFile =
  if not existsFile(filename):
    # The file must be created if it doesn't exist.
    # It also needs the bare minimum JSON structure,
    # which consists of an empty table, denoted by
    # a pair of curly braces.
    # Also, close the file so that it can be opened
    # asyncronously.
    let tempHandle = open(filename, fmAppend)
    writeLine tempHandle, "{}"
    close tempHandle

  openAsync filename, fmReadWriteExisting

{.push warnings: off.}
proc parseNickFile(file: AsyncFile): Future[Result] {.async.} =
  try:
    let
      contents = await readAll file
      jsonNode = parseJson contents
      table = to(jsonNode, Table[string, string])
    
    result = Result(kind: Success, table: table)
  except JsonParsingError:
    result = Result(kind: Fail, errMsg: getCurrentExceptionMsg())
{.pop.}

proc newNickManager*(lg: Logger; filename: string): Option[NickManager] =
  let
    nickFile = createOrOpen filename
    nickTable = waitFor parseNickFile nickFile
  
  result = case nickTable.kind:
  of Success:
    some(NickManager(
      file: nickFile,
      table: nickTable.table,
    ))
  of Fail:
    waitFor log(lg, "Error parsing nickname file:\n", nickTable.errMsg)
    none(NickManager)

func generateJsonTree(nm: NickManager): JsonNode =
  result = newJObject()

  for key, val in nm.table:
    result[key] = newJString val

proc save(nm: NickManager) {.async.} =
  let jsonStr = pretty(generateJsonTree(nm)) & "\n"

  setFileSize nm.file, 0
  setFilePos nm.file, 0
  await write(nm.file, jsonStr)

proc close*(nm: NickManager) =
  close nm.file

proc register*(nm: NickManager; ipStr, nickname: string): Future[bool] {.async.} =
  if not isIpAddress(ipStr) or not verify(nickname):
    return false

  nm.table[ipStr] = nickname
  await save nm

  return true
