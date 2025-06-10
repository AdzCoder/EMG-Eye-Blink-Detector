# EMG Signal Processing for Eye Blink Detection

MATLAB-based system for detecting eye blinks from EMG signals, designed for assistive communication devices.

## Features

- 🚀 **Adaptive Thresholding**  
  Smart baseline adjustment for reliable blink detection.
- 📊 **Performance Metrics**  
  Calculates accuracy, precision, recall, and F1-score.
- 📈 **Visualisation**  
  Automatically generates signal plots and confusion matrices.
- 🔄 **Batch Processing**  
  Supports simultaneous processing of multiple datasets.
- 📁 **Report Generation**  
  Saves results in `.mat` and `.txt` formats for further analysis.

## Quick Start

### Prerequisites
- **MATLAB R2018b** (minimum) or **R2020a+** (recommended)
- Toolboxes:
  - [Signal Processing Toolbox](https://www.mathworks.com/products/signal.html) (for `lowpass()`)
  - [Statistics and Machine Learning Toolbox](https://www.mathworks.com/products/statistics.html) (for `confusionmat`/`confusionchart`)

### Setup

1. Clone the repository and add it to your MATLAB path:
    ```matlab
    !git clone https://github.com/AdzCoder/EMG-Eye-Blink-Detector.git
    addpath(genpath('EMG-Eye-Blink-Detector'));
    ```

2. Create a data folder and add your EMG datasets (`emgdata1.mat` to `emgdata6.mat`):
    ```matlab
    mkdir('data')
    % Place your .mat files inside the 'data' folder
    ```

### Run Analysis

- To process a single dataset with plotting enabled:
    ```matlab
    [activity, accuracy, cm] = emg_signal_processor('data/emgdata1.mat', true);
    ```

- To batch process all datasets:
    ```matlab
    run_emg_analysis;
    ```

## Output Examples

- Filtered EMG signal with detected activity overlay (e.g., `emgdata1_analysis.png`)  
- Confusion matrix and performance metrics saved alongside data files  

## Project Team

- Group 10  
- University of Warwick, School of Engineering
- [ES197: Systems Modelling, Simulation and Computation (22/23)](https://courses.warwick.ac.uk/modules/2022/ES197-15)

## Project Status

This project was developed as part of a coursework assignment and is provided for educational purposes. It is not actively maintained.

## License

MIT License — see the [LICENSE](LICENSE) file for details.
