// AMTC_UKF.mqh
#ifndef AMTC_UKF_MQH
#define AMTC_UKF_MQH

double state;        // Slope state
double covariance;   // State covariance
double Q, R;         // Process and measurement noise
double sigmaPoints[5]; // 2n + 1 points for 1D state
double weights[5];

// Initialize UKF
void InitUKF(double processNoise, double measurementNoise) {
   state = 0.0;
   covariance = 0.1;
   Q = processNoise;
   R = measurementNoise;
   weights[0] = 0.5; // Weight for mean point
   for(int i = 1; i < 5; i++) weights[i] = 0.125; // Weights for sigma points
}

// Update UKF with new observation
double UKFUpdate(double observedSlope) {
   // Generate sigma points (n = 1, so 2n + 1 = 3, but use 5 for stability)
   double sqrtCov = MathSqrt(3 * covariance);
   sigmaPoints[0] = state;
   sigmaPoints[1] = state + sqrtCov;
   sigmaPoints[2] = state - sqrtCov;
   sigmaPoints[3] = state + 2 * sqrtCov;
   sigmaPoints[4] = state - 2 * sqrtCov;

   // Predict step (simple random walk model)
   for(int i = 0; i < 5; i++) {
      sigmaPoints[i] += (MathRand() / 32767.0 - 0.5) * MathSqrt(Q);
   }

   // Update step
   double meanPred = 0.0, covPred = 0.0;
   for(int i = 0; i < 5; i++) meanPred += weights[i] * sigmaPoints[i];
   for(int i = 0; i < 5; i++) {
      double diff = sigmaPoints[i] - meanPred;
      covPred += weights[i] * diff * diff;
   }
   covPred += Q;

   // Measurement update
   double measMean = 0.0, measCov = 0.0, crossCov = 0.0;
   for(int i = 0; i < 5; i++) measMean += weights[i] * sigmaPoints[i];
   for(int i = 0; i < 5; i++) {
      double diff = sigmaPoints[i] - measMean;
      measCov += weights[i] * diff * diff;
      crossCov += weights[i] * (sigmaPoints[i] - meanPred) * diff;
   }
   measCov += R;

   // Kalman gain
   double kalmanGain = measCov > 0 ? crossCov / measCov : 0.0;

   // Update state and covariance
   state = meanPred + kalmanGain * (observedSlope - measMean);
   covariance = covPred - kalmanGain * crossCov;

   return state;
}

void DeinitUKF() {
   state = 0.0;
   covariance = 0.1;
}

#endif