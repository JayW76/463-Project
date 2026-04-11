% MATLAB Signal Processing Script
% This script handles the digital band-pass filtering (300Hz–3kHz) mentioned in your risks section 
% and extracts the fundamental frequency (pitch), a key biomarker for stress.

% Project: Voice-Based Stress Analysis Preprocessing
% Purpose: Filter noise and extract vocal prosody features

fs = 16000; % Sampling frequency matching ESP32
duration = 5; % 5-second window

% 1. Data Acquisition (Simulated or Serial)
% Replace 'COM3' with your ESP32 port
% s = serialport('COM3', 115200);
% rawData = read(s, fs * duration, "int32");

% 2. Digital Band-Pass Filter (300Hz - 3kHz) [cite: 76]
bpFilter = designfilt('bandpassiir', 'FilterOrder', 8, ...
    'HalfPowerFrequency1', 300, 'HalfPowerFrequency2', 3000, ...
    'SampleRate', fs);
filteredAudio = filter(bpFilter, double(rawData));

% 3. Feature Extraction: Pitch (Vocal Prosody) [cite: 37, 55]
[f0, idx] = pitch(filteredAudio, fs);

% 4. Visualization
subplot(2,1,1);
plot(filteredAudio);
title('Filtered Vocal Signal (300Hz-3kHz)');
xlabel('Samples'); ylabel('Amplitude');

subplot(2,1,2);
plot(f0);
title('Vocal Pitch Tracking (F0)');
xlabel('Frame Index'); ylabel('Frequency (Hz)');

% 5. Simple Stress Logic
avgPitch = mean(f0, 'omitnan');
if avgPitch > threshold % You must calibrate this threshold
    disp('Feedback: Elevated Stress Detected'); [cite: 43]
else
    disp('Feedback: Calm State'); [cite: 43]
end