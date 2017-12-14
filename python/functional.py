#!/usr/bin/env python
# -*- coding: utf-8 -*-


#Imports
import numpy                                as np
import os, pdb, sys
import torch                                as T
import torch.autograd                       as TA
import torch.cuda                           as TC
import torch.nn                             as TN
import torch.optim                          as TO



class TTQW(TA.Function):
	"""
	TTQ Weight Quantization and Gradient Override.
	"""
	
	@staticmethod
	def forward(ctx, weights, Wp, Wn, thresh):
		deltat = thresh * weights.abs().max(0)[0].max(0)[0].max(0)[0].max(0)[0]
		wP     = (weights >=  deltat).float()
		wN     = (weights <= -deltat).float()
		w      = Wp*wP - Wn*wN
		
		ctx.save_for_backward(weights, Wp, Wn, thresh)
		
		return w
	@staticmethod
	def backward(ctx, dw):
		weights, Wp, Wn, thresh = ctx.saved_variables
		
		deltat = thresh * weights.abs().max(0)[0].max(0)[0].max(0)[0].max(0)[0]
		wP     = (weights >=  deltat).float()
		wN     = (weights <= -deltat).float()
		
		dweights = Wp  * wP        * dw + \
		           1.0 * (1-wP-wN) * dw + \
		           Wn  * wN        * dw
		dWp      = (wP * dw).sum(0).sum(0).sum(0).sum(0)
		dWn      = (wN * dw).sum(0).sum(0).sum(0).sum(0)
		
		return dweights, dWp, dWn, None


class Thresh3(TA.Function):
	"""
	Threshold ternarization.
	"""
	
	@staticmethod
	def forward(ctx, x, lo, hi):
		#
		# Justification for defaults:
		#
		# 33% of the mass of a Gaussian is below   stddev -0.44.
		# 33% of the mass of a Gaussian is between stddev -0.44 and +0.44.
		# 33% of the mass of a Gaussian is above   stddev +0.44.
		#
		
		ctx.save_for_backward(x)
		tzx = (x >= hi).float() - (x <= lo).float()
		return tzx
	@staticmethod
	def backward(ctx, dx):
		return dx, None, None


class Residual3(TA.Function):
	"""
	Ternarized ResNet residual connection.
	"""
	
	@staticmethod
	def forward(ctx, a, b):
		return T.clamp(a+b, -1, +1)
	@staticmethod
	def backward(ctx, dx):
		return dx, dx


class BNNRound3(TA.Function):
	"""
	BinaryNet rounding with gradient override
	"""
	
	@staticmethod
	def forward(ctx, x):
		ctx.save_for_backward(x)
		return x.sign()
	
	@staticmethod
	def backward(ctx, dx):
		x, = ctx.saved_variables
		
		gt1  = x > +1
		lsm1 = x < -1
		gi   = 1-gt1.float()-lsm1.float()
		
		return gi*dx

bnn_round3 = BNNRound3.apply


