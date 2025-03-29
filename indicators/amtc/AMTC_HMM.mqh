//+------------------------------------------------------------------+
//|                      AMTC_HMM.mqh                                |
//+------------------------------------------------------------------+
#ifndef AMTC_HMM_MQH
#define AMTC_HMM_MQH

double stateProbs[3]; // Trending, Range-bound, Volatile

void InitHMM() {
   ArrayFill(stateProbs, 0, 3, 1.0 / 3.0); // Uniform initial probabilities
}

double UpdateHMM(double volatility, double slopeVariance) {
   double observations[2] = {volatility, slopeVariance};
   double transition[3][3] = {{0.8, 0.1, 0.1}, {0.2, 0.6, 0.2}, {0.3, 0.2, 0.5}};
   double emission[3][2] = {{0.01, 0.001}, {0.005, 0.0005}, {0.02, 0.002}}; // Mean volatilities and variances
   double newProbs[3];

   for(int i = 0; i < 3; i++) {
      newProbs[i] = 0.0;
      for(int j = 0; j < 3; j++) {
         newProbs[i] += stateProbs[j] * transition[j][i];
      }
      double likelihood = MathExp(-MathPow(observations[0] - emission[i][0], 2) / 0.01) *
                          MathExp(-MathPow(observations[1] - emission[i][1], 2) / 0.0001);
      newProbs[i] *= likelihood;
   }

   double sum = newProbs[0] + newProbs[1] + newProbs[2];
   if(sum > 0) {
      for(int i = 0; i < 3; i++) stateProbs[i] = newProbs[i] / sum;
   }

   int maxState = 0;
   for(int i = 1; i < 3; i++) {
      if(stateProbs[i] > stateProbs[maxState]) maxState = i;
   }
   return maxState * 0.5; // Scale to 0-1 range
}

#endif