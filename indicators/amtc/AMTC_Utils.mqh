// #                        AMTC_Utils.mqh
#ifndef AMTC_UTILS_MQH
#define AMTC_UTILS_MQH

// # Calculate Linear Weighted Moving Average
double CalculateLWMA(const double &data[], int bar, int period, int total) {
   if(bar < period - 1 || bar >= total) return 0.0;
   double sum = 0.0;
   double weightSum = period * (period + 1) / 2.0;
   for(int i = 0; i < period; i++) {
      int idx = bar - i;
      if(idx < 0) return 0.0;
      sum += data[idx] * (period - i);
   }
   return sum / weightSum;
}

// # Calculate Hull Moving Average
double CalculateHMA(const double &data[], int bar, int period, int total) {
   if(bar < period + (int)MathSqrt(period) - 1 || bar >= total) return 0.0;

   // Step 1: WMA of half period
   int halfPeriod = MathMax(2, period / 2);
   double wmaHalf = CalculateLWMA(data, bar, halfPeriod, total);

   // Step 2: WMA of full period
   double wmaFull = CalculateLWMA(data, bar, period, total);

   // Step 3: Raw HMA = 2 * WMA(half) - WMA(full)
   double rawHma = 2.0 * wmaHalf - wmaFull;

   // Step 4: WMA of raw HMA with sqrt(period)
   int sqrtPeriod = MathMax(2, (int)MathSqrt(period));
   static double rawHmaArray[];
   ArrayResize(rawHmaArray, total);
   rawHmaArray[bar] = rawHma;

   return CalculateLWMA(rawHmaArray, bar, sqrtPeriod, total);
}

// # Adjust HMA period based on volatility (ATR)
double CalculateAdjustedPeriod(int basePeriod, double atr, double sensitivity) {
   double atrHandle = iMA(NULL, 0, 50, 0, MODE_SMA, PRICE_CLOSE, atr);
   if(atrHandle == INVALID_HANDLE) return basePeriod;
   double atrAvg = atrHandle;
   double volatilityFactor = (atr / atrAvg) * sensitivity;
   return MathMax(5, MathMin(basePeriod * 2, basePeriod * volatilityFactor));
}

// # Non-linear slope estimation using sigmoid weighting
double CalculateNonLinearSlope(const double &hma[], int bar, int period, int total) {
   if(bar < 1 || bar >= total) return 0.0;
   double delta = hma[bar] - hma[bar - 1];
   double sigmoid = 1.0 / (1.0 + MathExp(-delta * 100.0)); // Steeper sigmoid
   return delta * (sigmoid - 0.5) * 2.0; // Center around 0
}

// # Bayesian Particle Filter for slope estimation
double ParticleFilterUpdate(double observedSlope, double &particles[], int particleCount) {
   static bool initialized = false;
   double weights[], filtered = 0.0;
   ArrayResize(weights, particleCount);

   if(!initialized) {
      for(int i = 0; i < particleCount; i++) {
         particles[i] = (MathRand() / 32767.0 - 0.5) * 0.01; // Initial spread
      }
      initialized = true;
   }

   // Update particles and compute weights
   double sumWeights = 0.0;
   for(int i = 0; i < particleCount; i++) {
      particles[i] += (MathRand() / 32767.0 - 0.5) * 0.001; // Random walk
      double diff = particles[i] - observedSlope;
      weights[i] = MathExp(-diff * diff / 0.02); // Gaussian likelihood
      sumWeights += weights[i];
   }

   // Normalize weights and compute filtered value
   if(sumWeights == 0) return observedSlope; // Avoid division by zero
   for(int i = 0; i < particleCount; i++) {
      weights[i] /= sumWeights;
      filtered += particles[i] * weights[i];
   }

   // Resample particles
   double newParticles[];
   ArrayResize(newParticles, particleCount);
   double step = 1.0 / particleCount;
   double r = MathRand() / 32767.0 * step;
   double c = weights[0];
   int j = 0;
   for(int i = 0; i < particleCount; i++) {
      double u = r + i * step;
      while(u > c && j < particleCount - 1) {
         j++;
         c += weights[j];
      }
      newParticles[i] = particles[j];
   }
   ArrayCopy(particles, newParticles);

   return filtered;
}

// # Cross-asset trend consensus
double CalculateCrossAssetConsensus(int bar, string symbol, int total) {
   double priceOther[];
   if(CopyClose(symbol, _Period, bar, 10, priceOther) < 10) return 0.0;
   double slope = (priceOther[0] - priceOther[9]) / 9.0;
   return slope > 0.0001 ? 0.2 : (slope < -0.0001 ? -0.2 : 0.0);
}

// # Skewness adjustment for fuzzy weights
double CalculateSkewnessAdjustment(const double &price[], int bar, int total) {
   if(bar < 20 || bar >= total) return 0.0;
   double returns[], mean = 0.0, m2 = 0.0, m3 = 0.0;
   ArrayResize(returns, 20);
   for(int i = 0; i < 20; i++) {
      int idx = bar - i - 1;
      if(idx < 0) return 0.0;
      returns[i] = price[bar - i] - price[idx];
      mean += returns[i];
   }
   mean /= 20.0;
   for(int i = 0; i < 20; i++) {
      double dev = returns[i] - mean;
      m2 += dev * dev;
      m3 += dev * dev * dev;
   }
   double variance = m2 / 19.0;
   if(variance == 0) return 0.0;
   double skewness = (m3 / 20.0) / MathPow(variance, 1.5);
   return MathMax(-0.5, MathMin(0.5, skewness));
}

// # Fuzzy logic consensus scores
void CalculateFuzzyScores(double slope, double consensus, double skewAdj,
                          double &upScore, double &downScore, double &flatScore) {
   double slopePos = MathMax(0, slope);
   double slopeNeg = MathMax(0, -slope);
   upScore = MathMin(1.0, (slopePos * 100.0 + consensus * 0.5 + skewAdj * 0.3) / 0.01);
   downScore = MathMin(1.0, (slopeNeg * 100.0 - consensus * 0.5 + skewAdj * 0.3) / 0.01);
   flatScore = MathMin(1.0, 1.0 - (MathAbs(slope) * 200.0) / 0.005);
   double total = upScore + downScore + flatScore;
   if(total > 0) {
      upScore /= total;
      downScore /= total;
      flatScore /= total;
   }
}

// # SHAP values for explainability
void CalculateSHAPValues(double slope, double consensus, double skewAdj, double &shapValues[]) {
   ArrayResize(shapValues, 3);
   shapValues[0] = MathAbs(slope) * 100.0 * 0.5;     // Slope contribution
   shapValues[1] = MathAbs(consensus) * 0.3;         // Consensus contribution
   shapValues[2] = MathAbs(skewAdj) * 0.2;           // Skewness contribution
}

#endif