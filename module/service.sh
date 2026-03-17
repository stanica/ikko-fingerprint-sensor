#!/system/bin/sh
# fp_sleep Magisk service script
# Monitors screen state and freezes/unfreezes the fingerprint HAL process.
#
# Zero polling — blocks on logcat ring buffer for screen_toggled events.
#
# Screen off: SIGSTOP the HAL (sensor completely dead, zero IRQs)
# Screen on:  SIGCONT the HAL (fingerprint unlock works normally)

LOG="/data/local/tmp/fp_sleep.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"
}

log "=== fp_sleep service starting ==="

# Wait for boot to complete
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

log "Boot completed"

# Re-register QS tile if toggle app is installed (fixes stale tile after reboot)
if pm list packages 2>/dev/null | grep -q com.ikko.fpsleep; then
    cmd statusbar remove-tile 'custom(com.ikko.fpsleep/.FpSleepTile)' 2>/dev/null
    cmd statusbar add-tile 'custom(com.ikko.fpsleep/.FpSleepTile)' 2>/dev/null
    log "QS tile re-registered"
fi

log "Waiting for HAL..."

# Find the fingerprint HAL PID
find_hal_pid() {
    /system/bin/ps -A -o PID,ARGS 2>/dev/null | grep 'fingerprint@2.1' | grep -v grep | awk '{print $1}' | head -1
}

# Retry until HAL is up (may take a while after boot)
HAL_PID=""
for i in $(seq 1 30); do
    HAL_PID=$(find_hal_pid)
    [ -n "$HAL_PID" ] && break
    sleep 2
done
if [ -z "$HAL_PID" ]; then
    log "ERROR: Cannot find fingerprint HAL process after 60s"
    exit 1
fi
log "Fingerprint HAL PID: $HAL_PID"

# Apply initial state
dumpsys power 2>/dev/null | grep -q "Display Power: state=ON"
if [ $? -ne 0 ]; then
    kill -STOP "$HAL_PID"
    log "Screen OFF at start - HAL frozen (PID $HAL_PID)"
else
    log "Screen ON at start"
fi

log "Listening on logcat screen_toggled (zero polling)"

# Main loop: block on logcat for screen_toggled events
# screen_toggled: 0 = screen off, 1 = screen on
logcat -b events -s screen_toggled -v raw -T 1 2>/dev/null | while IFS= read -r line; do
    # Raw format outputs just "0" or "1"
    case "$line" in
        0)
            # Skip if disabled via toggle
            [ -f "/data/local/tmp/fp_sleep_disabled" ] && continue

            # Verify HAL is still alive
            if ! kill -0 "$HAL_PID" 2>/dev/null; then
                HAL_PID=$(find_hal_pid)
                if [ -z "$HAL_PID" ]; then
                    log "ERROR: Cannot find fingerprint HAL"
                    continue
                fi
                log "New HAL PID: $HAL_PID"
            fi
            kill -STOP "$HAL_PID"
            log "Screen OFF - HAL frozen (PID $HAL_PID)"
            ;;
        1)
            if ! kill -0 "$HAL_PID" 2>/dev/null; then
                HAL_PID=$(find_hal_pid)
                if [ -z "$HAL_PID" ]; then
                    log "ERROR: Cannot find fingerprint HAL"
                    continue
                fi
                log "New HAL PID: $HAL_PID"
            fi
            kill -CONT "$HAL_PID"
            log "Screen ON - HAL unfrozen (PID $HAL_PID)"
            ;;
    esac
done
