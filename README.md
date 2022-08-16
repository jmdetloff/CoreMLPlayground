# CoreMLPlayground
A small project to serve as a demonstration of model load times.

Tap 'Load for All Units' to load a model using MLComputeUnitsAll. Tap 'Load for CPU' to load a model with MLComputeUnitsCPUOnly. The time to load is printed to the console.

Expected result:
Model's load slowly the first time they are loaded, but subsequent loads even across app restarts are faster.

Observed result:
When the compute units are set to MLComputeUnitsAll, the first load of a model in each run of the process is much slower than subsequent loads.
