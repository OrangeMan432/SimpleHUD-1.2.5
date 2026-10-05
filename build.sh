#!/usr/bin/env bash
# Build SimpleHUD-1.2.5.jar (vanilla 1.2.5 MultiMC patch jar) via RetroMCP-Java.
# Repo root doubles as the RetroMCP workspace directory.
# Requires: Java 8 (for RetroMCP) and Python 3 (for the HUD patch applier).
set -euo pipefail
cd "$(dirname "$0")"

find_java8() {
  for cand in "${JAVA8_HOME:-}" \
    "/c/Program Files/Java/openjdk-8u212-b03/bin/java.exe" \
    "$HOME/.jdks/openjdk-8u212-b03/bin/java.exe"; do
    [ -n "$cand" ] && [ -x "$cand" ] && { echo "$cand"; return 0; }
  done
  if command -v java >/dev/null 2>&1 && java -version 2>&1 | grep -q '1\.8\.0'; then
    command -v java; return 0
  fi
  echo "ERROR: Java 8 not found. Set JAVA8_HOME to a JDK 8 install." >&2
  return 1
}

find_retromcp() {
  if [ -n "${RETROMCP_JAR:-}" ] && [ -f "$RETROMCP_JAR" ]; then echo "$RETROMCP_JAR"; return 0; fi
  for cand in \
    "../RetroMCP-Java/build/libs/RetroMCP-CLI-all.jar" \
    "./tools/RetroMCP-CLI-all.jar"; do
    [ -f "$cand" ] && { echo "$cand"; return 0; }
  done
  echo "ERROR: RetroMCP-CLI-all.jar not found." >&2
  echo "  Clone https://github.com/MCPHackers/RetroMCP-Java next to this repo and run its 'build' task," >&2
  echo "  or drop RetroMCP-CLI-all.jar into tools/ (or set RETROMCP_JAR)." >&2
  return 1
}

JAVA8="$(find_java8)"
RMCP="$(find_retromcp)"
SRC="minecraft/src/net/minecraft/src/GuiIngame.java"

[ -d jars ] || "$JAVA8" -jar "$RMCP" setup 1.2.5
[ -f "$SRC" ] || "$JAVA8" -jar "$RMCP" decompile
python tools/apply_hud.py
"$JAVA8" -jar "$RMCP" build client

mkdir -p dist
cp build/minecraft.zip dist/SimpleHUD-1.2.5.jar
echo "OK: dist/SimpleHUD-1.2.5.jar"
