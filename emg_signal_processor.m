function [emg_t, accuracy, confusion_matrix] = emg_signal_processor(dataset_name, plot_results)
% EMG Signal Processing and Activity Detection
% 
% This function processes EMG signals to detect muscle activity using
% adaptive baseline thresholding with median filtering.
%
% Author: Adil Wahab Bhatti
% Date: 2025-06-10
% Version: 2.0
%
% Inputs:
%   dataset_name - String specifying the dataset file (e.g., 'emgdata1.mat')
%   plot_results - Boolean flag to enable/disable plotting (default: true)
%
% Outputs:
%   emg_t - Binary signal indicating detected muscle activity
%   accuracy - Classification accuracy compared to target signal
%   confusion_matrix - Confusion matrix for performance evaluation
%
% Usage Example:
%   [activity, acc, cm] = emg_signal_processor('emgdata1.mat', true);
%
% Dependencies:
%   - Signal Processing Toolbox (for lowpass filter)
%   - Statistics and Machine Learning Toolbox (for confusionmat)

    % Input validation and default parameters
    if nargin < 1
        error('Dataset name is required');
    end
    if nargin < 2
        plot_results = true;
    end
    
    try
        % Load the specified dataset (handle both direct paths and data folder)
        if exist(dataset_name, 'file')
            data = load(dataset_name);
        elseif exist(fullfile('data', dataset_name), 'file')
            data = load(fullfile('data', dataset_name));
        else
            error('Dataset file not found in current directory or data/ folder');
        end
        
        fprintf('Successfully loaded %s\n', dataset_name);
    catch ME
        error('Failed to load dataset %s: %s', dataset_name, ME.message);
    end
    
    %% Signal Processing Parameters
    % These parameters are optimised based on EMG signal characteristics
    SAMPLING_PERIOD = 8e-3;        % 8ms sampling period
    FILTER_ORDER = 100;            % Filter order (not used with lowpass)
    CUTOFF_FREQUENCY = 0.1;        % 0.1 Hz cutoff for low-pass filter
    
    % Activity detection parameters
    DETECTION_WINDOW = 100;        % Samples for activity detection
    BASELINE_WINDOW = 500;         % Samples for baseline estimation
    MEAN_THRESHOLD = 1.05;         % Threshold multiplier for mean
    MAX_THRESHOLD = 1.2;           % Threshold multiplier for maximum
    
    %% Signal Preprocessing
    emg = data.emg;
    signal_length = length(emg);
    sampling_frequency = 1 / SAMPLING_PERIOD;
    end_time = (signal_length - 1) * SAMPLING_PERIOD;
    time_vector = 0:SAMPLING_PERIOD:end_time;
    
    % Apply low-pass filter to remove high-frequency noise
    emg_filtered = lowpass(emg, CUTOFF_FREQUENCY, sampling_frequency);
    
    % Initialize output signal
    emg_activity = zeros(1, signal_length);
    
    %% Activity Detection Algorithm
    % Use sliding window approach with adaptive baseline
    detection_half_window = floor(DETECTION_WINDOW / 2);
    baseline_half_window = floor(BASELINE_WINDOW / 2);
    
    % Process signal with sufficient margin to avoid boundary effects
    start_idx = baseline_half_window + 10;
    end_idx = signal_length - baseline_half_window - 10;
    
    fprintf('Processing signal from sample %d to %d...\n', start_idx, end_idx);
    
    for i = start_idx:end_idx
        % Calculate adaptive baseline using median of wider window
        baseline_start = max(1, i - baseline_half_window);
        baseline_end = min(signal_length, i + baseline_half_window);
        baseline_value = median(emg_filtered(baseline_start:baseline_end));
        
        % Calculate statistics for detection window
        detection_start = max(1, i - detection_half_window);
        detection_end = min(signal_length, i + detection_half_window);
        window_mean = mean(emg_filtered(detection_start:detection_end));
        window_max = max(emg_filtered(detection_start:detection_end));
        
        % Apply dual-threshold detection criteria
        if (window_mean > baseline_value * MEAN_THRESHOLD) && ...
           (window_max > baseline_value * MAX_THRESHOLD)
            % Mark entire detection window as active
            emg_activity(detection_start:detection_end) = 1;
        end
    end
    
    %% Performance Evaluation
    accuracy = NaN;
    confusion_matrix = [];
    
    if isfield(data, 'target')
        target = data.target;
        
        % Ensure signals have the same length
        min_length = min(length(target), length(emg_activity));
        target = target(1:min_length);
        emg_activity = emg_activity(1:min_length);
        
        % Calculate confusion matrix and accuracy
        confusion_matrix = confusionmat(target, emg_activity);
        accuracy = sum(diag(confusion_matrix)) / sum(confusion_matrix(:));
        
        fprintf('Classification Accuracy: %.2f%%\n', accuracy * 100);
        
        % Display confusion matrix statistics
        if size(confusion_matrix, 1) == 2 && size(confusion_matrix, 2) == 2
            tn = confusion_matrix(1,1); fp = confusion_matrix(1,2);
            fn = confusion_matrix(2,1); tp = confusion_matrix(2,2);
            
            precision = tp / (tp + fp);
            recall = tp / (tp + fn);
            f1_score = 2 * (precision * recall) / (precision + recall);
            
            fprintf('Precision: %.3f, Recall: %.3f, F1-Score: %.3f\n', ...
                    precision, recall, f1_score);
        end
    else
        fprintf('No target signal found for accuracy evaluation\n');
    end
    
    %% Visualization
    if plot_results
        create_plots(time_vector, emg_filtered, emg_activity, data, dataset_name);
    end
    
    % Return processed signal
    emg_t = emg_activity;
end

function create_plots(time_vector, emg_filtered, emg_activity, data, dataset_name)
    % Create comprehensive visualization of results and save to PNG
    
    % Create invisible figure for batch processing
    fig = figure('Visible', 'off', 'Position', [100 100 1200 800]);
    
    try
        % Plot 1: Filtered signal
        subplot(3, 2, 1);
        plot(time_vector, emg_filtered, 'b-', 'LineWidth', 1);
        title(sprintf('Filtered EMG Signal - %s', strrep(dataset_name, '_', '\_')));
        xlabel('Time (s)');
        ylabel('Amplitude (AD Units)');
        grid on;
        
        % Plot 2: Detected activity
        subplot(3, 2, 2);
        plot(time_vector, emg_activity, 'r-', 'LineWidth', 2);
        title('Detected Muscle Activity');
        xlabel('Time (s)');
        ylabel('Activity State');
        ylim([-0.1 1.1]);
        grid on;
        
        % Plot 3: Comparison with target (if available)
        if isfield(data, 'target')
            subplot(3, 2, 3);
            hold on;
            plot(time_vector, data.target, 'g-', 'LineWidth', 2, 'DisplayName', 'Target');
            plot(time_vector, emg_activity, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Detected');
            title('Activity Detection Comparison');
            xlabel('Time (s)');
            ylabel('Activity State');
            legend('show');
            ylim([-0.1 1.1]);
            grid on;
            hold off;
            
            % Plot 4: Confusion matrix
            subplot(3, 2, 4);
            confusion_matrix = confusionmat(data.target, emg_activity);
            confusionchart(confusion_matrix, {'Inactive', 'Active'}, ...
                          'RowSummary', 'row-normalized', ...
                          'ColumnSummary', 'column-normalized');
            title('Confusion Matrix');
        end
        
        % Plot 5: Signal with activity overlay
        subplot(3, 2, [5, 6]);
        yyaxis left;
        plot(time_vector, emg_filtered, 'b-', 'LineWidth', 1);
        ylabel('EMG Amplitude (AD Units)', 'Color', 'b');
        
        yyaxis right;
        area(time_vector, emg_activity * max(emg_filtered) * 0.3, ...
             'FaceAlpha', 0.3, 'FaceColor', 'r', 'EdgeColor', 'none');
        ylabel('Detected Activity', 'Color', 'r');
        
        title('EMG Signal with Activity Detection Overlay');
        xlabel('Time (s)');
        grid on;
        
        % Adjust layout
        sgtitle(sprintf('EMG Signal Analysis - %s', strrep(dataset_name, '_', '\_')), ...
                'FontSize', 14, 'FontWeight', 'bold');
        
        % Create output directory if it doesn't exist
        output_dir = 'emg_plots';
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        
        % Generate filename and save as PNG
        [~, filename, ~] = fileparts(dataset_name);
        output_filename = fullfile(output_dir, sprintf('%s_analysis.png', filename));
        
        % Save with high resolution
        print(fig, output_filename, '-dpng', '-r300');
        fprintf('  → Plot saved: %s\n', output_filename);
        
    catch ME
        fprintf('  ✗ Error creating plot: %s\n', ME.message);
    end
    
    % Always close the figure to prevent memory buildup
    close(fig);
end

%% Batch Processing Function
function batch_process_emg_datasets()
    % Process multiple EMG datasets (emgdata1.mat to emgdata6.mat)
    
    fprintf('Starting batch processing of EMG datasets...\n');
    fprintf('===========================================\n');
    
    results = struct();
    
    for i = 1:6
        dataset_name = sprintf('emgdata%d.mat', i);
        
        try
            fprintf('\nProcessing %s...\n', dataset_name);
            [activity, accuracy, cm] = emg_signal_processor(dataset_name, false);
            
            % Store results
            results.(sprintf('dataset%d', i)).activity = activity;
            results.(sprintf('dataset%d', i)).accuracy = accuracy;
            results.(sprintf('dataset%d', i)).confusion_matrix = cm;
            
            fprintf('✓ %s processed successfully\n', dataset_name);
            
        catch ME
            fprintf('✗ Failed to process %s: %s\n', dataset_name, ME.message);
            results.(sprintf('dataset%d', i)).error = ME.message;
        end
    end
    
    fprintf('\n===========================================\n');
    fprintf('Batch processing completed!\n');
    
    % Display summary
    fprintf('\nSummary of Results:\n');
    for i = 1:6
        field_name = sprintf('dataset%d', i);
        if isfield(results.(field_name), 'accuracy') && ~isnan(results.(field_name).accuracy)
            fprintf('Dataset %d: Accuracy = %.2f%%\n', i, results.(field_name).accuracy * 100);
        else
            fprintf('Dataset %d: No accuracy data available\n', i);
        end
    end
end
