#!/system/bin/sh
# Magisk module install-time script

ui_print "- Installing Fingerprint Sleep on Screen Off"
ui_print "- Freezes fingerprint HAL when screen is off"
ui_print "- Eliminates IRQ storm from Silead sensor"

# Set executable permission on service script
set_perm "$MODPATH/service.sh" 0 0 0755
