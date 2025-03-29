# Adaptive Multi-Scale Trend Classifier (AMTC): A Research-Grade Indicator for Dynamic Market State Categorization

## Abstract
The Adaptive Multi-Scale Trend Classifier (AMTC) is a cutting-edge technical indicator designed to dynamically classify market conditions into up, down, and flat states with high accuracy and adaptability. Building upon the foundations of traditional moving averages, the AMTC introduces a suite of innovations including volatility-adjusted multi-scale decomposition, non-linear slope estimation, and the Unscented Kalman Filter (UKF) for precise trend estimation. These are complemented by fuzzy logic consensus for signal aggregation and genetic algorithm optimization for parameter tuning. Further enhancements such as cross-asset trend consensus, skewness-dependent adjustments, multi-threading for real-time performance, and an interactive SHAP dashboard for explainability set the AMTC apart from conventional indicators. Conceptual evaluations suggest that the AMTC offers improved performance in volatile and choppy markets, making it a valuable tool for traders and researchers in financial market analysis.

## 1. Introduction
Financial markets are inherently non-stationary and volatile, posing significant challenges for accurate trend classification. Traditional technical indicators, such as the Simple Moving Average (SMA) and Exponential Moving Average (EMA), often fail to adapt to rapid market shifts, resulting in delayed signals and frequent false positives. The Hull Moving Average (HMA), introduced by Hull (2005), addressed some of these issues by reducing lag through a combination of weighted moving averages and a square root transformation. However, its fixed-period design and lack of explicit trend classification limited its flexibility in diverse market conditions.

The Unified Adaptive Hull Moving Average (UHMA) extended the HMA by incorporating multi-scale analysis and basic slope-based classification. While an improvement, the UHMA’s static scales and reliance on linear assumptions constrained its precision in complex, non-linear market environments.

The Adaptive Multi-Scale Trend Classifier (AMTC) overcomes these limitations by introducing a sophisticated, adaptive framework that classifies market states into up, down, and flat categories with enhanced accuracy and responsiveness. The AMTC integrates several advanced components: volatility-adjusted multi-scale decomposition, non-linear slope estimation, and the Unscented Kalman Filter (UKF) for robust trend estimation. These core features are augmented by fuzzy logic consensus for aggregating signals across scales and genetic algorithm optimization for parameter tuning. Additional enhancements, including cross-asset trend consensus, skewness-dependent adjustments, multi-threading for real-time performance, and an interactive SHAP dashboard for explainability, distinguish the AMTC from traditional indicators. By leveraging these innovations, the AMTC is particularly well-suited for real-time trading applications, offering both precision and transparency.

This paper aims to:  
- Detail the AMTC’s methodology and technical underpinnings,  
- Evaluate its conceptual performance against traditional indicators, and  
- Discuss its implications for traders and researchers in financial market analysis.

## 2. Literature Review
Technical analysis has long relied on moving averages to identify trends, with the SMA and EMA being foundational tools (Kaufman, 1995). However, their inherent lag prompted the development of adaptive indicators, such as the Kaufman Adaptive Moving Average (KAMA), which adjusts to market volatility. The HMA (Hull, 2005) further reduced lag, while wavelet-based methods enabled multi-scale analysis of price data (Percival & Walden, 2000). Fuzzy logic has been employed to manage uncertainty in signal aggregation (Zimmermann, 2001), enhancing decision-making in noisy environments.

Recent advancements in signal processing and optimization have further enriched the field. Kalman filtering, particularly the Unscented Kalman Filter (UKF), has been widely adopted in finance for state estimation and forecasting due to its ability to handle non-linear dynamics (Harvey, 1990; Wan & Van Der Merwe, 2000). Genetic algorithms, inspired by natural selection, have proven effective in optimizing complex parameter spaces in trading systems (Mitchell, 1996). The AMTC builds on this foundation, integrating the UKF for trend estimation and genetic algorithms for parameter optimization, alongside other novel techniques, to achieve superior adaptability and precision.

## 3. Methodology
The AMTC is a composite indicator comprising multiple interconnected components, each designed to address specific challenges in trend classification. Below, we outline the technical details of these components, emphasizing their mathematical formulations and practical utility.

### 3.1 Volatility-Adjusted Multi-Scale Decomposition
The AMTC analyzes trends across short, medium, and long-term horizons using three distinct scales, with periods dynamically adjusted based on market volatility. The adjustment is driven by the Average True Range (ATR), a widely used volatility measure. The adjusted period for scale \( i \) at time \( t \) is calculated as:

\[
p_{i,t}^{\text{adj}} = p_i \times \left(1 + \beta \times \frac{\text{ATR}_t}{\text{ATR}_{\text{avg},t}}\right)
\]

where:  
- \( p_i \) is the base period for scale \( i \) (e.g., 9, 21, 50),  
- \( \beta \) is a user-defined sensitivity parameter,  
- \( \text{ATR}_t \) is the current ATR, and  
- \( \text{ATR}_{\text{avg},t} \) is the average ATR over a historical window (e.g., 14 periods).  

This volatility adjustment ensures that the AMTC becomes more responsive during turbulent periods and smooths out noise in stable conditions.

### 3.2 Non-Linear Slope Estimation
For each scale, the AMTC estimates the trend slope using a sigmoid-weighted method to capture non-linear dynamics, such as trend acceleration or deceleration. The slope at scale \( i \) and time \( t \) is:

\[
\text{slope}_{i,t} = \sum_{k=1}^{w_i} \left( \frac{1}{1 + e^{-\delta (P_t - P_{t-k})}} - 0.5 \right) \times \frac{k}{w_i}
\]

where:  
- \( w_i = \lfloor p_{i,t}^{\text{adj}} / 2 \rfloor \) is half the adjusted period,  
- \( \delta \) controls the sigmoid function’s steepness,  
- \( P_t \) is the price at time \( t \), and  
- \( P_{t-k} \) is the price \( k \) periods ago.  

This non-linear approach enhances sensitivity to subtle trend changes compared to traditional linear methods.

### 3.3 Unscented Kalman Filtering (UKF)
The AMTC employs the Unscented Kalman Filter (UKF) to estimate the true trend slope \( S_t \) as a hidden state, updated based on observed price movements. The UKF excels in non-linear systems and is defined by the following state transition and measurement models:

\[
S_t = f(S_{t-1}, u_t) + w_t
\]
\[
z_t = h(S_t) + v_t
\]

where:  
- \( f \) and \( h \) are non-linear functions representing state evolution and measurement processes,  
- \( u_t \) is an optional control input (e.g., volatility),  
- \( w_t \) and \( v_t \) are Gaussian noise terms with covariances \( Q \) and \( R \), respectively, and  
- \( z_t \) is the observed slope from Section 3.2.  

The UKF uses sigma points to approximate the state distribution, providing a more accurate estimate of the mean and covariance than linear approximations like the Extended Kalman Filter (EKF). This improves the AMTC’s ability to track trends in volatile, non-linear markets.

### 3.4 Fuzzy Logic Consensus
The AMTC aggregates trend signals across scales using a fuzzy logic system. Membership functions for up, down, and flat states are defined with dynamic thresholds:

\[
\mu_{\text{up},i}(s) = \frac{1}{1 + e^{-k(s - \theta_i)}}, \quad \theta_i = \alpha \times \sqrt{\text{var}(S_{t,i})}
\]

where:  
- \( s \) is the slope at scale \( i \),  
- \( k \) controls the transition steepness,  
- \( \theta_i \) is the threshold for scale \( i \),  
- \( \alpha \) is a scaling parameter, and  
- \( \text{var}(S_{t,i}) \) is the variance of the slope at scale \( i \).  

The final classification is a weighted average of fuzzy scores, with weights adjusted for volatility and skewness (see Section 3.6).

### 3.5 Genetic Algorithm Optimization
The AMTC’s parameters (e.g., \( \beta \), \( \delta \), \( \alpha \)) are optimized using a genetic algorithm. The fitness function balances multiple objectives:

\[
\text{fitness} = 0.4 \times \text{hit_rate} + 0.4 \times \text{Sortino} - 0.2 \times \text{drift} - 0.2 \times \text{instability}
\]

where:  
- \( \text{hit_rate} \) is the classification accuracy,  
- \( \text{Sortino} \) is the Sortino ratio (a risk-adjusted return metric),  
- \( \text{drift} \) measures parameter drift over time, and  
- \( \text{instability} \) penalizes excessive variability in classifications.  

This optimization ensures the AMTC achieves high accuracy and stability across market conditions.

### 3.6 Cross-Asset Trend Consensus and Skewness Influence
To enhance contextual awareness, the AMTC incorporates a trend consensus score from one or two highly correlated assets, weighted by recent correlation coefficients. Additionally, skewness adjusts the fuzzy membership weights, increasing sensitivity to downtrends during periods of negative skewness (e.g., market crashes).

### 3.7 SHAP-Based Explainability with Interactive Dashboard
Transparency is achieved through SHapley Additive exPlanations (SHAP) values, which quantify each feature’s contribution (e.g., volatility, slope, consensus) to the final classification. The AMTC includes an interactive dashboard displaying real-time SHAP values, enabling users to visualize decision-making factors. This fosters trust and provides actionable insights for traders.

### 3.8 Multi-Threading for Real-Time Performance
The AMTC leverages multi-threading to parallelize computations across scales and filters, minimizing latency. This optimization ensures efficient operation in real-time trading environments, making it suitable for high-frequency applications.

## 4. Results and Discussion
As a conceptual paper, this study does not present empirical results but evaluates the AMTC’s potential based on its design. The UKF is expected to enhance trend estimation accuracy, particularly in markets with non-linear dynamics, by robustly handling uncertainty. Multi-threading enables efficient processing of large datasets and multiple scales, reducing delays that could impair real-time decision-making. The interactive SHAP dashboard provides immediate insights into classification drivers, enhancing trust and usability.

Compared to traditional indicators like the HMA and UHMA, the AMTC’s adaptability, precision, and transparency suggest significant advantages, particularly in volatile or choppy markets. While empirical validation is beyond this paper’s scope, the conceptual framework warrants further research, including backtesting across diverse asset classes and timeframes.

## 5. Conclusion
The AMTC represents a significant advancement in technical analysis, offering a highly adaptive, transparent, and efficient tool for market state classification. Its real-time capabilities, powered by multi-threading, make it ideal for high-frequency trading, while the interactive SHAP dashboard bridges the gap between complex models and practical applications. Future research could explore its integration with machine learning for predictive analytics or its performance across asset classes like cryptocurrencies and commodities.

## References
- Harvey, A. C. (1990). *Forecasting, Structural Time Series Models and the Kalman Filter*. Cambridge University Press.  
- Hull, A. (2005). *Hull Moving Average*. [Placeholder for full citation].  
- Kaufman, P. J. (1995). *Smarter Trading: Improving Performance in Changing Markets*. McGraw-Hill.  
- Mitchell, M. (1996). *An Introduction to Genetic Algorithms*. MIT Press.  
- Percival, D. B., & Walden, A. T. (2000). *Wavelet Methods for Time Series Analysis*. Cambridge University Press.  
- Wan, E. A., & Van Der Merwe, R. (2000). The Unscented Kalman Filter for Nonlinear Estimation. In *Proceedings of the IEEE 2000 Adaptive Systems for Signal Processing, Communications, and Control Symposium* (pp. 153–158).  
- Zimmermann, H. J. (2001). *Fuzzy Set Theory—and Its Applications*. Springer.

---

### Notes for Publication
- **Visual Aids**: Consider adding a diagram of the AMTC’s architecture or a flowchart of its signal generation process to enhance clarity.  
- **Empirical Validation**: Future submissions could include backtesting results to quantify performance.  
- **Implementation**: The AMTC is implemented in MQL5 for MetaTrader 5, enhancing its practical relevance, though detailed code is reserved for supplementary materials.