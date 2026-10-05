#!/usr/bin/env bash
# Build dist/SimpleHUD-1.2.5.jar for Minecraft 1.2.5.
#
# The jar contains a single ModLoader mod class (mod_SimpleHUD): no vanilla
# classes are edited, so it is safe to add on top of Forge/MultiMC instances.
# It runs on vanilla + ModLoader and on Forge (which discovers jar-embedded
# mod_ classes and provides the ModLoader API).
#
# Repo root doubles as the RetroMCP workspace directory (compile classpath).
# Requires: Java 8, curl, python3 (zip handling).
set -euo pipefail
cd "$(dirname "$0")"

MODLOADER_URL="https://b2.mcarchive.net/file/mcarchive/219370a86a15bfef8ff91f51fdd151e99391b771759183b19f72197452a28b79/ModLoader%201.2.5.zip"
TR_BASE="https://maven.fabricmc.net/net/fabricmc"
CEN_BASE="https://repo1.maven.org/maven2"
REMAP_JARS="
tiny-remapper/0.14.1/tiny-remapper-0.14.1.jar
mapping-io/0.8.0/mapping-io-0.8.0.jar
tiny-mappings-parser/0.3.0+build.17/tiny-mappings-parser-0.3.0+build.17.jar
"

find_java8() {
  local cand="${JAVA8_HOME:-}"
  if [ -n "$cand" ]; then
    [ -d "$cand" ] && cand="$cand/bin/java"
    if [ -f "$cand" ] && [ -x "$cand" ]; then echo "$cand"; return 0; fi
  fi
  for cand in \
    "/c/Program Files/Java/openjdk-8u212-b03/bin/java.exe" \
    "$HOME/.jdks/openjdk-8u212-b03/bin/java.exe" \
    "/usr/lib/jvm/java-8-openjdk/bin/java"; do
    [ -f "$cand" ] && [ -x "$cand" ] && { echo "$cand"; return 0; }
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
PY=""
for cand in python3 python; do
  if [ -z "$PY" ] && command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import sys' >/dev/null 2>&1; then
    PY="$cand"
  fi
done
if [ -z "$PY" ]; then
  echo "ERROR: working python3/python not found." >&2
  exit 1
fi
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*|Windows*) SEP=";" ;;
  *) SEP=":" ;;
esac
JAVABIN="$(dirname "$JAVA8")"
JAVAC="$JAVABIN/javac"
JARTOOL="$JAVABIN/jar"
CACHE="tools/.cache"

# 1. Vanilla workspace (compile classpath only - nothing is patched)
[ -d jars ] || "$JAVA8" -jar "$RMCP" setup 1.2.5
[ -f minecraft/src/net/minecraft/src/GuiIngame.java ] || "$JAVA8" -jar "$RMCP" decompile
[ -f minecraft/bin/net/minecraft/client/Minecraft.class ] || "$JAVA8" -jar "$RMCP" recompile client

# 2. ModLoader API classes (compile-time only, never shipped)
mkdir -p "$CACHE/modloader"
if [ ! -f "$CACHE/modloader/BaseMod.class" ]; then
  [ -f "$CACHE/ModLoader-1.2.5.zip" ] || curl -sSL -o "$CACHE/ModLoader-1.2.5.zip" "$MODLOADER_URL"
  "$PY" -c "import zipfile; z=zipfile.ZipFile('$CACHE/ModLoader-1.2.5.zip'); z.extract('BaseMod.class','$CACHE/modloader'); z.extract('ModLoader.class','$CACHE/modloader')"
fi

# 3. tiny-remapper + deps (compile-time only, never shipped)
mkdir -p "$CACHE/remaplib"
for spec in $REMAP_JARS; do
  f="$CACHE/remaplib/${spec##*/}"
  [ -f "$f" ] || curl -sSL -o "$f" "$TR_BASE/$spec"
done
for a in asm asm-analysis asm-commons asm-tree asm-util; do
  f="$CACHE/remaplib/$a-9.10.1.jar"
  [ -f "$f" ] || curl -sSL -o "$f" "$CEN_BASE/org/ow2/asm/$a/9.10.1/$a-9.10.1.jar"
done
[ -f "$CACHE/remaplib/gson-2.11.0.jar" ] || curl -sSL -o "$CACHE/remaplib/gson-2.11.0.jar" "$CEN_BASE/com/google/code/gson/gson/2.11.0/gson-2.11.0.jar"
[ -f "$CACHE/remaplib/jsr305-3.0.2.jar" ] || curl -sSL -o "$CACHE/remaplib/jsr305-3.0.2.jar" "$CEN_BASE/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2.jar"

# 4. Compile the mod (MCP names)
rm -rf "$CACHE/modbuild" "$CACHE/modinput.jar"
mkdir -p "$CACHE/modbuild"
"$JAVAC" -encoding UTF-8 -cp "minecraft/bin${SEP}$CACHE/modloader" -d "$CACHE/modbuild" mod/mod_SimpleHUD.java

# 5. Package + remap to notch names (tiny-remapper merges into existing
# output, so the output jar must not exist beforehand)
rm -rf "$CACHE/modinput"
mkdir -p "$CACHE/modinput"
cp "$CACHE/modbuild/mod_SimpleHUD.class" "$CACHE/modinput/"
(cd "$CACHE/modinput" && "$JARTOOL" cfM ../modinput.jar mod_SimpleHUD.class)
mkdir -p dist
rm -f dist/SimpleHUD-1.2.5.jar
REMAPP_CP="$(echo "$CACHE"/remaplib/*.jar | tr ' ' "$SEP")"
"$JAVA8" -cp "$REMAPP_CP" net.fabricmc.tinyremapper.Main \
  "$CACHE/modinput.jar" dist/SimpleHUD-1.2.5.jar conf/mappings.tiny named client \
  "minecraft/bin" "$CACHE/modloader"

# 6. Guard: the jar must contain ONLY the mod class (never vanilla classes)
"$PY" -c "import zipfile,sys; n=zipfile.ZipFile('dist/SimpleHUD-1.2.5.jar').namelist(); sys.exit(0 if n==['mod_SimpleHUD.class'] else (print('UNEXPECTED JAR CONTENTS:',n),1))"
echo "OK: dist/SimpleHUD-1.2.5.jar"
