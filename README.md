# CoreMLPlayground
A small project to serve as a demonstration of model load times and inference time of models with different input types.

Tap 'Load for All Units' to load a model using MLComputeUnitsAll. Tap 'Load for CPU' to load a model with MLComputeUnitsCPUOnly. The time to load is printed to the console.

Expected result:
Model's load slowly the first time they are loaded, but subsequent loads even across app restarts are faster.

Observed result:
When the compute units are set to MLComputeUnitsAll, the first load of a model in each run of the process is much slower than subsequent loads.

Tap 'Benchmark input types' to kick off a benchmarking process that runs inference on three instances of MobileNetV2. One lowered with a fixed input shape, one lowered with a flexible input shape, and one lowered with an enumerated input shape. The average inference duration for each model will be printed to the console.

Expected result:
The inference time for these models will be roughly the same.

Observed result:
On iPhone 11 the model lowered with enumerated input shape takes ~5x time to perform inference.
