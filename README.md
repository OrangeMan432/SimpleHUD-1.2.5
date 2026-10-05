# SimpleHUD 1.2.5

Vanilla Minecraft 1.2.5 HUD overlay: `FPS: <fps>` top-left, `XYZ: <x>, <y>, <z>`
bottom-left. No Forge/ModLoader — a single patched `GuiIngame` class packaged
as a MultiMC "Add to minecraft.jar" patch jar.

Colors: labels/colons gray (`§7`), values white (`§f`). Hidden while the F3
debug screen is open.

## Use

1. MultiMC instance with vanilla **1.2.5**
2. Edit Instance → Version tab → **Add to Minecraft.jar**
3. Pick `dist/SimpleHUD-1.2.5.jar`

## Build

Prerequisites: **Java 8** (RetroMCP needs it), **Python 3**, and
[RetroMCP-Java](https://github.com/MCPHackers/RetroMCP-Java) cloned next to
this repo with its `build` task run (provides `RetroMCP-CLI-all.jar`).
Alternatively drop that jar into `tools/` or set `RETROMCP_JAR`.

```sh
./build.sh        # Git Bash / Linux
# or
build.bat         # cmd
```

The repo root doubles as the RetroMCP workspace: the script runs
`setup 1.2.5` → `decompile` (skipped if already done), applies the HUD patch
via `tools/apply_hud.py`, then `build client` and copies the result to
`dist/SimpleHUD-1.2.5.jar`.

All RetroMCP working dirs (`minecraft/`, `jars/`, `build/`, …) are git-ignored;
tracked sources are just the patch applier, the build scripts, and the README.

## How it works

`tools/apply_hud.py` inserts a 12-line block into
`GuiIngame.renderGameOverlay()`, after the F3-debug block:

```java
if(!this.mc.gameSettings.showDebugInfo) {
    String hudFps = "?";
    try {
        hudFps = this.mc.debug.split(" ")[0]; // "60 fps, ..." -> "60"
    } catch(Exception var49) {
    }

    var8.drawStringWithShadow("§7FPS: §f" + hudFps, 2, 2, 16777215);
    String hudXyz = "§7XYZ: §f" + MathHelper.floor_double(this.mc.thePlayer.posX) + ", " + ...;
    var8.drawStringWithShadow(hudXyz, 2, var7 - 10, 16777215);
}
```

`§` codes are written as `\u00a7` escapes so the patch is encoding-safe.
