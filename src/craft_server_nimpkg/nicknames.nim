import
  net, options, parseutils, sets, streams, tables
from hashes import
  Hash, hash
from os import existsFile
from strutils import
  Digits, Letters

const
  NICK_FILE = "nicks.txt"
  ERROR_MSG = "Failed to parse " & NICK_FILE
  DUPLICATE_IP_MSG = "Duplicate IP address in " & NICK_FILE
  DUPLICATE_USERNAME_MSG = "Duplicate username in " & NICK_FILE

type
  NickManagerObj = object
    map: Table[IpAddress, string]
    file: FileStream not nil

  NickManager* = ref NickManagerObj not nil

proc createFileIfNeeded();
proc parseFile(nm: var NickManager);
proc hash(ip: IpAddress): Hash;

proc newNickManager*(): NickManager =
  createFileIfNeeded()

  result = NickManager(
    map: initTable[IpAddress, string](),
    file: openFileStream(NICK_FILE, fmReadWriteExisting)
  )

  result.parseFile()

proc getOrNil*(nm: NickManager; ip: IpAddress): nil string =
  nm.map.withValue(ip, nick):
    return nick[]

proc createFileIfNeeded() =
  let f = open(NICK_FILE, fmAppend)
  f.close()

proc parseFile(nm: var NickManager) {.raises: [ValueError].} =
  template fail(msg = ERROR_MSG): untyped =
    raise newException(ValueError, msg)

  var
    line = ""
    username = ""
    ipStr = ""
    allUsernames = initSet[string]()
  
  while nm.file.readLine(line):
    # Format of a nicknames file line,
    # where [ws] indicates optional
    # whitespace, = denotes a literal
    # equals sign, and <val> denotes
    # a required value called val:
    #
    # [ws]<ipStr>[ws]=[ws]<username>[ws]
    #  A     B    C  D E      F      G
    #
    # The above lettered sections
    # are referenced in the parsing code.

    # Empty line
    if line.len == 0:
      continue

    var
      counter = 0
      last = 0

    # A
    counter += skipWhitespace(line, counter)

    # B
    last = parseWhile(line, ipStr, Digits + {'.'}, counter)
    counter += last
    if last == 0:
      fail()

    # C
    counter += skipWhitespace(line, counter)

    # D
    last = skipWhile(line, {'='}, counter)
    counter += last
    if last != 1:
      fail()

    # E
    counter += skipWhitespace(line, counter)
    
    # F
    last = parseWhile(line, username, Letters + Digits, counter)
    counter += last
    if last == 0:
      fail()
    
    # G
    counter += skipWhitespace(line, counter)

    # Verification
    if counter != line.len:
      fail()

    #echo "Final: ", ipStr, " = ", username

    let ip = parseIpAddress(ipStr)

    if ip in nm.map:
      fail(DUPLICATE_IP_MSG)
    
    if username in allUsernames:
      fail(DUPLICATE_USERNAME_MSG)

    nm.map[ip] = username
    allUsernames.incl(username)

  echo "Using nickname file: " & NICK_FILE

proc hash(ip: IpAddress): Hash =
  case ip.family:
  of IpV4:
    result = hash(ip.address_v4)
  of IpV6:
    result = hash(ip.address_v6)
