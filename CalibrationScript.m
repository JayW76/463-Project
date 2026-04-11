% Project: Vocal Baseline Calibration
[audio, fs] = audioread('baseline_calm.wav');

% Standard filtering [cite: 76]
bpFilter = designfilt('bandpassiir', 'FilterOrder', 8, ...
    'HalfPowerFrequency1', 300, 'HalfPowerFrequency2', 3000, 'SampleRate', fs);
cleanAudio = filter(bpFilter, audio);

% Extract Pitch and Amplitude
[f0, ~] = pitch(cleanAudio, fs);
[upperEnv, ~] = envelope(cleanAudio);

% Calculate Baseline Biomarkers [cite: 55]
baselineJitter = mean(abs(diff(f0)), 'omitnan') / mean(f0, 'omitnan');
baselineShimmer = mean(abs(diff(upperEnv))) / mean(upperEnv);

% Save these values for comparison
save('user_baseline.mat', 'baselineJitter', 'baselineShimmer');
fprintf('Calibration Complete.\nBaseline Jitter: %.4f\nBaseline Shimmer: %.4f\n', ...
        baselineJitter, baselineShimmer);