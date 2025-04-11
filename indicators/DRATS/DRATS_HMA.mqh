//+------------------------------------------------------------------+
//|                      DRATS_HMA.mqh                               |
//| Copyright 2025, jechaviz                                         |
//| jechaviz@gmail.com                                               |
//+------------------------------------------------------------------+
#ifndef DRATS_HMA_MQH
#define DRATS_HMA_MQH

//+------------------------------------------------------------------+
//| Calculate Hull Moving Average                                   |
//| Inputs:                                                         |
//|   price[]   - Price series                                      |
//|   bar       - Current bar index                                 |
//|   period    - HMA period (volatility-adjusted)                  |
//|   total     - Total bars available                             |
//| Returns:                                                        |
//|   HMA value at current bar                                      |
//+------------------------------------------------------------------+
double CalculateHMA(const double &price[], int bar, double period, int total) {
   int p = (int)MathMax(1, MathRound(period));
   if (bar < p * 2) return price[bar];

   // WMA of period p/2
   double wma_short = 0.0;
   int short_period = p / 2;
   double short_weight_sum = 0.0;
   for (int i = 0; i < short_period && (bar - i) >= 0; i++) {
      double weight = short_period - i;
      wma_short += price[bar - i] * weight;
      short_weight_sum += weight;
   }
   wma_short /= short_weight_sum;

   // WMA of period p
   double wma_long = 0.0;
   double long_weight_sum = 0.0;
   for (int i = 0; i < p && (bar - i) >= 0; i++) {
      double weight = p - i;
      wma_long += price[bar - i] * weight;
      long_weight_sum += weight;
   }
   wma_long /= long_weight_sum;

   // Raw HMA: 2 * WMA(p/2) - WMA(p)
   double raw_hma = 2 * wma_short - wma_long;

   // WMA of raw HMA over sqrt(p)
   int smooth_period = (int)MathMax(1, MathRound(MathSqrt(p)));
   if (bar < smooth_period) return raw_hma;

   double hma = 0.0;
   double smooth_weight_sum = 0.0;
   double hma_series[];
   ArrayResize(hma_series, smooth_period);

   for (int i = 0; i < smooth_period && (bar - i) >= 0; i++) {
      if (i == 0) {
         hma_series[i] = raw_hma;
      } else {
         double w_s = 0.0, w_l = 0.0;
         double ws_sum = 0.0, wl_sum = 0.0;
         for (int j = 0; j < short_period && (bar - i - j) >= 0; j++) {
            double w = short_period - j;
            w_s += price[bar - i - j] * w;
            ws_sum += w;
         }
         for (int j = 0; j < p && (bar - i - j) >= 0; j++) {
            double w = p - j;
            w_l += price[bar - i - j] * w;
            wl_sum += w;
         }
         hma_series[i] = 2 * (w_s / ws_sum) - (w_l / wl_sum);
      }
      double weight = smooth_period - i;
      hma += hma_series[i] * weight;
      smooth_weight_sum += weight;
   }

   return hma / smooth_weight_sum;
}

#endif