"""Idempotent applier for the SimpleHUD overlay patch (MC 1.2.5, vanilla).

Inserts an FPS / XYZ overlay block into GuiIngame.renderGameOverlay(),
right after the F3-debug block and before the record-playing block.
Colors: gray (section-7) labels/colons, white (section-f) values.

Usage:
    python tools/apply_hud.py [path/to/GuiIngame.java]

Defaults to minecraft/src/net/minecraft/src/GuiIngame.java relative to
the repo root (which doubles as the RetroMCP workspace directory).
"""

import pathlib
import sys

ANCHOR = (
    "\t\t\tGL11.glPopMatrix();\n"
    "\t\t}\n"
    "\n"
    "\t\tif(this.recordPlayingUpFor > 0) {"
)

BLOCK = (
    "\n"
    "\t\tif(!this.mc.gameSettings.showDebugInfo) {\n"
    "\t\t\tString hudFps = \"?\";\n"
    "\t\t\ttry {\n"
    "\t\t\t\thudFps = this.mc.debug.split(\" \")[0];\n"
    "\t\t\t} catch(Exception var49) {\n"
    "\t\t\t}\n"
    "\n"
    "\t\t\tvar8.drawStringWithShadow(\"\\u00a77FPS: \\u00a7f\" + hudFps, 2, 2, 16777215);\n"
    "\t\t\tString hudXyz = \"\\u00a77XYZ: \\u00a7f\" + MathHelper.floor_double(this.mc.thePlayer.posX) + \", \" + MathHelper.floor_double(this.mc.thePlayer.posY) + \", \" + MathHelper.floor_double(this.mc.thePlayer.posZ);\n"
    "\t\t\tvar8.drawStringWithShadow(hudXyz, 2, var7 - 10, 16777215);\n"
    "\t\t}\n"
)


def main() -> int:
    if len(sys.argv) > 1:
        target = pathlib.Path(sys.argv[1])
    else:
        target = (
            pathlib.Path(__file__).resolve().parent.parent
            / "minecraft"
            / "src"
            / "net"
            / "minecraft"
            / "src"
            / "GuiIngame.java"
        )
    raw = target.read_bytes()
    newline = "\r\n" if b"\r\n" in raw else "\n"
    text = raw.decode("utf-8").replace("\r\n", "\n")

    if "hudFps" in text:
        print("HUD patch already applied, nothing to do.")
        return 0
    if ANCHOR not in text:
        print("ERROR: anchor block not found in GuiIngame.java", file=sys.stderr)
        return 1

    replacement = (
        "\t\t\tGL11.glPopMatrix();\n"
        "\t\t}\n"
        + BLOCK
        + "\n"
        + "\t\tif(this.recordPlayingUpFor > 0) {"
    )
    text = text.replace(ANCHOR, replacement, 1)
    target.write_bytes(text.replace("\n", newline).encode("utf-8"))
    print(f"HUD patch applied to {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
