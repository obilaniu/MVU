#!/usr/bin/env python
# -*- coding: utf-8 -*-


#Imports
import numpy                                as np
import os, pdb, sys
import torch                                as T
import torch.autograd                       as TA
import torch.cuda                           as TC
import torch.nn                             as TN
import torch.nn.functional                  as TNF
import torch.optim                          as TO

from   functional                       import *



#
# PyTorch Convolution Layers
#

class Conv2dTTQ(TN.Conv2d):
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


class Conv2dBNN(TN.Conv2d):
	"""
	Convolution layer for BinaryNet
	"""
	
	def __init__(self, in_channels, out_channels, kernel_size, stride=1,
	             padding=0, dilation=1, groups=1, bias=True, H=1.0, W_LR_scale="Glorot"):
		num_inputs = reduce(lambda a,b:a*b, kernel_size+(in_channels,),  1)
		num_units  = reduce(lambda a,b:a*b, kernel_size+(out_channels,), 1)
		if H == "Glorot":
			self.H          = float(np.sqrt(1.5/(num_inputs + num_units)))
		else:
			self.H          = H
		
		if W_LR_scale == "Glorot":
			self.W_LR_scale = float(np.sqrt(1.5/(num_inputs + num_units)))
		else:
			self.W_LR_scale = self.H
		
		super(Conv2dBNN, self).__init__(in_channels, out_channels, kernel_size,
		                                stride, padding, dilation, groups, bias)
		
		self.reset_parameters()
	def reset_parameters(self):
		self.weight.data.uniform_(-self.H, +self.H)
		if isinstance(self.bias, TN.Parameter):
			self.bias.data.zero_()
	def reconstrain(self):
		self.weight.data.clamp_(-self.H, +self.H)
	def forward(self, input):
		Wb = bnn_round3(self.weight/self.H)*self.H
		return TNF.conv2d(input,
		                  Wb,
		                  self.bias, self.stride, self.padding,
		                  self.dilation, self.groups)



#
# PyTorch Dense Layers
#

class LinearBNN(TN.Linear):
	"""
	Linear/Dense layer for BinaryNet
	"""
	
	def __init__(self, in_channels, out_channels, bias=True, H=1.0, W_LR_scale="Glorot"):
		num_inputs = reduce(lambda a,b:a*b, (in_channels,),  1)
		num_units  = reduce(lambda a,b:a*b, (out_channels,), 1)
		if H == "Glorot":
			self.H          = float(np.sqrt(1.5/(num_inputs + num_units)))
		else:
			self.H          = H
		
		if W_LR_scale == "Glorot":
			self.W_LR_scale = float(np.sqrt(1.5/(num_inputs + num_units)))
		else:
			self.W_LR_scale = self.H
		
		super(LinearBNN, self).__init__(in_channels, out_channels, bias)
		
		self.reset_parameters()
	def reset_parameters(self):
		self.weight.data.uniform_(-self.H, +self.H)
		if isinstance(self.bias, TN.Parameter):
			self.bias.data.zero_()
	def reconstrain(self):
		self.weight.data.clamp_(-self.H, +self.H)
	def forward(self, input):
		Wb = bnn_round3(self.weight/self.H)*self.H
		return TNF.linear(input, Wb, self.bias)





#
# PyTorch BN/Quantization Layers.
#

class BatchNorm2dTz(TN.BatchNorm2d):
	def __init__(self, num_features, eps=1e-5, momentum=0.1, lo=-0.44, hi=+0.44):
		super(BatchNorm2dTz, self).__init__(num_features, eps, momentum, False)
		
		self.lo = TN.Parameter(T.Tensor([float(lo)]))
		self.hi = TN.Parameter(T.Tensor([float(hi)]))
	def forward(self, x):
		x = super(BatchNorm2dTz, self).forward(x)
		x = Thresh3.apply(x, self.lo, self.hi)
		return x




#
# PyTorch Non-Linearities
#

class BNNTanh(TN.Module):
	def __init__(self):
		super(BNNTanh, self).__init__()
	
	def forward(self, x):
		return bnn_round3(x)


