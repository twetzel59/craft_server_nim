import
  std / [ asyncdispatch, asyncfile ]

type
  Logger* = ref object
    file: AsyncFile

proc newLogger*(filename: string): Logger =
  Logger(file: openAsync(filename, fmAppend))

proc doLog(lg: Logger; str: string) {.async.} =
  await write(lg.file, str)
  write stdout, str

proc log*(lg: Logger; x: varargs[string, `$`]): Future[void] =
  var str = ""
  for i in x:
    str &= i
  str &= '\n'

  doLog lg, str

proc close*(lg: Logger) =
  echo "Stopping logger"
  close lg.file
