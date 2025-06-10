%% EMG Signal Analysis - Main Runner Script
% 
% This script demonstrates how to use the EMG signal processing function
% for analysing muscle activity data.
%
% Author: Adil Wahab Bhatti
% Date: 2025-06-10
% Version: 2.0
%
% Instructions:
% 1. Ensure that emg_signal_processor.m is in your MATLAB path
% 2. Place your EMG data files (emgdata1.mat to emgdata6.mat) in the same directory
% 3. Run this script to perform the analysis

%% Clear workspace and command window
clear; clc; close all;

fprintf('EMG Signal Analysis Runner\n');
fprintf('==========================\n\n');

%% Option 1: Auto-detect and process all EMG datasets with PNG generation
fprintf('1. Auto-detecting EMG datasets in data/ folder...\n');

% Set data folder path
data_folder = 'data';
if ~exist(data_folder, 'dir')
    fprintf('✗ Data folder "%s" not found. Creating it...\n', data_folder);
    mkdir(data_folder);
    fprintf('  Please place your EMG data files in the "%s" folder and run again.\n\n', data_folder);
else
    % Find all EMG data files
    emg_files = dir(fullfile(data_folder, 'emgdata*.mat'));
    
    if isempty(emg_files)
        fprintf('✗ No EMG data files found in "%s" folder.\n', data_folder);
        fprintf('  Expected files: emgdata1.mat, emgdata2.mat, etc.\n\n');
    else
        fprintf('✓ Found %d EMG data files:\n', length(emg_files));
        for i = 1:length(emg_files)
            fprintf('  - %s\n', emg_files(i).name);
        end
        fprintf('\n');
    end
end

%% Option 2: Batch process all detected datasets WITH individual PNG plots
fprintf('2. Processing all datasets with PNG generation...\n');
try
    results = struct();
    
    if exist('emg_files', 'var') && ~isempty(emg_files)
        for i = 1:length(emg_files)
            dataset_path = fullfile(data_folder, emg_files(i).name);
            [~, dataset_name, ~] = fileparts(emg_files(i).name);
            
            fprintf('   Processing %s... ', emg_files(i).name);
            
            try
                % Process WITH plotting enabled (invisible PNG generation)
                [activity, accuracy, cm] = emg_signal_processor(dataset_path, true);
                
                % Extract dataset number for results storage
                dataset_num = regexp(dataset_name, '\d+', 'match');
                if ~isempty(dataset_num)
                    field_name = sprintf('dataset%s', dataset_num{1});
                else
                    field_name = dataset_name;
                end
                
                results.(field_name) = struct(...
                    'filename', emg_files(i).name, ...
                    'activity', activity, ...
                    'accuracy', accuracy, ...
                    'confusion_matrix', cm);
                
                if ~isnan(accuracy)
                    fprintf('✓ (Accuracy: %.1f%%)\n', accuracy * 100);
                else
                    fprintf('✓ (No target data)\n');
                end
                
            catch ME
                fprintf('✗ (Error: %s)\n', ME.message);
                if ~isempty(dataset_num)
                    field_name = sprintf('dataset%s', dataset_num{1});
                else
                    field_name = dataset_name;
                end
                results.(field_name) = struct('error', ME.message, 'filename', emg_files(i).name);
            end
        end
        
        fprintf('\n✓ Batch processing with PNG generation completed\n\n');
    else
        fprintf('✗ No datasets to process\n\n');
    end
    
catch ME
    fprintf('✗ Error in batch processing: %s\n\n', ME.message);
end

%% Option 3: Display summary results
fprintf('3. Summary of Results:\n');
fprintf('----------------------\n');

if exist('results', 'var')
    accuracies = [];
    
    for i = 1:6
        field_name = sprintf('dataset%d', i);
        if isfield(results, field_name) && isfield(results.(field_name), 'accuracy')
            acc = results.(field_name).accuracy;
            if ~isnan(acc)
                fprintf('Dataset %d: Accuracy = %.2f%%\n', i, acc * 100);
                accuracies = [accuracies, acc];
            else
                fprintf('Dataset %d: No target data available\n', i);
            end
        else
            fprintf('Dataset %d: Processing failed\n', i);
        end
    end
    
    if ~isempty(accuracies)
        fprintf('\nOverall Statistics:\n');
        fprintf('  - Mean Accuracy: %.2f%%\n', mean(accuracies) * 100);
        fprintf('  - Std Accuracy:  %.2f%%\n', std(accuracies) * 100);
        fprintf('  - Best Result:   %.2f%% (Dataset %d)\n', ...
                max(accuracies) * 100, find(accuracies == max(accuracies), 1));
        fprintf('  - Worst Result:  %.2f%% (Dataset %d)\n', ...
                min(accuracies) * 100, find(accuracies == min(accuracies), 1));
    end
end

%% Option 4: Create comparison plot for all detected datasets
fprintf('\n4. Creating comparison visualisation...\n');

if exist('results', 'var') && ~isempty(fieldnames(results))
    try
        % Create an invisible figure comparing all datasets
        fig_comparison = figure('Visible', 'off', 'Position', [200 200 1400 800]);
        
        % Get all successful results
        field_names = fieldnames(results);
        successful_datasets = {};
        for i = 1:length(field_names)
            if isfield(results.(field_names{i}), 'activity')
                successful_datasets{end+1} = field_names{i};
            end
        end
        
        if ~isempty(successful_datasets)
            % Calculate subplot layout
            n_datasets = length(successful_datasets);
            n_cols = min(3, n_datasets);
            n_rows = ceil(n_datasets / n_cols);
            
            for i = 1:length(successful_datasets)
                field_name = successful_datasets{i};
                filename = results.(field_name).filename;
                
                % Load the original data for the time vector
                try
                    data = load(fullfile(data_folder, filename));
                    sampT = 8e-3;
                    t = 0:sampT:(length(data.emg)-1)*sampT;
                    
                    subplot(n_rows, n_cols, i);
                    
                    % Plot filtered signal and activity
                    yyaxis left;
                    emg_filtered = lowpass(data.emg, 0.1, 1/sampT);
                    plot(t, emg_filtered, 'b-', 'LineWidth', 0.8);
                    ylabel('EMG Amplitude', 'Color', 'b');
                    
                    yyaxis right;
                    plot(t, results.(field_name).activity, 'r-', 'LineWidth', 2);
                    ylabel('Activity', 'Color', 'r');
                    ylim([0 1.2]);
                    
                    % Extract dataset number or use filename
                    dataset_num = regexp(field_name, '\d+', 'match');
                    if ~isempty(dataset_num)
                        plot_title = sprintf('Dataset %s', dataset_num{1});
                    else
                        plot_title = strrep(filename, '.mat', '');
                    end
                    
                    title(plot_title);
                    xlabel('Time (s)');
                    grid on;
                    
                catch
                    % Skip if can't load data
                    subplot(n_rows, n_cols, i);
                    text(0.5, 0.5, sprintf('Error loading\n%s', filename), ...
                         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
                    title(sprintf('Dataset %d (Error)', i));
                end
            end
            
            sgtitle(sprintf('EMG Activity Detection - All Datasets (%d found)', n_datasets), ...
                    'FontSize', 14, 'FontWeight', 'bold');
            
            % Create output directory and save comparison plot
            output_dir = 'emg_plots';
            if ~exist(output_dir, 'dir')
                mkdir(output_dir);
            end
            
            comparison_filename = fullfile(output_dir, 'all_datasets_comparison.png');
            print(fig_comparison, comparison_filename, '-dpng', '-r300');
            
            fprintf('✓ Comparison visualisation saved: %s\n', comparison_filename);
        else
            fprintf('✗ No successful datasets to compare\n');
        end
        
        % Close the figure
        close(fig_comparison);
        
    catch ME
        fprintf('✗ Error creating comparison plot: %s\n', ME.message);
        if exist('fig_comparison', 'var')
            close(fig_comparison);
        end
    end
else
    fprintf('✗ No results available for comparison\n');
end

%% Option 5: Save results
fprintf('\n5. Saving results...\n');
if exist('results', 'var')
    try
        % Save results to a .mat file
        save('emg_analysis_results.mat', 'results');
        fprintf('✓ Results saved to emg_analysis_results.mat\n');
        
        % Optionally save a summary report
        diary('emg_analysis_report.txt');
        fprintf('\nEMG Analysis Report\n');
        fprintf('Generated: %s\n', datestr(now));
        fprintf('===================\n\n');
        
        for i = 1:6
            field_name = sprintf('dataset%d', i);
            if isfield(results, field_name) && isfield(results.(field_name), 'accuracy')
                acc = results.(field_name).accuracy;
                if ~isnan(acc)
                    fprintf('Dataset %d: Accuracy = %.2f%%\n', i, acc * 100);
                end
            end
        end
        diary off;
        
        fprintf('✓ Report saved to emg_analysis_report.txt\n');
        
    catch ME
        fprintf('✗ Error saving results: %s\n', ME.message);
    end
end

fprintf('\n==========================\n');
fprintf('EMG Analysis Complete!\n');
fprintf('Check the generated figures and saved files.\n');
