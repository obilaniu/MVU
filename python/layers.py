# -*- coding: utf-8 -*-
import numpy                                as np
import torch
import torch.nn.functional                  as TNF

from   functional                       import *



#
# PyTorch Convolution Layers
#

class Conv2dTTQ(torch.nn.Conv2d):
	"""
	Convolution layer for TTQ
	"""
	
	def __init__(self, in_channels, out_channels, kernel_size, stride=1,
	             padding=0, dilation=1, groups=1, bias=True, thresh=0.05):
		super(Conv2dTTQ, self).__init__(in_channels, out_channels, kernel_size,
		                                stride, padding, dilation, groups, bias)
		
		self.thresh = TN.Parameter(T.Tensor([float(thresh)]))
		self.Wp     = TN.Parameter(T.Tensor([1.0]))
		self.Wn     = TN.Parameter(T.Tensor([1.0]))
		
		self.reset_parameters()
	def reset_parameters(self):
		if hasattr(self, "Wp"): self.Wp.data.zero_().add_(1.0)
		if hasattr(self, "Wn"): self.Wn.data.zero_().add_(1.0)
		self.weight.data.uniform_(-1.0, +1.0)
		if isinstance(self.bias, TN.Parameter):
			self.bias.data.uniform_(-1.0, +1.0)
	def reconstrain(self):
		self.Wp.data.clamp_(0.0, 1.0)
		self.Wn.data.clamp_(0.0, 1.0)
	def forward(self, input):
		return TNF.conv2d(input,
		                  TTQW.apply(self.weight, self.Wp, self.Wn, self.thresh),
		                  self.bias, self.stride, self.padding,
		                  self.dilation, self.groups)


class Conv2dBNN(torch.nn.Conv2d):
	"""
	Convolution layer for BinaryNet.
	"""
	
	def __init__(self, in_channels,
	                   out_channels,
	                   kernel_size,
	                   stride       = 1,
	                   padding      = 0,
	                   dilation     = 1,
	                   groups       = 1,
	                   bias         = True,
	                   H            = 1.0,
	                   W_LR_scale   = "Glorot",
	                   override     = "matt"):
		#
		# Fan-in/fan-out computation
		#
		num_inputs = in_channels
		num_units  = out_channels
		for x in kernel_size:
			num_inputs *= x
			num_units  *= x
		
		if H == "Glorot":
			self.H          = float(np.sqrt(1.5/(num_inputs + num_units)))
		else:
			self.H          = H
		
		if W_LR_scale == "Glorot":
			self.W_LR_scale = float(np.sqrt(1.5/(num_inputs + num_units)))
		else:
			self.W_LR_scale = self.H
		
		self.override = override
		
		super().__init__(in_channels, out_channels, kernel_size,
		                 stride, padding, dilation, groups, bias)
		self.reset_parameters()
	
	def reset_parameters(self):
		self.weight.data.uniform_(-self.H, +self.H)
		if isinstance(self.bias, torch.nn.Parameter):
			self.bias.data.zero_()
	
	def constrain(self):
		self.weight.data.clamp_(-self.H, +self.H)
	
	def forward(self, x):
		if   self.override == "matt":
			Wb = bnn_sign(self.weight/self.H)*self.H
		elif self.override == "pass":
			Wb = bnn_sign_pass(self.weight/self.H)*self.H
		return TNF.conv2d(x, Wb, self.bias, self.stride, self.padding,
		                  self.dilation, self.groups)


#
# PyTorch Dense Layers
#

class LinearBNN(torch.nn.Linear):
	"""
	Linear/Dense layer for BinaryNet.
	"""
	
	def __init__(self, in_channels,
	                   out_channels,
	                   bias         = True,
	                   H            = 1.0,
	                   W_LR_scale   = "Glorot",
	                   override     = "matt"):
		#
		# Fan-in/fan-out computation
		#
		num_inputs = in_channels
		num_units  = out_channels
		
		if H == "Glorot":
			self.H          = float(np.sqrt(1.5/(num_inputs + num_units)))
		else:
			self.H          = H
		
		if W_LR_scale == "Glorot":
			self.W_LR_scale = float(np.sqrt(1.5/(num_inputs + num_units)))
		else:
			self.W_LR_scale = self.H
		
		self.override = override
		
		super().__init__(in_channels, out_channels, bias)
		self.reset_parameters()
	
	def reset_parameters(self):
		self.weight.data.uniform_(-self.H, +self.H)
		if isinstance(self.bias, torch.nn.Parameter):
			self.bias.data.zero_()
	
	def constrain(self):
		self.weight.data.clamp_(-self.H, +self.H)
	
	def forward(self, input):
		if   self.override == "matt":
			Wb = bnn_sign(self.weight/self.H)*self.H
		elif self.override == "pass":
			Wb = bnn_sign_pass(self.weight/self.H)*self.H
		return TNF.linear(input, Wb, self.bias)



#
# PyTorch Non-Linearities
#

class SignBNN(torch.nn.Module):
	def __init__(self, override="matt"):
		super().__init__()
		self.override = override
	def forward(self, x):
		if   self.override == "matt":
			return bnn_sign(x)
		elif self.override == "pass":
			return bnn_sign_pass(x)

class PACT(torch.nn.Module):
	def __init__(self):
		super().__init__()
		self.alpha = torch.nn.Parameter(torch.tensor(10.0, dtype=torch.float32))
	
	def forward(self, x):
		return pact(x, self.alpha)

class BNNTanh(torch.nn.Module):
	def __init__(self):
		super().__init__()
	
	def forward(self, x):
		return bnn_round3(x)



#
# PyTorch BN/Quantization Layers.
#

class BatchNorm2dTz(torch.nn.BatchNorm2d):
	def __init__(self, num_features, eps=1e-5, momentum=0.1, lo=-0.44, hi=+0.44):
		super().__init__(num_features, eps, momentum, False)
		
		self.lo = torch.nn.Parameter(torch.FloatTensor([float(lo)]))
		self.hi = torch.nn.Parameter(torch.FloatTensor([float(hi)]))
	def forward(self, x):
		x = super().forward(x)
		x = Thresh3.apply(x, self.lo, self.hi)
		return x

