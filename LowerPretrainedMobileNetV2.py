import torch
import torchvision
import coremltools as ct

from torchvision.models import MobileNet_V2_Weights

torch_model = torchvision.models.mobilenet_v2(weights=MobileNet_V2_Weights.DEFAULT)
torch_model.eval()

example_input_224 = torch.rand(1, 3, 224, 224) 
example_input_225 = torch.rand(1, 3, 225, 225)

traced_model = torch.jit.trace(torch_model, example_input_224)

shapes = [example_input_224.shape, example_input_225.shape]
enumerated_shape = ct.EnumeratedShapes(shapes=shapes)
flexible_shape = ct.Shape(shape=(1, 3, ct.RangeDim(224, 230), ct.RangeDim(224, 230)))

model = ct.convert(
  traced_model,
  inputs=[ct.TensorType(shape=example_input_224.shape)]
)
model.save("mobilenetv2.mlmodel")


model_enumerated = ct.convert(
  traced_model,
  inputs=[ct.TensorType(shape=enumerated_shape)]
)
model_enumerated.save("mobilenetv2_enumerated.mlmodel")


model_flexible = ct.convert(
  traced_model,
  inputs=[ct.TensorType(shape=flexible_shape)]
)
model_flexible.save("mobilenetv2_flexible.mlmodel")
