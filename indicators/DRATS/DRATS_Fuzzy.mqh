//+------------------------------------------------------------------+
//|                      DRATS_Fuzzy.mqh                             |
//| Copyright 2025, jechaviz                                         |
//| jechaviz@gmail.com                                               |
//+------------------------------------------------------------------+
#ifndef DRATS_FUZZY_MQH
#define DRATS_FUZZY_MQH

//+------------------------------------------------------------------+
//| Calculate skewness of price returns                             |
//| Inputs:                                                         |
//|   price[]  - Price series (close prices)                        |
//|   bar      - Current bar index                                  |
//|   period   - Lookback period for skewness                       |
//|   total    - Total number of bars available                     |
//| Returns:                                                        |
//|   Skewness value                                                |
//+------------------------------------------------------------------+
double CalculateSkewness(const double &price[], int bar, int period, int total) {
   if (bar < period || bar >= total) return 0.0;

   double returns[];
   ArrayResize(returns, period);
   double mean = 0.0, m2 = 0.0, m3 = 0.0;

   // Compute returns and mean
   for (int i = 0; i < period; i++) {
      returns[i] = price[bar - i] - price[bar - i - 1];
      mean += returns[i];
   }
   mean /= period;

   // Compute second and third moments
   for (int i = 0; i < period; i++) {
      double dev = returns[i] - mean;
      m2 += dev * dev;
      m3 += dev * dev * dev;
   }

   double variance = m2 / (period - 1);
   if (variance == 0) return 0.0;
   return (m3 / period) / MathPow(variance, 1.5);
}

//+------------------------------------------------------------------+
//| Perform fuzzy classification of market state                    |
//| Inputs:                                                         |
//|   s_short   - Short-scale slope                                 |
//|   s_medium  - Medium-scale slope                                |
//|   s_long    - Long-scale slope                                  |
//|   atr       - Current ATR value                                 |
//|   skew      - Skewness of recent returns                        |
//| Outputs:                                                        |
//|   upScore   - Fuzzy score for uptrend                           |
//|   downScore - Fuzzy score for downtrend                         |
//|   flatScore - Fuzzy score for flat state                        |
//+------------------------------------------------------------------+
void CalculateFuzzy(double s_short, double s_medium, double s_long, double atr, double skew, 
                    double &upScore, double &downScore, double &flatScore) {
   // Compute adaptive threshold
   double theta_t = 1.2 * atr * (1 + 0.25 * MathAbs(skew));
   if (theta_t == 0) theta_t = 1e-10; // Avoid division by zero

   // Membership functions for each scale
   double mu_up_short = MathMax(0, MathMin(1, (s_short - theta_t) / theta_t));
   double mu_down_short = MathMax(0, MathMin(1, (-s_short - theta_t) / theta_t));
   double mu_flat_short = 1 - MathMax(mu_up_short, mu_down_short);

   double mu_up_medium = MathMax(0, MathMin(1, (s_medium - theta_t) / theta_t));
   double mu_down_medium = MathMax(0, MathMin(1, (-s_medium - theta_t) / theta_t));
   double mu_flat_medium = 1 - MathMax(mu_up_medium, mu_down_medium);

   double mu_up_long = MathMax(0, MathMin(1, (s_long - theta_t) / theta_t));
   double mu_down_long = MathMax(0, MathMin(1, (-s_long - theta_t) / theta_t));
   double mu_flat_long = 1 - MathMax(mu_up_long, mu_down_long);

   // Aggregate scores with weights
   double w1 = 0.3, w2 = 0.4, w3 = 0.3; // Short, medium, long weights
   upScore = (w1 * mu_up_short + w2 * mu_up_medium + w3 * mu_up_long);
   downScore = (w1 * mu_down_short + w2 * mu_down_medium + w3 * mu_down_long);
   flatScore = (w1 * mu_flat_short + w2 * mu_flat_medium + w3 * mu_flat_long);
}

#endif