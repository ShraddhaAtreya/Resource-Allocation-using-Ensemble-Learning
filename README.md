# 5G Resource Allocation and Handover Simulation with Ensemble Learning

This project simulates a dynamic 5G network environment in MATLAB, generating a realistic dataset that captures user mobility, handover events, and resource allocation behavior across multiple gNodeBs (gNBs). The output dataset is further analyzed in Python using ensemble machine learning models to predict resource allocation performance.

---

 ## Project Overview

This work models:

- A grid-based 5G topology with **9 gNodeBs** and **90 UEs**
- **User mobility** and **handover dynamics** across time
- Application-specific **bandwidth requirements**
- Effects of **interference**, **congestion**, and **gNB capacity**
- Export of key metrics (e.g., latency, RSSI, allocated throughput) to a CSV file

Machine learning models are then trained on this dataset to predict throughput allocation using **ensemble learning techniques** such as:
- Stacking Regressor
- Gradient Boosting
- Random Forest
- XGBoost
- AdaBoost
- LightGBM
- Voting Regressor

---
**Technologies Used**

| Layer        | Tools / Libraries          |
| ------------ | -------------------------- |
| Simulation   | MATLAB (R2021a or later)   |
| ML Analysis  | Python 3.10+, Pandas, NumPy |
| Visualization| Matplotlib, Seaborn        |
| ML Models    | scikit-learn, XGBoost, LightGBM |

---

---

## Dataset Description

The generated dataset contains the following columns:

- `Timestamp`: Time step of the simulation
- `User_ID`: Unique identifier of the user equipment (UE)
- `Application`: Type of application (e.g., Emergency, Streaming)
- `Signal_Str`: Received Signal Strength Indicator (RSSI)
- `Latency`: Estimated latency based on distance & congestion
- `Required_`: Required bandwidth for the application
- `Allocated_`: Actual bandwidth allocated to the UE
- `Resource_Allocation`: Allocation % relative to requirement

---

##  ML Model Results

| **Model**            | **R² Score** | **RMSE**  | **MSE**    |
|----------------------|--------------|-----------|------------|
| Stacking Regressor   | 0.9948       | 0.0141    | 0.0002     |
| Gradient Boosting    | 0.9943       | 0.0147    | 0.0002     |
| XGBoost              | 0.9937       | 0.0154    | 0.0002     |
| Voting Regressor     | 0.9926       | 0.0168    | 0.0003     |
| Random Forest        | 0.9892       | 0.0203    | 0.0004     |
| AdaBoost             | 0.9760       | 0.0302    | 0.0009     |
| LightGBM             | 0.9747       | 0.0310    | 0.0010     |

---

##  How to Run

### MATLAB Simulation

1. Open MATLAB and run `newfiveg.m`
2. A CSV file `handover_dataset_custom.csv` will be created
3. The simulation visually displays UEs, gNBs, and handovers

### Python ML Model

1. Open the `ensemble_learning.ipynb` notebook
2. Load the CSV file and run all cells
3. Models will train and evaluate on the dataset



##  Applications

- 5G handover modeling
- QoS-aware traffic management
- Network traffic forecasting
- Intelligent RAN (Radio Access Network) planning






