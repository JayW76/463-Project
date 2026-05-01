%% EGEC 463: Vocal Stress Analysis Visualization
clear; clc; close all;

% --- 1. SETUP & FILE CHECK ---
current_script_path = fileparts(mfilename('fullpath'));
cd(current_script_path); 

filename = 'vocal_sample_raw.wav';
if ~isfile(filename)
    error('FILE NOT FOUND! Run the Python script first to record audio.');
end

% --- 2. DATA IMPORT & FILTERING ---
[audio, fs] = audioread(filename);
t = (0:length(audio)-1)/fs; % Time vector for plotting

% 8th Order Bandpass (300Hz - 3kHz) from Slide 6
bpFilter = designfilt('bandpassiir', 'FilterOrder', 8, ...
    'HalfPowerFrequency1', 300, 'HalfPowerFrequency2', 3000, ...
    'SampleRate', fs);
cleanAudio = filter(bpFilter, audio);

% --- 3. FEATURE EXTRACTION ---
% Extract Pitch (f0) and Envelope
[f0, f0_idx] = pitch(cleanAudio, fs);
upperEnv = envelope(cleanAudio, 100, 'rms');

% Calculate Jitter (Frequency Variation)
jitter = mean(abs(diff(f0)), 'omitnan') / mean(f0, 'omitnan');

% Calculate Shimmer (Amplitude Variation)
shimmer = mean(abs(diff(upperEnv))) / mean(upperEnv);

% --- 4. STRESS LOGIC & FEEDBACK ---
if jitter > 0.02 || shimmer > 0.15
    decision = 'S';
    statusStr = 'STRESS DETECTED';
    statusColor = [1 0.2 0.2]; % Reddish for stress
else
    decision = 'C';
    statusStr = 'CALM / NORMAL';
    statusColor = [0 1 1]; % Cyan for calm
end

% Send Command back to ESP32
try
    s = serialport('COM3', 921600);
    write(s, decision, "char");
    clear s; 
catch
    disp('Warning: Serial Port busy or disconnected.');
end

% --- 5. VISUALIZATION (Matches Presentation Slide 7) ---
figure('Color', 'k', 'Name', 'Vocal Biomarker Analysis');

% TOP PLOT: Filtered Waveform & Envelope
subplot(2,1,1);
plot(t, cleanAudio, 'Color', [0.5 0.5 0.5]); hold on; % Gray Waveform
plot(t, upperEnv, 'Color', [1 1 0], 'LineWidth', 1.5); % Yellow Envelope
title('Top Plot: Filtered Waveform & Amplitude Envelope', 'Color', 'w');
ylabel('Amplitude', 'Color', 'w');
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.2 0.2 0.2]);
legend('Filtered Audio', 'Shimmer Envelope', 'TextColor', 'w', 'Location', 'northeast');
grid on;

% BOTTOM PLOT: Pitch Tracking (F0)
subplot(2,1,2);
% Note: f0_idx converted to seconds for the X-axis
t_f0 = f0_idx / fs; 
plot(t_f0, f0, 'Color', [0 1 1], 'LineWidth', 2); 
title(['Bottom Plot: F0 Pitch Tracking - STATUS: ', statusStr], 'Color', statusColor);
ylabel('Frequency (Hz)', 'Color', 'w');
xlabel('Time (seconds)', 'Color', 'w');
ylim([min(f0)-20 max(f0)+20]); % Dynamic zoom on pitch
set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.2 0.2 0.2]);
grid on;

% Print stats to console
fprintf('\n--- RESULTS ---\n');
fprintf('Jitter:  %.4f (Threshold: 0.02)\n', jitter);
fprintf('Shimmer: %.4f (Threshold: 0.15)\n', shimmer);
fprintf('Status:  %s\n', statusStr);