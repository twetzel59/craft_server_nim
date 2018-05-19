type
  Seq*[T] = seq[T] not nil

proc notNil*(str: string): string not nil =
  if str.isNil:
    raise newException(ValueError, "nil string")
  else:
    result = str

proc notNil*[T: ref object](obj: T): T not nil =
  if obj.isNil:
    raise newException(ValueError, "nil ref object")
  else:
    result = obj

