#!/bin/bash

set -euo pipefail

BASEDIR=$(cd "$(dirname "$0")"; pwd -P)
rm -rf "$BASEDIR/Whiteboard/Resource"
mkdir -p "$BASEDIR/Whiteboard/Resource"
cp -R "$BASEDIR/../Whiteboard-bridge/build/"* "$BASEDIR/Whiteboard/Resource"
