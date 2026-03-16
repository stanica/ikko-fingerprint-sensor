package com.ikko.fpsleep;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        TextView tv = new TextView(this);
        tv.setPadding(48, 48, 48, 48);
        tv.setTextSize(16);
        tv.setText("Requesting root access...");
        setContentView(tv);

        new Thread(() -> {
            boolean granted = false;
            try {
                Process p = Runtime.getRuntime().exec(new String[]{"su", "-c", "id"});
                granted = (p.waitFor() == 0);
            } catch (Exception e) {
                // ignore
            }
            boolean result = granted;
            runOnUiThread(() -> {
                if (result) {
                    tv.setText("Root granted! You can now use the FP Sleep tile in Quick Settings.");
                    Toast.makeText(this, "Root access granted", Toast.LENGTH_SHORT).show();
                } else {
                    tv.setText("Root denied. Please grant root access in Magisk and try again.");
                    Toast.makeText(this, "Root access denied", Toast.LENGTH_SHORT).show();
                }
            });
        }).start();
    }
}
