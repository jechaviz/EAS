//+------------------------------------------------------------------+
//|                      AMTC_Utils.mqh                              |
//+------------------------------------------------------------------+
#ifndef AMTC_UTILS_MQH
#define AMTC_UTILS_MQH

// LWMA Calculation
double CalculateLWMA(const double &data[], int bar, int period, int total) {
   if(bar < period - 1 || bar >= total) return(0.0);
   double sum = 0.0, weightSum = period * (period + 1) / 2.0;
   for(int i = 0; i < period; i++) sum += data[bar - i] * (period - i);
   return(sum / weightSum);
}

// HMA Calculation
double CalculateHMA(const double &data[], int bar, int period, int total) {
   if(bar < period + (int)MathSqrt(period) - 1 || bar >= total) return(0.0);
   int halfPeriod = MathMax(2, period / 2);
   double wmaHalf = CalculateLWMA(data, bar, halfPeriod, total);
   double wmaFull = CalculateLWMA(data, bar, period, total);
   double rawHma = 2.0 * wmaHalf - wmaFull;
   static double rawHmaArray[];
   ArrayResize(rawHmaArray, total);
   rawHmaArray[bar] = rawHma;
   return CalculateLWMA(rawHmaArray, bar, MathMax(2, (int)MathSqrt(period)), total);
}

// Volatility-adjusted period
double CalculateAdjustedPeriod(int basePeriod, double atr, double sensitivity) {
   int atrHandle = iATR(_Symbol, _Period, 14);
   if(atrHandle == INVALID_HANDLE) return basePeriod;
   double atrArray[];
   if(CopyBuffer(atrHandle, 0, 0, 50, atrArray) < 50) {
      IndicatorRelease(atrHandle);
      return basePeriod;
   }
   double atrAvg = 0.0;
   for(int i = 0; i < 50; i++) atrAvg += atrArray[i];
   atrAvg /= 50;
   IndicatorRelease(atrHandle);
   if(atrAvg == 0) return basePeriod;
   double factor = (atr / atrAvg) * sensitivity;
   return MathMax(5, MathMin(basePeriod * 2, basePeriod * factor));
}

// Non-linear slope with sigmoid weighting
double CalculateNonLinearSlope(const double &hma[], int bar, int period, int total) {
   if(bar < period || bar >= total) return(0.0);
   double delta = (hma[bar] - hma[bar - period]) / period;
   double sigmoid = 1.0 / (1.0 + MathExp(-10.0 * delta));
   return (sigmoid - 0.5) * 2.0;
}

// Cross-asset trend consensus
double CalculateCrossAssetConsensus(int bar, string assets, int total) {
   string assetList[];
   StringSplit(assets, ',', assetList);
   double consensus = 0.0, weightSum = 0.0;
   for(int i = 0; i < ArraySize(assetList); i++) {
      double price[];
      if(CopyClose(assetList[i], _Period, bar, 30, price) >= 30) {
         double slope = (price[0] - price[29]) / 29.0;
         double corr = CalculatePearsonCorrelation(_Symbol, assetList[i], bar, total);
         consensus += slope * corr;
         weightSum += MathAbs(corr);
      }
   }
   return weightSum > 0 ? consensus / weightSum : 0.0;
}

// Pearson correlation between 2 symbols
double CalculatePearsonCorrelation(string symbol1, string symbol2, int bar, int total) {
   double p1[], p2[];
   if(CopyClose(symbol1, _Period, bar, 30, p1) < 30 || CopyClose(symbol2, _Period, bar, 30, p2) < 30) return(0.0);
   double mean1 = 0.0, mean2 = 0.0, cov = 0.0, var1 = 0.0, var2 = 0.0;
   for(int i = 0; i < 30; i++) { mean1 += p1[i]; mean2 += p2[i]; }
   mean1 /= 30; mean2 /= 30;
   for(int i = 0; i < 30; i++) {
      double d1 = p1[i] - mean1, d2 = p2[i] - mean2;
      cov += d1 * d2;
      var1 += d1 * d1;
      var2 += d2 * d2;
   }
   return var1 * var2 > 0 ? cov / MathSqrt(var1 * var2) : 0.0;
}

// Skewness adjustment
double CalculateSkewnessAdjustment(const double &price[], int bar, int total) {
   if(bar < 30 || bar >= total) return(0.0);
   double returns[], mean = 0.0, m2 = 0.0, m3 = 0.0;
   ArrayResize(returns, 30);
   for(int i = 0; i < 30; i++) {
      returns[i] = price[bar - i] - price[bar - i - 1];
      mean += returns[i];
   }
   mean /= 30.0;
   for(int i = 0; i < 30; i++) {
      double dev = returns[i] - mean;
      m2 += dev * dev;
      m3 += dev * dev * dev;
   }
   double variance = m2 / 29.0;
   return variance > 0 ? (m3 / 30.0) / MathPow(variance, 1.5) : 0.0;
}

// Slope variance
double CalculateSlopeVariance(const double &slope[], int bar, int window, int total) {
   if(bar < window || bar >= total) return(0.0);
   double mean = 0.0, variance = 0.0;
   for(int i = 0; i < window; i++) mean += slope[bar - i];
   mean /= window;
   for(int i = 0; i < window; i++) {
      double dev = slope[bar - i] - mean;
      variance += dev * dev;
   }
   return variance / (window - 1);
}

// Fuzzy logic consensus with multi-scale and adjustments
void CalculateFuzzyScores(double slopeShort, double slopeMedium, double slopeLong, double consensus,
                          double skewAdj, double regime, double &upScore, double &downScore, double &flatScore) {
   double theta = 0.001 * (1 + regime);
   double muUpShort = 1.0 / (1.0 + MathExp(-10 * (slopeShort - theta)));
   double muDownShort = 1.0 / (1.0 + MathExp(10 * (slopeShort + theta)));
   double muFlatShort = 1.0 - MathMin(muUpShort, muDownShort);
   double muUpMedium = 1.0 / (1.0 + MathExp(-10 * (slopeMedium - theta)));
   double muDownMedium = 1.0 / (1.0 + MathExp(10 * (slopeMedium + theta)));
   double muFlatMedium = 1.0 - MathMin(muUpMedium, muDownMedium);
   double muUpLong = 1.0 / (1.0 + MathExp(-10 * (slopeLong - theta)));
   double muDownLong = 1.0 / (1.0 + MathExp(10 * (slopeLong + theta)));
   double muFlatLong = 1.0 - MathMin(muUpLong, muDownLong);

   upScore = (muUpShort * 0.3 + muUpMedium * 0.4 + muUpLong * 0.3) + consensus * 0.2 + MathMax(0, skewAdj) * 0.1;
   downScore = (muDownShort * 0.3 + muDownMedium * 0.4 + muDownLong * 0.3) - consensus * 0.2 + MathMax(0, -skewAdj) * 0.1;
   flatScore = (muFlatShort * 0.3 + muFlatMedium * 0.4 + muFlatLong * 0.3);
   double total = upScore + downScore + flatScore;
   if(total > 0) {
      upScore /= total;
      downScore /= total;
      flatScore /= total;
   }
}

// SHAP values for explainability
void CalculateSHAPValues(double slope, double consensus, double skewAdj, double regime, double &shapValues[]) {
   ArrayResize(shapValues, 4);
   shapValues[0] = MathAbs(slope) * 100.0 * 0.5;     // Slope
   shapValues[1] = MathAbs(consensus) * 0.3;         // Consensus
   shapValues[2] = MathAbs(skewAdj) * 0.2;           // Skewness
   shapValues[3] = regime * 0.1;                     // Regime
}

#endif