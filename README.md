# Outline of the Scripts in the Study

## Heartbeat-evoked potentials (HEPs) in folder Heartbeats

### main.m
- **Loading the EEG data that contains the ECG data.**
- **Cuting the data to the time frame during the SART experiment (events 91 and 199)**
- **Detecting Heartbeats**
  - Calls `detectHeartbeat.m`
  - Detects QRS complexes in the ECG data.
  - Plots ECG signal for manual verification.
  - Allows flipping the ECG signal and modifying `t` and `tn` variables to ensure accurate R peak detection.
  - Saves detected R peaks and their locations.
- **Adding Heartbeats as Events**
  - Calls `addHeartbeat.m`
  - Adds detected R peaks as events labeled '111' to the preprocessed EEG data.

- **Labelling Heartbeat Events with Self-Relatedness**
  - Looks into a 15-second window before each thought probe event.
  - Assigns the self-relatedness label of the thought probe to all heartbeat events within this timeframe.

- **Epoching and Categorizing Trials**
  - Epochs the EEG data into trials centered around the heartbeat events (from 100 ms before to 600 ms after the R-peaks).
  - Categorizes trials based on the self-relatedness labels: self-focused thought, non-self-focused thought, and 'other.'

- **Plotting HEPs to verify correctness after categorization**


## HEP pre-processing functions in folder Heartbeats

### CutContu_biosemi.m
- Cuts the EEG data to the relevant time frame marked by events 91 and 199.
- Prepares data for subsequent heartbeat detection and analysis.

### detectHeartbeat.m
- Detects QRS peaks in the ECG signal.
- Plots ECG signal for manual inspection to confirm accuracy.
- Allows manual adjustments (signal flipping, modifying `t` and `tn`) to check if all R peaks are captured.

### addHeartbeat.m
- Integrates detected R peaks as new events labeled '111' into the preprocessed EEG data.
- Essential for linking heartbeats to EEG data for HEP analysis.

## FieldTrip analysis in the FieldTrip Folder

### fieldtripHEP.m
- **Loads the previously saved EEG files, which include heartbeat events**

- **Epoching and Categorizing Trials**
  - Epochs the EEG data into trials centered around the heartbeat events (from 100 ms before to 600 ms after the R-peaks).
  - Categorizes trials based on the self-relatedness labels: self-focused thought, non-self-focused thought, and 'other.'

- **Time-Locked Analysis**
  - Conducts time-locked analysis on self-focused and non-self-focused thoughts using FieldTrip functions on the categorized EEG data to be used to analyze HEPs later.
  - The processed data is saved as `.mat` files, with separate files for self-focused and non-self-focused trials.

### clustering.m
- **HEP Plotting**
  - Loads the `.mat` files generated by `fieldtripdata.m`.
  - Creates plots of the HEPs for each electrode.

- **Cluster-Based Permutation Test**
  - Performs a statistical comparison between self-focused and non-self-focused trials using a cluster-based permutation test.
  - Plots the results of this test.

### fieldtripPower.m
- **Similar to `fieldtripdata.m`, loads the EEG data with the heartbeat events**
- **Epochs the EEG data around the heartbeat events and categorizes the trials based on the self-relatedness labels**
- **Preforms frequency analysis**:
  - Instead of time-locked analysis, this script conducts frequency analysis on the epoched EEG data to study brain oscillations.
  - The frequency analysis focuses on power spectra within specific frequency bands (theta, alpha, beta), examining changes in oscillatory activity related to self-focused versus non-self-focused thoughts.
  - Results of the frequency analysis are saved as `.mat` files for further analysis.

## Preparing and preforming the linear mixed effects models in the LME folder
  
### LMEAmplitudeData.m
- **Loads EEG data with the heartbeat events**:
- **Labeling and Epoching**:
  - Labels heartbeat events with self-relatedness labels as in previous scripts.
  - Epochs EEG data around heartbeat events and calculates the average HEP amplitude for selected channels.
- **Creating CSV for LME Models**:
  - Extracts HEP amplitudes and categorizes them by self-relatedness.
  - Saves the resulting data into a CSV file, which can be used for further analysis in R with LME models.

### LMEPowerData.m
- **Average and Plotting**:
  - Combines data from `.mat` created in `fieldtripPower.m` for different participants to create grand averages for self-focused and non-self-focused trials.
  - Plots the average HEPs for visual inspection.
- **Frequency Analysis**:
  - Conducts frequency analysis to extract power spectra for specific frequency bands and electrodes for each trial.
  - Saves the resulting power frequency data into a CSV file for subsequent analysis in R.
  
### LMEHep.Rmd
- **Data Preparation**:
  - Reads the HEP amplitude data from the CSV file created in `LMEAmplitudeData.m`
  - Data is transformed from wide to long format, with channels and thought conditions as separate variables.
  - The HEP amplitudes are log-transformed for analysis.

- **LME and post-hoc analysis**:
  - An LME model is fit for each channel, with `Thought`, `Fant`, and `Med` as fixed effects and `Subject_ID` as a random effect (can be adjusted though to include less/mroe fixed effects).
  - Post-hoc comparisons using Tukey's HSD are performed.
  - Bayes Factors are computed to compare models with and without interaction terms.
  - The script saves the coefficients, p-values, significance levels, post-hoc p-values, and Bayes Factors for each channel to a CSV file.
  - It also performs ANOVA comparisons between models of increasing complexity (e.g., adding interaction terms) and saves these results to a CSV file.

### LMEPower.Rmd
- **Data Preparation**:
  - Reads the brain oscillatory power data from the CSV file created in `LMEPowerData.m`
  - Data is transformed from wide to long format, with power values corresponding to specific frequency bands and EEG channels.
  - The data is log-transformed for analysis.

- **LME and post-hoc analysis**:
  - LME models are fit for each frequency band and channel combination, with `Thought` as the primary fixed effect and `Participant` as a random effect.
  - These models can be adjusted to include other fixed effects (`Group`, `Fant`, and `Med`)
  - Post-hoc comparisons are conducted to examine differences between self-focused and non-self-focused thoughts.
  - Bayes Factors are calculated to assess the strength of evidence for the fixed effects.
  - The script outputs the model coefficients, p-values, significance levels, post-hoc p-values, and Bayes Factors for each combination of frequency band and channel.
  - Results are saved to CSV files for further analysis.
  - It also performs ANOVA comparisons between models of increasing complexity (e.g., adding interaction terms).

### BayesPower.Rmd
- **Data Preparation**:
  - Reads the brain oscillatory power data from the CSV file created in `LMEPowerData.m`
  - Data is transformed from wide to long format, with power values corresponding to specific frequency bands and EEG channels.
  - The data is log-transformed for analysis.

- **Bayes Factor analysis**:
  - This file was created separately to perform all the Bayesian analyses for the models with the added interactions automatically, as they tend to take a significant amount of time to run. By setting up the script this way, you can run all the necessary Bayesian models in one go, without the need to manually adjust the code and rerun each model individually.
  - For each frequency band and channel combination, the script fits Bayesian models to evaluate the interaction effects between `Thought`, `Fant`, `Med`, and `Group`.
  - Bayes Factors are computed to compare models with and without specific interaction terms.
  - Bayes Factor results for each model are saved to CSV files, providing a measure of the strength of evidence for each interaction effect.
 
  
## Classification in `classification.ipynb` in the classification folder
- **Data Preparation**:
  - Reads the brain oscillatory power data from the CSV file created in `LMEPowerData.m`
  - Data is preprocessed and significant features obtained from the LME are extracted for use in classification models.
  - Normalizes and scales the features to ensure they are suitable for input into machine learning models.

- **Model Training & Evaluation**:
  - Random Forest, Gradient Boosting, KNN classifiers are applied to the data to classify trials as self-focused or non-self-focused.
  - Grid-search is used to perform hyperparameter tuning, by searching through a predefined set of hyperparameters.
  - Cross-validation is used to evaluate model performance and avoid overfitting.
  - Metrics such as accuracy, precision, recall, and F1-score are generated to evaluate the performance of each classification model.
 
  
