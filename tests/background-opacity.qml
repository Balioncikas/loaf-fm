import QtQuick
import app.loaf

// Loaded by the Loaf binary so the registered types and font resources match
// the application. The Python runner supplies an isolated settings directory.
Item {
    LoafCore { id: core }
    Theme { id: theme }

    Timer {
        interval: 0
        running: true
        onTriggered: {
            theme.lowPowerSetting = "off";
            var expected = Number(core.get_setting("testExpectedOpacity"));
            function check(condition, message) {
                if (!condition)
                    throw new Error(message);
            }
            try {
                check(Math.abs(theme.windowBackground.a - expected) < 0.01,
                      "Saved opacity was not loaded or sanitized");
                theme.backgroundOpacity = 0.78;
                check(Math.abs(theme.windowBackground.a - 0.78) < 0.01,
                      "Changing opacity did not update the background");
                check(theme.textMain.a === 1 && theme.primary.a === 1
                      && theme.surfaceContainer.a === 1,
                      "Foreground or popup colors became translucent");
                check(Math.abs(theme.backdropSurface(theme.surfaceContainerLow).a
                               - (theme.containerAlphaFloor + (1 - theme.containerAlphaFloor) * 0.78)) < 0.01,
                      "Inset backgrounds should scale with the window opacity");
                theme.backgroundOpacity = 0.5;
                // The window's clear color is written into a premultiplied
                // buffer, so its RGB has to be scaled by the alpha as well.
                check(Math.abs(theme.windowBackground.r - theme.background.r * 0.5) < 0.01
                      && Math.abs(theme.windowBackground.a - 0.5) < 0.01,
                      "Window clear color is not premultiplied");
                theme.backgroundOpacity = 0.0;
                check(theme.windowBackground.a === 0
                      && theme.windowBackground.r === 0,
                      "0% opacity left a veil over the desktop");
                check(Math.abs(theme.backdropSurface(theme.surfaceContainerLow).a
                               - theme.containerAlphaFloor) < 0.01,
                      "0% opacity dropped text containers below the readability floor");
                theme.backgroundOpacity = 0.78;
                theme.lowPowerSetting = "on";
                check(theme.windowBackground.a === 1
                      && theme.backdropSurface(theme.surfaceContainerLow).a === 1,
                      "Low-power mode did not restore solid backgrounds");
                theme.lowPowerSetting = "off";
                check(Math.abs(theme.windowBackground.a - 0.78) < 0.01,
                      "Leaving low-power mode lost the preferred opacity");
                theme.backgroundOpacity = NaN;
                check(theme.windowBackground.a === 1, "Invalid opacity did not fall back to solid");
                theme.backgroundOpacity = 0.78;
                console.log("BACKGROUND_OPACITY_TEST_PASS");
                Qt.quit();
            } catch (error) {
                console.error("BACKGROUND_OPACITY_TEST_FAIL: " + error.message);
                Qt.quit();
            }
        }
    }
}
