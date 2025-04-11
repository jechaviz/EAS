//+------------------------------------------------------------------+
//|                      DRATS_ParticleFilter.mqh                    |
//| Copyright 2025, jechaviz                                         |
//| jechaviz@gmail.com                                               |
//+------------------------------------------------------------------+
#ifndef DRATS_PARTICLE_FILTER_MQH
#define DRATS_PARTICLE_FILTER_MQH

// Global variables
int    N_particles = 50;                // Number of particles
int    r_particles[];                   // Regime states (0=trending, 1=range-bound, 2=volatile)
double w_particles[];                   // Particle weights
double transition[3][3] = {             // State transition matrix
   {0.8, 0.1, 0.1},                    // P(trending -> trending, range-bound, volatile)
   {0.1, 0.8, 0.1},                    // P(range-bound -> trending, range-bound, volatile)
   {0.1, 0.1, 0.8}                     // P(volatile -> trending, range-bound, volatile)
};
double mu_r[3]    = {0.1, 0.0, 0.0};   // Expected slope for each regime
double sigma_r[3] = {0.05, 0.01, 0.1}; // Volatility for each regime

//+------------------------------------------------------------------+
//| Initialize particle filter                                      |
//| Input:                                                          |
//|   numParticles - Number of particles to use                     |
//+------------------------------------------------------------------+
void InitParticleFilter(int numParticles) {
   N_particles = numParticles;
   ArrayResize(r_particles, N_particles);
   ArrayResize(w_particles, N_particles);

   // Initialize particles with random regimes and equal weights
   for (int i = 0; i < N_particles; i++) {
      r_particles[i] = MathRand() % 3; // Random regime: 0, 1, or 2
      w_particles[i] = 1.0 / N_particles;
   }
}

//+------------------------------------------------------------------+
//| Update particle filter with new observation                     |
//| Inputs:                                                         |
//|   s_t         - Observed filtered slope                         |
//| Outputs:                                                        |
//|   regimeProb  - Probabilities of each regime (array of 3)       |
//+------------------------------------------------------------------+
void UpdateParticleFilter(double s_t, double &regimeProb[]) {
   double total_weight = 0.0;

   // Update each particle
   for (int i = 0; i < N_particles; i++) {
      // Sample new regime based on transition probabilities
      double rand = MathRand() / 32767.0;
      double cum_prob = 0.0;
      for (int j = 0; j < 3; j++) {
         cum_prob += transition[r_particles[i]][j];
         if (rand < cum_prob) {
            r_particles[i] = j;
            break;
         }
      }

      // Compute likelihood: exp(-((s_t - mu_r)^2) / (2 * sigma_r^2))
      double diff = s_t - mu_r[r_particles[i]];
      double sigma = sigma_r[r_particles[i]];
      double log_L = - (diff * diff) / (2 * sigma * sigma);
      double L = MathExp(log_L);

      // Update weight
      w_particles[i] *= L;
      total_weight += w_particles[i];
   }

   // Normalize weights
   if (total_weight > 0) {
      for (int i = 0; i < N_particles; i++) {
         w_particles[i] /= total_weight;
      }
   } else {
      // Reset weights if all are zero (rare edge case)
      for (int i = 0; i < N_particles; i++) {
         w_particles[i] = 1.0 / N_particles;
      }
   }

   // Compute Effective Sample Size (ESS)
   double sum_w2 = 0.0;
   for (int i = 0; i < N_particles; i++) {
      sum_w2 += w_particles[i] * w_particles[i];
   }
   double ESS = 1.0 / sum_w2;

   // Resample if ESS is below threshold
   if (ESS < N_particles / 2.0) {
      double new_r_particles[];
      ArrayResize(new_r_particles, N_particles);
      double cumulative_sum[];
      ArrayResize(cumulative_sum, N_particles);

      // Compute cumulative sum of weights
      cumulative_sum[0] = w_particles[0];
      for (int i = 1; i < N_particles; i++) {
         cumulative_sum[i] = cumulative_sum[i-1] + w_particles[i];
      }

      // Systematic resampling
      double step = 1.0 / N_particles;
      double start = (MathRand() / 32767.0) * step;
      int idx = 0;
      for (int i = 0; i < N_particles; i++) {
         double u = start + i * step;
         while (idx < N_particles - 1 && u > cumulative_sum[idx]) idx++;
         new_r_particles[i] = r_particles[idx];
      }

      // Update particles and reset weights
      for (int i = 0; i < N_particles; i++) {
         r_particles[i] = new_r_particles[i];
         w_particles[i] = 1.0 / N_particles;
      }
   }

   // Compute regime probabilities
   ArrayFill(regimeProb, 0, 3, 0.0);
   for (int i = 0; i < N_particles; i++) {
      regimeProb[r_particles[i]] += w_particles[i];
   }
}

#endif