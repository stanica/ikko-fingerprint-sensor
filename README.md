# Fingerprint Sleep on Screen Off

A Magisk module that freezes the fingerprint HAL when the screen is off, eliminating the Silead sensor IRQ storm and saving battery.

## Background

IKKO MindOne devices use a Silead fingerprint sensor (`silfp`) whose HAL enters "nav mode" (wake-on-touch) whenever the screen turns off. This causes a continuous IRQ storm (~174 interrupts per 35 seconds) that wastes battery even when the device is idle in a pocket.

## How it works

- Listens for `screen_toggled` events via Android's logcat event buffer — **zero polling**
- **Screen off**: Sends `SIGSTOP` to the fingerprint HAL process, fully freezing the sensor (zero IRQs, zero wakelocks)
- **Screen on**: Sends `SIGCONT` to resume the HAL, restoring fingerprint unlock
- Automatically re-resolves the HAL PID if the process restarts

Fingerprint templates are preserved across freeze/unfreeze cycles — no re-enrollment needed.

## Requirements

- Rooted device with [Magisk](https://github.com/topjohnwu/Magisk) installed
- IKKO MindOne (tested on firmware v2.112.5.92)

## Installation

1. Download `magisk_fp_sleep.zip` from the [Releases](../../releases) page
2. Open the Magisk app → Modules → Install from storage
3. Select the downloaded zip and flash it
4. Reboot

## Verified on device

| Metric | Screen off (frozen) | Screen on (unfrozen) |
|--------|-------------------|---------------------|
| silfp IRQs | 0 / 5s | Normal |
| Wakelocks | 0 fingerprint-related | Normal |
| Fingerprint unlock | Disabled | Works |

## Uninstall

Remove the module in the Magisk app and reboot.

## License

MIT
