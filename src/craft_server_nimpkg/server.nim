import settings

proc serverBegin*(settings: Settings) =
  echo "Using world file: ", settings.worldFile
  echo "Using port: ", $int16(settings.port)
