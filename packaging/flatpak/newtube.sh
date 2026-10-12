#!/bin/sh
export LD_LIBRARY_PATH="/app/lib/newtube/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec /app/lib/newtube/newtube "$@"
