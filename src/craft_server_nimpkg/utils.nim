proc notNilOrDie*(arg: string): string not nil =
  if arg.isNil:
    raise newException(AssertionError, "notNilOrDie: arg was nil")
  else:
    return arg
