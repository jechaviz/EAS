//+------------------------------------------------------------------+
//|                      DRATS_GRU.mqh                               |
//| Copyright 2025, jechaviz                                         |
//| jechaviz@gmail.com                                               |
//+------------------------------------------------------------------+
#ifndef DRATS_GRU_MQH
#define DRATS_GRU_MQH

static double h_prev = 0.0;  // Previous hidden state

//+------------------------------------------------------------------+
//| Initialize GRU state                                            |
//+------------------------------------------------------------------+
void InitGRU() {
   h_prev = 0.0;
}

//+------------------------------------------------------------------+
//| Sigmoid activation function                                     |
//+------------------------------------------------------------------+
double sigmoid(double x) {
   return 1.0 / (1.0 + MathExp(-x));
}

//+------------------------------------------------------------------+
//| Update GRU and predict next slope                               |
//| Input:                                                          |
//|   s_t    - Current filtered slope                               |
//| Returns:                                                        |
//|   Updated hidden state (predicted slope)                        |
//+------------------------------------------------------------------+
double UpdateGRU(double s_t) {
   // Hardcoded weights and biases (pre-trained assumption)
   double w_z1 = 1.0, w_z2 = 0.5, b_z = 0.0;  // Update gate
   double w_r1 = 1.0, w_r2 = 0.5, b_r = 0.0;  // Reset gate
   double w_h1 = 1.0, w_h2 = 0.5, b_h = 0.0;  // Candidate hidden state

   // Compute gates
   double z_t = sigmoid(w_z1 * s_t + w_z2 * h_prev + b_z);          // Update gate
   double r_t = sigmoid(w_r1 * s_t + w_r2 * h_prev + b_r);          // Reset gate
   double h_tilde = MathTanh(w_h1 * s_t + w_h2 * (r_t * h_prev) + b_h); // Candidate hidden state
   double h_t = (1 - z_t) * h_prev + z_t * h_tilde;                 // New hidden state

   h_prev = h_t;
   return h_t;
}

#endif