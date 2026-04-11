/* * Haptic Feedback Integration for ESP32-S3
 * Using Adafruit_DRV2605 library
 */
#include <Wire.h>
#include "Adafruit_DRV2605.h"

Adafruit_DRV2605 drv;

void setupHaptics() {
  drv.begin();
  drv.selectLibrary(1);
  // I2C effects: 1 is a strong click, 7 is a "soft bump" for calm alerts
  drv.setMode(DRV2605_MODE_INTTRIG); 
}

void triggerStressAlert() {
  drv.setWaveform(0, 47); // "Sharp Tick" - alert for elevated stress
  drv.setWaveform(1, 0);  // End waveform
  drv.go();
}