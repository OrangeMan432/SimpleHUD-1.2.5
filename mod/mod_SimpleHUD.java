import net.minecraft.client.Minecraft;
import net.minecraft.src.MathHelper;
import net.minecraft.src.ScaledResolution;

/**
 * SimpleHUD for Minecraft 1.2.5 + ModLoader (also runs under Forge, which
 * includes ModLoader API support and discovers jar-embedded mod_ classes).
 *
 * Shows "FPS: <fps>" top-left and "XYZ: <x>, <y>, <z>" bottom-left, and
 * prints death coordinates to the local chat on death. Client-side only:
 * nothing is ever sent to the server.
 */
public class mod_SimpleHUD extends BaseMod
{
    private boolean hudDeathSent = false;

    public String getVersion()
    {
        return "SimpleHUD 1.0";
    }

    public void load()
    {
        ModLoader.setInGameHook(this, true, false);
    }

    public boolean onTickInGame(float partialTick, Minecraft mc)
    {
        if (mc.thePlayer == null || mc.theWorld == null)
        {
            return true;
        }

        if (mc.thePlayer.getHealth() <= 0)
        {
            if (!hudDeathSent)
            {
                hudDeathSent = true;
                String hudDeath = "\u00a77Died at \u00a7f" + MathHelper.floor_double(mc.thePlayer.posX) + ", " + MathHelper.floor_double(mc.thePlayer.posY) + ", " + MathHelper.floor_double(mc.thePlayer.posZ);
                mc.thePlayer.addChatMessage(hudDeath);
            }
        }
        else
        {
            hudDeathSent = false;
        }

        if (mc.currentScreen != null || mc.gameSettings.showDebugInfo)
        {
            return true;
        }

        String hudFps = "?";
        try
        {
            hudFps = mc.debug.split(" ")[0];
        }
        catch (Exception e)
        {
        }
        mc.fontRenderer.drawStringWithShadow("\u00a77FPS: \u00a7f" + hudFps, 2, 2, 16777215);

        ScaledResolution sr = new ScaledResolution(mc.gameSettings, mc.displayWidth, mc.displayHeight);
        String hudXyz = "\u00a77XYZ: \u00a7f" + MathHelper.floor_double(mc.thePlayer.posX) + ", " + MathHelper.floor_double(mc.thePlayer.posY) + ", " + MathHelper.floor_double(mc.thePlayer.posZ);
        mc.fontRenderer.drawStringWithShadow(hudXyz, 2, sr.getScaledHeight() - 10, 16777215);

        return true;
    }
}
