# SimpleHUD 1.2.5

A ModLoader mod (`mod_SimpleHUD`) for Minecraft 1.2.5:

- `FPS: <fps>` top-left, `XYZ: <x>, <y>, <z>` bottom-left (hidden on F3)
- Death coordinates printed to the local chat (`Died at <x>, <y>, <z>`)

Colors: labels gray (`§7`), values white (`§f`). Client-side only — nothing
is ever sent to the server.

The jar contains **only** the mod class. No vanilla classes are edited, so it
is safe to stack on Forge instances (Forge discovers jar-embedded `mod_`
classes and provides the ModLoader API). Requires ModLoader 1.2.5, which
Forge already bundles.

## Use

1. MultiMC instance with **1.2.5** (+ ModLoader, or Forge)
2. Edit Instance → Version tab → **Add to Minecraft.jar**
3. Pick `dist/SimpleHUD-1.2.5.jar`

## Build

Prerequisites: **Java 8**, **curl**, **python3**, and
[RetroMCP-Java](https://github.com/MCPHackers/RetroMCP-Java) cloned next to
this repo with its `build` task run (provides `RetroMCP-CLI-all.jar`).
Alternatively drop that jar into `tools/` or set `RETROMCP_JAR`.

```sh
./build.sh        # Git Bash / Linux
# or
build.bat         # cmd
```

The repo root doubles as the RetroMCP workspace (vanilla sources are only
used as a compile classpath — nothing is patched). The script compiles
`mod/mod_SimpleHUD.java` against vanilla classes plus Risugami's ModLoader
API (auto-downloaded from MCArchive), remaps it to notch names with
tiny-remapper (auto-downloaded from Fabric/ Maven Central), and packages
`dist/SimpleHUD-1.2.5.jar`. A guard fails the build if the jar ever contains
anything but `mod_SimpleHUD.class`.

Sources tracked in git: `mod/`, build scripts, `tools/` (excluding the
download cache), README, LICENSE.

## How it works

`load()` registers a render hook via `ModLoader.setInGameHook(this, true,
false)`, so `onTickInGame` runs every frame. It draws the overlay with the
vanilla `FontRenderer`, and polls `getHealth()`: on the transition to 0 it
sends the death position to the local chat once (flag resets on respawn).

`§` codes are written as `\u00a7` escapes so the source is encoding-safe.
