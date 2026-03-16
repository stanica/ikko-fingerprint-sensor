package com.ikko.fpsleep;

import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;
import java.io.File;
import java.util.concurrent.TimeUnit;

public class FpSleepTile extends TileService {

    private static final String FLAG_FILE = "/data/local/tmp/fp_sleep_disabled";
    private Boolean cachedEnabled = null;

    private boolean isEnabled() {
        if (cachedEnabled != null) return cachedEnabled;
        // First check: use su to read file state
        try {
            Process p = Runtime.getRuntime().exec(new String[]{"su", "-c", "test -f " + FLAG_FILE});
            p.waitFor(5, TimeUnit.SECONDS);
            cachedEnabled = (p.exitValue() != 0);
        } catch (Exception e) {
            cachedEnabled = true;
        }
        return cachedEnabled;
    }

    private void runSu(String cmd) {
        try {
            Process p = Runtime.getRuntime().exec(new String[]{"su", "-c", cmd});
            p.waitFor(5, TimeUnit.SECONDS);
        } catch (Exception e) {
            // ignore
        }
    }

    @Override
    public void onStartListening() {
        cachedEnabled = null; // refresh from disk when panel opens
        updateTile();
    }

    @Override
    public void onClick() {
        boolean enabled = isEnabled();
        // Update state immediately
        cachedEnabled = !enabled;
        updateTile();
        // Run su command in background
        new Thread(() -> {
            if (enabled) {
                runSu("touch " + FLAG_FILE + " && " +
                    "pid=$(/system/bin/ps -A -o PID,ARGS | grep 'fingerprint@2.1' | grep -v grep | awk '{print $1}' | head -1) && " +
                    "[ -n \"$pid\" ] && kill -CONT $pid");
            } else {
                runSu("rm -f " + FLAG_FILE);
            }
        }).start();
    }

    private void updateTile() {
        Tile tile = getQsTile();
        if (tile == null) return;

        if (isEnabled()) {
            tile.setState(Tile.STATE_ACTIVE);
            tile.setLabel("Fingerprint");
            tile.setSubtitle("Auto-sleep");
        } else {
            tile.setState(Tile.STATE_INACTIVE);
            tile.setLabel("Fingerprint");
            tile.setSubtitle("Always on");
        }
        tile.updateTile();
    }
}
