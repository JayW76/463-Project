// Check for incoming feedback from MATLAB
if (Serial.available() > 0) {
  char command = Serial.read();
  
  if (command == 'S') { // 'S' for Stress detected
    // Trigger the Vibration Motor 
    drv.setWaveform(0, 47); // Sharp Alert pattern
    drv.setWaveform(1, 0);  // End
    drv.go();
    Serial.println("Haptic Alert Triggered");
  } else if (command == 'C') { // 'C' for Calm
    // No action or a soft "pulse" to confirm monitoring
  }
}