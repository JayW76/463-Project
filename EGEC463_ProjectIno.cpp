/*
 * Project: Neck-Worn Wearable for Voice-Based Stress Analysis
 * Hardware: ESP32-S3, INMP441 MEMS Microphone, DRV2605L Haptic Driver
 */

#include <driver/i2s.h>
#include <Wire.h>
#include "Adafruit_DRV2605.h"

// I2S Mic Pins
#define I2S_WS 15
#define I2S_SD 16
#define I2S_SCK 14
#define I2S_PORT I2S_NUM_0
#define BUFFER_LEN 512

// DRV2605L I2C Pins
#define I2C_SDA 8
#define I2C_SCL 9

Adafruit_DRV2605 drv;

void triggerStressAlert() {
  drv.setWaveform(0, 47);  // sharp click
  drv.setWaveform(1, 0);   // end waveform
  drv.go();
}

void setup() {
  Serial.begin(921600);
  delay(1000);

  // Start I2C for DRV2605L
  Wire.begin(I2C_SDA, I2C_SCL);

  if (!drv.begin()) {
    Serial.println("DRV2605L not found");
  } else {
    drv.selectLibrary(1);
    drv.setMode(DRV2605_MODE_INTTRIG);
    Serial.println("DRV2605L_READY");
  }

  // I2S Configuration
  const i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
    .sample_rate = 16000,
    .bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,
    .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
    .communication_format = I2S_COMM_FORMAT_STAND_I2S,
    .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
    .dma_buf_count = 8,
    .dma_buf_len = BUFFER_LEN,
    .use_apll = false,
    .tx_desc_auto_clear = false,
    .fixed_mclk = 0
  };

  const i2s_pin_config_t pin_config = {
    .bck_io_num = I2S_SCK,
    .ws_io_num = I2S_WS,
    .data_out_num = -1,
    .data_in_num = I2S_SD
  };

  esp_err_t err;

  err = i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL);
  if (err != ESP_OK) {
    Serial.println("I2S driver install failed");
    while (true);
  }

  err = i2s_set_pin(I2S_PORT, &pin_config);
  if (err != ESP_OK) {
    Serial.println("I2S pin setup failed");
    while (true);
  }

  i2s_zero_dma_buffer(I2S_PORT);

  Serial.println("ESP32_READY");
}

void loop() {
  int32_t samples[BUFFER_LEN];
  size_t bytes_read = 0;

  esp_err_t result = i2s_read(
    I2S_PORT,
    samples,
    sizeof(samples),
    &bytes_read,
    portMAX_DELAY
  );

  if (result == ESP_OK && bytes_read > 0) {
    int samples_read = bytes_read / sizeof(int32_t);

    for (int i = 0; i < samples_read; i++) {
      Serial.println(samples[i]);
    }
  }

  if (Serial.available() > 0) {
    char command = Serial.read();

    if (command == 'S') {
      triggerStressAlert();
      Serial.println("HAPTIC_ALERT_TRIGGERED");
    }
  }
}

