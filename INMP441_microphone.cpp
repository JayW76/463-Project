/*
* The following code configures the INMP441 microphone using the I2S (Inter-IC Sound) protocol. 
* It captures raw audio data and transmits it over Serial to MATLAB for analysis.
*/

/*
 * Project: Neck-Worn Wearable for Voice-Based Stress Analysis
 * Hardware: ESP32-S3, INMP441 MEMS Microphone
 */

#include <driver/i2s.h>

// I2S Pin Configuration
#define I2S_WS 15
#define I2S_SD 16
#define I2S_SCK 14
#define I2S_PORT I2S_NUM_0
#define BUFFER_LEN 1024

void setup() {
  Serial.begin(115200);
  
  // I2S Configuration
  const i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
    .sample_rate = 16000, // 16kHz sampling rate for voice
    .bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,
    .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
    .communication_format = I2S_COMM_FORMAT_STAND_I2S,
    .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
    .dma_buf_count = 8,
    .dma_buf_len = BUFFER_LEN,
    .use_apll = false
  };

  const i2s_pin_config_t pin_config = {
    .bck_io_num = I2S_SCK,
    .ws_io_num = I2S_WS,
    .data_out_num = -1, // Not used
    .data_in_num = I2S_SD
  };

  i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL);
  i2s_set_pin(I2S_PORT, &pin_config);
}

void loop() {
  int32_t samples[BUFFER_LEN];
  size_t bytes_read;

  // Read data from I2S
  i2s_read(I2S_PORT, &samples, sizeof(samples), &bytes_read, portMAX_DELAY);

  // Send raw data to Serial for MATLAB processing
  if (bytes_read > 0) {
    for (int i = 0; i < bytes_read / 4; i++) {
      Serial.println(samples[i]);
    }
  }
}