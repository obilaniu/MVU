# -*- coding: utf-8 -*-
import torch


class BNNSign(torch.autograd.Function):
	"""
	BinaryNet q = Sign(r) with gradient override.
	Equation (1) and (4) of https://arxiv.org/pdf/1602.02830.pdf
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

bnn_sign = BNNSign.apply


class BNNSignPass(torch.autograd.Function):
	"""
	BinaryNet q = Sign(r) with gradient override.
	Same as BNNSign except that gradient is passed through unchanged.
	"""
	
	@staticmethod
	def forward(ctx, x):
		return x.sign()
	
	@staticmethod
	def backward(ctx, dx):
		return dx

bnn_sign_pass = BNNSignPass.apply


class PACTFunction(torch.autograd.Function):
	"""
	Parametrized Clipping Activation Function
	https://arxiv.org/pdf/1805.06085.pdf
	"""
	
	@staticmethod
	def forward(ctx, x, alpha=10.0, k=0):
		alpha = torch.tensor(alpha).to(x)
		k     = torch.tensor(k    ).to('cpu', torch.int64)
		ctx.save_for_backward(x, alpha, k)
		return x.clamp(min=0.0).min(alpha)
	
	@staticmethod
	def backward(ctx, dLdy):
		x, alpha, k = ctx.saved_variables
		
		lt0      = x < 0
		gta      = x > alpha
		gi       = 1.0-lt0.float()-gta.float()
		
		dLdx     = dLdy*gi
		dLdalpha = torch.sum(dLdy*x.ge(alpha).float())
		return dLdx, dLdalpha, None

pact          = PACTFunction.apply


class BiPACTFunction(torch.autograd.Function):
	"""
	Bipolar Parametrized Clipping Activation Function
	https://arxiv.org/pdf/1709.04054.pdf
	https://arxiv.org/pdf/1805.06085.pdf
	"""
	
	@staticmethod
	def forward(ctx, x, alpha=10.0, k=0):
		alpha = torch.tensor(alpha).to(x)
		k     = torch.tensor(k    ).to('cpu', torch.int64)
		M     = torch.arange(2, 2*x.size(1)+2, 2)&2
		M     = M.sub_(1).repeat([1]*x.dim()).transpose_(1,-1).to(x)
		
		x     = x*M
		ctx.save_for_backward(x, alpha, k, M)
		return x.clamp(min=0.0).min(alpha).mul(M)
	
	@staticmethod
	def backward(ctx, dLdy):
		x, alpha, k, M = ctx.saved_variables
		
		lt0      = x < 0
		gta      = x > alpha
		gi       = 1.0-lt0.float()-gta.float()
		
		dLdx     = dLdy*gi*M
		dLdalpha = torch.sum(dLdy*x.ge(alpha).float())
		return dLdx, dLdalpha, None

bipact        = BiPACTFunction.apply



class TTQW(torch.autograd.Function):
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


class Thresh3(torch.autograd.Function):
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


class Residual3(torch.autograd.Function):
	"""
	Ternarized ResNet residual connection.
	"""
	
	@staticmethod
	def forward(ctx, a, b):
		return torch.clamp(a+b, -1, +1)
	@staticmethod
	def backward(ctx, dx):
		return dx, dx


class BNNRound3(torch.autograd.Function):
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


