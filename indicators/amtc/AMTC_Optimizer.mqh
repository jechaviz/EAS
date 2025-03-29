//+------------------------------------------------------------------+
//|                      AMTC_Optimizer.mqh                          |
//+------------------------------------------------------------------+
#ifndef AMTC_OPTIMIZER_MQH
#define AMTC_OPTIMIZER_MQH

#include "AMTC_Utils.mqh" // Added to access CalculateHMA

// Genetic Algorithm Parameter Optimization
void OptimizeParameters(int shortPeriod, int mediumPeriod, int longPeriod) {
   const int populationSize = 20, generations = 10;
   double population[][3], fitness[];
   ArrayResize(population, populationSize);
   ArrayResize(fitness, populationSize);

   // Initialize population
   for(int i = 0; i < populationSize; i++) {
      population[i][0] = shortPeriod * (0.5 + i * 0.05);
      population[i][1] = mediumPeriod * (0.5 + i * 0.05);
      population[i][2] = longPeriod * (0.5 + i * 0.05);
   }

   // Evolutionary loop
   for(int gen = 0; gen < generations; gen++) {
      for(int i = 0; i < populationSize; i++) {
         fitness[i] = SimulateReturns(population[i][0], population[i][1], population[i][2]);
      }

      // Selection and crossover
      double newPopulation[][3];
      ArrayResize(newPopulation, populationSize);
      for(int i = 0; i < populationSize; i += 2) {
         int parent1 = SelectParent(fitness);
         int parent2 = SelectParent(fitness);
         for(int j = 0; j < 3; j++) {
            newPopulation[i][j] = population[parent1][j] * 0.5 + population[parent2][j] * 0.5;
            if(i + 1 < populationSize) {
               newPopulation[i + 1][j] = population[parent1][j] * 0.7 + population[parent2][j] * 0.3;
            }
         }
      }

      // Mutation
      for(int i = 0; i < populationSize; i++) {
         if(MathRand() / 32767.0 < 0.1) {
            for(int j = 0; j < 3; j++) {
               newPopulation[i][j] += (MathRand() / 32767.0 - 0.5) * (j == 0 ? shortPeriod : (j == 1 ? mediumPeriod : longPeriod)) * 0.2;
            }
         }
         newPopulation[i][0] = MathMax(5, MathMin(shortPeriod * 2, newPopulation[i][0]));
         newPopulation[i][1] = MathMax(5, MathMin(mediumPeriod * 2, newPopulation[i][1]));
         newPopulation[i][2] = MathMax(5, MathMin(longPeriod * 2, newPopulation[i][2]));
      }
      ArrayCopy(population, newPopulation);
   }

   // Select best
   int bestIdx = 0;
   for(int i = 1; i < populationSize; i++) {
      if(fitness[i] > fitness[bestIdx]) bestIdx = i;
   }
   shortPeriod = (int)population[bestIdx][0];
   mediumPeriod = (int)population[bestIdx][1];
   longPeriod = (int)population[bestIdx][2];
   Print("Optimized Periods: Short=", shortPeriod, ", Medium=", mediumPeriod ", Long=", longPeriod);
}

// Simulate returns for fitness evaluation
double SimulateReturns(double shortPeriod, double mediumPeriod, double longPeriod) {
   double price[];
   if(CopyClose(_Symbol, _Period, 0, 100, price) < 100) return 0.0;
   double sumReturns = 0.0;
   for(int i = 1; i < 100; i++) {
      double hmaShort = CalculateHMA(price, i, (int)shortPeriod, 100);
      double hmaMedium = CalculateHMA(price, i, (int)mediumPeriod, 100);
      double hmaLong = CalculateHMA(price, i, (int)longPeriod, 100);
      double prevHmaMedium = CalculateHMA(price, i - 1, (int)mediumPeriod, 100);
      if(hmaShort > hmaMedium && hmaMedium > hmaLong && hmaMedium > prevHmaMedium) {
         sumReturns += price[i] - price[i-1];
      }
      else if(hmaShort < hmaMedium && hmaMedium < hmaLong && hmaMedium < prevHmaMedium) {
         sumReturns += price[i-1] - price[i];
      }
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