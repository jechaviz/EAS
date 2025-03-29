// # AMTC_Optimizer.mqh
#ifndef AMTC_OPTIMIZER_MQH
#define AMTC_OPTIMIZER_MQH

// # Genetic Algorithm Parameter Optimization
void OptimizeParameters(int &basePeriod) {
   const int populationSize = 10;
   const int generations = 5;
   double population[], fitness[];
   ArrayResize(population, populationSize);
   ArrayResize(fitness, populationSize);

   // Initialize population
   for(int i = 0; i < populationSize; i++) {
      population[i] = basePeriod * (0.5 + i * 0.1);
   }

   // Evolutionary loop
   for(int gen = 0; gen < generations; gen++) {
      // Evaluate fitness (simplified Sharpe ratio proxy)
      for(int i = 0; i < populationSize; i++) {
         double period = population[i];
         double returns = SimulateReturns(period); // Mock simulation
         fitness[i] = returns / (period * 0.01); // Reward shorter periods with good returns
      }

      // Selection and crossover
      double newPopulation[];
      ArrayResize(newPopulation, populationSize);
      for(int i = 0; i < populationSize; i += 2) {
         int parent1 = SelectParent(fitness);
         int parent2 = SelectParent(fitness);
         newPopulation[i] = population[parent1] * 0.5 + population[parent2] * 0.5;
         if(i + 1 < populationSize) {
            newPopulation[i + 1] = population[parent1] * 0.7 + population[parent2] * 0.3;
         }
      }

      // Mutation
      for(int i = 0; i < populationSize; i++) {
         if(MathRand() / 32767.0 < 0.1) {
            newPopulation[i] += (MathRand() / 32767.0 - 0.5) * basePeriod * 0.2;
         }
         newPopulation[i] = MathMax(5, MathMin(basePeriod * 2, newPopulation[i]));
      }
      ArrayCopy(population, newPopulation);
   }

   // Select best
   int bestIdx = 0;
   for(int i = 1; i < populationSize; i++) {
      if(fitness[i] > fitness[bestIdx]) bestIdx = i;
   }
   basePeriod = (int)population[bestIdx];
}

// # Simulate returns for fitness evaluation
double SimulateReturns(double period) {
   double price[];
   if(CopyClose(_Symbol, _Period, 0, 100, price) < 100) return 0.0;
   double sumReturns = 0.0;
   for(int i = 1; i < 100; i++) {
      double hma = CalculateHMA(price, i, (int)period, 100);
      double prevHma = CalculateHMA(price, i - 1, (int)period, 100);
      sumReturns += (hma > prevHma) ? (price[i] - price[i-1]) : 0;
   }
   return sumReturns;
}

// # Tournament selection for genetic algorithm
int SelectParent(double &fitness[]) {
   int idx1 = MathRand() % ArraySize(fitness);
   int idx2 = MathRand() % ArraySize(fitness);
   return fitness[idx1] > fitness[idx2] ? idx1 : idx2;
}

#endif