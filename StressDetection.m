% Project: Vocal Prosody Biomarker Extraction 
[audio, fs] = audioread('vocal_sample_raw.wav');

% 1. Digital Band-Pass Filter (300Hz - 3kHz) [cite: 76]
bpFilter = designfilt('bandpassiir', 'FilterOrder', 8, ...
    'HalfPowerFrequency1', 300, 'HalfPowerFrequency2', 3000, 'SampleRate', fs);
cleanAudio = filter(bpFilter, audio);

% 2. Extract Pitch (Fundamental Frequency f0)
[f0, timeInstants] = pitch(cleanAudio, fs);

% 3. Calculate Jitter (Frequency Variation)
% High jitter often indicates vocal fold tension due to stress.
f0_diff = abs(diff(f0));
jitter = mean(f0_diff, 'omitnan') / mean(f0, 'omitnan');

% 4. Calculate Shimmer (Amplitude/Loudness Variation) [cite: 37]
% Shimmer measures the stability of the vocal fold vibration intensity.
[upperEnv, ~] = envelope(cleanAudio);
shimmer = mean(abs(diff(upperEnv))) / mean(upperEnv);

% 5. Logic for Stress Feedback [cite: 43]
fprintf('Jitter: %.4f | Shimmer: %.4f\n', jitter, shimmer);

if jitter > 0.02 || shimmer > 0.15 % Example thresholds
    disp('Result: Elevated Stress Level Detected');
else
    disp('Result: Calm State');
end