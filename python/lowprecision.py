# -*- coding: utf-8 -*-



# Imports.
import cPickle                              as pkl
import math
import numpy                                as np
import os, pdb
import pysnips.ml.experiment                as PySMlExp
import pysnips.ml.loop                      as PySMlL
import pysnips.ml.pytorch                   as PySMlPy
import sys
import torch                                as T
import torch.autograd                       as TA
import torch.cuda                           as TC
import torch.nn                             as TN
import torch.optim                          as TO



#
# Utilities
#

def getExperiment(d):
	return Experiment(d.workDir, d)
def getMNIST(dataDir):
	import gzip
	with gzip.open(os.path.join(dataDir, "mnist.pkl.gz"), "rb") as f:
		trainSet, validSet, testSet = pkl.load(f)
	return trainSet[0], trainSet[1],\
	       validSet[0], validSet[1],\
	       testSet [0], testSet [1]


#
# Experiment Class
#

class Experiment(PySMlExp.Experiment, PySMlL.Callback):
	def __init__(self, workDir, d):
		super(Experiment, self).__init__(workDir, d=d)
		self.__dataDir = d.dataDir
		self.callbacks = [self]
		
		# Dataset load
		self.trainX, self.trainY, \
		self.validX, self.validY, \
		self.testX,  self.testY   = getMNIST(self.dataDir)
		
		# Create Model
		self.model = MNISTTernaryModel(self.d)
		if self.d.cuda is None:
			self.model.cpu()
		else:
			self.model.cuda(self.d.cuda)
		
		
		# Create Optimizer
		if   self.d.optimizer.name == "adam":
			self.optimizer = TO.Adam(self.model.parameters(),
			                         self.d.optimizer.lr,
			                         (self.d.optimizer.beta1,
			                          self.d.optimizer.beta2),
			                         self.d.optimizer.eps)
		elif self.d.optimizer.name == "yellowfin":
			self.optimizer = PySMlPy.YellowFin(self.model.parameters(),
			                                   self.d.optimizer.lr,
			                                   self.d.optimizer.mom,
			                                   self.d.optimizer.beta,
			                                   self.d.optimizer.curvWW,
			                                   self.d.optimizer.nesterov)
		else:
			raise NotImplementedError("Optimizer "+self.d.optimizer.name+" not implemented!")
		
		# Log file
		self.log = open(os.path.join(self.logDir, "results.txt"), "w+")
	
	@property
	def dataDir(self): return self.__dataDir
	@property
	def logDir(self):  return os.path.join(self.workDir, "logs")
	
	
	#
	# Experiment API
	#
	def dump(self, path):
		return self
	def load(self, path):
		return self
	def fromScratch(self):
		super(Experiment, self).fromScratch()
		
		self.loopDict = {
			"std/loop/epochMax": self.d.num_epochs,
			"std/loop/batchMax": len(self.trainX)/self.d.batch_size
		}
		
		return self
	def fromSnapshot(self, path):
		super(Experiment, self).fromSnapshot(path)
		return self
	def run(self):
		self.callbacks = [
			PySMlL.CallbackProgbar(50),
		] + [self] + [
			PySMlL.CallbackLinefeed(),
			PySMlL.CallbackFlush(),
		]
		self.loopDict = PySMlL.loop(self.callbacks, self.loopDict)
		
		return self
	
	#
	# Callback API
	#
	
	def anteTrain(self, d): pass
	def anteEpoch(self, d):
		d["user/epochErr"] = 0
		d["user/epochErr"] = 0
	def anteBatch(self, d): pass
	def execBatch(self, d):
		b = d["std/loop/batchNum"]
		
		#
		# Get the data...
		#
		X = self.trainX[b*self.d.batch_size:(b+1)*self.d.batch_size]
		Y = self.trainY[b*self.d.batch_size:(b+1)*self.d.batch_size]
		if self.d.cuda is None:
			X = T. FloatTensor(X)
			Y = T. LongTensor (Y)
		else:
			X = TC.FloatTensor(X)
			Y = TC.LongTensor (Y)
		X = TA.Variable(X)
		Y = TA.Variable(Y)
		
		#
		# Feed it to model and step the optimizer
		#
		self.optimizer.zero_grad()
		d.update(self.model(X, Y))
		d["user/ceLoss"].backward()
		# Step
		self.optimizer.step()
	def postBatch(self, d): pass
	def postEpoch(self, d):
		d.update(self.validate())
		sys.stdout.write(
			"\nValLoss: {:6.2f}  ValAccuracy: {:6.2f}%".format(
				d["user/valLoss"],
				d["user/valAcc"],
			)
		)
		self.log.write("{:d},{:6.2f},{:6.2f}\n".format(d["std/loop/epochNum"],
		                                               d["user/valLoss"],
		                                               100.0*d["user/valAcc"]))
	def postTrain(self, d): pass
	def finiTrain(self, d): pass
	def finiEpoch(self, d): pass
	def finiBatch(self, d):
		batchNum  = d["std/loop/batchNum"]
		batchSize = self.d.batch_size
		ceLoss    = float(d["user/ceLoss"]  .data.cpu().numpy())
		batchErr  = int  (d["user/batchErr"].data.cpu().numpy())
		d["user/epochErr"] += batchErr
		sys.stdout.write(
			"CE Loss: {:8.6f}  Batch Accuracy: {:6.2f}%  Accuracy: {:6.2f}%".format(
				ceLoss,
				100.0*batchErr/batchSize,
				100.0*d["user/epochErr"]/((batchNum+1)*batchSize)
			)
		)
		
		#self.log.write("{:d},{:6.2f},{:6.2f}\n".format(d["std/loop/stepNum"],
		#                                               ceLoss,
		#                                               100.0*batchErr/batchSize))
		#self.log.flush()
	def preempt  (self, d):
		if d["std/loop/state"] == "anteEpoch" and d["std/loop/epochNum"] > 0:
			self.snapshot()
	
	def validate (self):
		# Switch to validation mode
		self.model.train(False)
		valErr  = 0
		valLoss = 0
		
		numBatches = len(self.validX) // self.d.batch_size
		
		for b in xrange(numBatches):
			#
			# Get the data...
			#
			X = self.validX[b*self.d.batch_size:(b+1)*self.d.batch_size]
			Y = self.validY[b*self.d.batch_size:(b+1)*self.d.batch_size]
			if self.d.cuda is None:
				X = T. FloatTensor(X)
				Y = T. LongTensor (Y)
			else:
				X = TC.FloatTensor(X)
				Y = TC.LongTensor (Y)
			X = TA.Variable(X)
			Y = TA.Variable(Y)
			
			#
			# Feed it to model and step the optimizer
			#
			d = self.model(X, Y)
			valErr  += int  (d["user/batchErr"].data.cpu().numpy())
			valLoss += float(d["user/ceLoss"]  .data.cpu().numpy())
		
		# Switch back to train mode
		self.model.train(True)
		
		valAcc   = float(valErr) / (numBatches*self.d.batch_size)
		valLoss /= numBatches
		
		return {
			"user/valAcc":  valAcc,
			"user/valLoss": valLoss,
		}



class MNISTModel(TN.Module):
	def __init__(self, d):
		super(MNISTModel, self).__init__()
		self.d      = d
		self.conv0  = TN.Conv2d          (  1,  64, (3,3), padding=1)
		self.bn0    = TN.BatchNorm2d     ( 64,  affine=False)
		self.relu0  = TN.ReLU            ()
		self.conv1  = TN.Conv2d          ( 64,  64, (3,3), padding=1)
		self.bn1    = TN.BatchNorm2d     ( 64,  affine=False)
		self.relu1  = TN.ReLU            ()
		self.conv2  = TN.Conv2d          ( 64, 128, (3,3), padding=1, stride=2)
		self.bn2    = TN.BatchNorm2d     (128,  affine=False)
		self.relu2  = TN.ReLU            ()
		self.conv3  = TN.Conv2d          (128, 128, (3,3), padding=1)
		self.bn3    = TN.BatchNorm2d     (128,  affine=False)
		self.relu3  = TN.ReLU            ()
		self.conv4  = TN.Conv2d          (128, 128, (3,3), padding=1)
		self.bn4    = TN.BatchNorm2d     (128,  affine=False)
		self.relu4  = TN.ReLU            ()
		self.conv5  = TN.Conv2d          (128, 256, (3,3), padding=1, stride=2)
		self.bn5    = TN.BatchNorm2d     (256,  affine=False)
		self.relu5  = TN.ReLU            ()
		self.conv6  = TN.Conv2d          (256, 256, (3,3), padding=1)
		self.bn6    = TN.BatchNorm2d     (256,  affine=False)
		self.relu6  = TN.ReLU            ()
		self.conv7  = TN.Conv2d          (256, 256, (3,3), padding=1)
		self.bn7    = TN.BatchNorm2d     (256,  affine=False)
		self.relu7  = TN.ReLU            ()
		self.conv8  = TN.Conv2d          (256, 256, (3,3), padding=1)
		self.bn8    = TN.BatchNorm2d     (256,  affine=False)
		self.relu8  = TN.ReLU            ()
		self.conv9  = TN.Conv2d          (256,  10, (1,1), padding=0)
		self.pool   = TN.MaxPool2d       ((7,7))
		self.celoss = TN.CrossEntropyLoss()
	def forward(self, X, Y):
		v, y     = X.view(self.d.batch_size, 1, 28, 28), Y
		v        = self.relu0(self.bn0(self.conv0(v)))
		v        = self.relu1(self.bn1(self.conv1(v)))
		v        = self.relu2(self.bn2(self.conv2(v)))
		v        = self.relu3(self.bn3(self.conv3(v)))
		v        = self.relu4(self.bn4(self.conv4(v)))
		v        = self.relu5(self.bn5(self.conv5(v)))
		v        = self.relu6(self.bn6(self.conv6(v)))
		v        = self.relu7(self.bn7(self.conv7(v)))
		v        = self.relu8(self.bn8(self.conv8(v)))
		v        = self.pool (self.conv9(v))
		v        = v.view(self.d.batch_size, 10)
		
		ceLoss   = self.celoss(v, y)
		yPred    = T.max(v, 1)[1]
		batchErr = yPred.eq(y).long().sum(0)
		
		return {
			"user/ceLoss":   ceLoss,
			"user/batchErr": batchErr,
			"user/yPred":    yPred,
		}



#
# 33% of the mass of a Gaussian is below   stddev -0.44.
# 33% of the mass of a Gaussian is between stddev -0.44 and +0.44.
# 33% of the mass of a Gaussian is above   stddev +0.44.
#

class TernaryConv(TN.Module):
	def __init__(self, in_channels, out_channels, kernel_size, stride=1,
	             padding=0, dilation=1, groups=1, biased=True, transposed=False,
	             thresh=0.05):
		super(TernaryConv, self).__init__()
		
		self.in_channels  = int(in_channels)
		self.out_channels = int(out_channels)
		self.kernel_size  = TN.modules.utils._pair(kernel_size)
		self.stride       = TN.modules.utils._pair(stride)
		self.padding      = TN.modules.utils._pair(padding)
		self.dilation     = TN.modules.utils._pair(dilation)
		self.groups       = int(groups)
		self.biased       = bool(biased)
		self.transposed   = bool(transposed)
		self.thresh       = float(thresh)
		
		if self.in_channels  % self.groups != 0:
			raise ValueError('in_channels must be divisible by groups')
		if self.out_channels % self.groups != 0:
			raise ValueError('out_channels must be divisible by groups')
		
		if self.transposed:
			self.weight = T .Tensor(self.in_channels,
			                        self.out_channels // self.groups,
			                        *self.kernel_size)
			self.weight = TN.Parameter(self.weight)
		else:
			self.weight = T .Tensor(self.out_channels,
			                        self.in_channels // self.groups,
			                        *self.kernel_size)
			self.weight = TN.Parameter(self.weight)
		if self.biased:
			self.bias   = TN.Parameter(T.Tensor(self.out_channels))
		else:
			self.register_parameter('bias', None)
		
		self.Wp = TN.Parameter(T.Tensor(1))
		self.Wn = TN.Parameter(T.Tensor(1))
		
		self.reset_parameters()
	def reset_parameters(self):
		self.Wp.data.zero_().add_(1.0)
		self.Wn.data.zero_().add_(1.0)
		self.weight.data.uniform_(-1.0, +1.0)
		if self.biased:
			self.bias.data.uniform_(-1.0, +1.0)
	def reconstrain(self):
		self.Wp.data.clamp_(0.0, 1.0)
		self.Wn.data.clamp_(0.0, 1.0)
	def forward(self, input):
		class WFunction(TA.Function):
			@staticmethod
			def forward(ctx, weights, Wp, Wn):
				deltat = self.thresh * weights.abs().max(0)[0].max(0)[0].max(0)[0].max(0)[0]
				wP     = (weights >=  deltat).float()
				wN     = (weights <= -deltat).float()
				w      = Wp*wP - Wn*wN
				
				ctx.save_for_backward(weights, Wp, Wn)
				
				return w
			@staticmethod
			def backward(ctx, dw):
				weights, Wp, Wn = ctx.saved_variables
				
				deltat = self.thresh * weights.abs().max(0)[0].max(0)[0].max(0)[0].max(0)[0]
				wP     = (weights >=  deltat).float()
				wN     = (weights <= -deltat).float()
				
				dweights = Wp  * wP        * dw + \
				           1.0 * (1-wP-wN) * dw + \
				           Wn  * wN        * dw
				dWp      = (wP * dw).sum(0).sum(0).sum(0).sum(0)
				dWn      = (wN * dw).sum(0).sum(0).sum(0).sum(0)
				
				return dweights, dWp, dWn
		
		w = WFunction().apply(self.weight, self.Wp, self.Wn)
		
		return TN.functional.conv2d(input, w, self.bias, self.stride,
		                            self.padding, self.dilation, self.groups)

class TernaryBNTz(TN.BatchNorm2d):
	def forward(self, input):
		class TzFunction(TA.Function):
			@staticmethod
			def forward(ctx, x):
				ctx.save_for_backward(x)
				tzx = (x >= 0.44).float() - (x <= -0.44).float()
				return tzx
			@staticmethod
			def backward(ctx, dx):
				return dx
		
		x = input
		#x = TN.functional.relu(x)
		x = super(TernaryBNTz, self).forward(x)
		return TzFunction().apply(x)

class MNISTTernaryModel(TN.Module):
	def __init__(self, d):
		super(MNISTTernaryModel, self).__init__()
		self.d      = d
		self.conv0  = TernaryConv        (  1,  64, (3,3), padding=1)
		self.bntz0  = TernaryBNTz        ( 64,  affine=False)
		self.conv1  = TernaryConv        ( 64,  64, (3,3), padding=1)
		self.bntz1  = TernaryBNTz        ( 64,  affine=False)
		self.conv2  = TernaryConv        ( 64, 128, (3,3), padding=1, stride=2)
		self.bntz2  = TernaryBNTz        (128,  affine=False)
		self.conv3  = TernaryConv        (128, 128, (3,3), padding=1)
		self.bntz3  = TernaryBNTz        (128,  affine=False)
		self.conv4  = TernaryConv        (128, 128, (3,3), padding=1)
		self.bntz4  = TernaryBNTz        (128,  affine=False)
		self.conv5  = TernaryConv        (128, 256, (3,3), padding=1, stride=2)
		self.bntz5  = TernaryBNTz        (256,  affine=False)
		self.conv6  = TernaryConv        (256, 256, (3,3), padding=1)
		self.bntz6  = TernaryBNTz        (256,  affine=False)
		self.conv7  = TernaryConv        (256, 256, (3,3), padding=1)
		self.bntz7  = TernaryBNTz        (256,  affine=False)
		self.conv8  = TernaryConv        (256, 256, (3,3), padding=1)
		self.bntz8  = TernaryBNTz        (256,  affine=False)
		self.conv9  = TernaryConv        (256,  10, (1,1), padding=0)
		self.pool   = TN.MaxPool2d       ((7,7))
		self.celoss = TN.CrossEntropyLoss()
	def forward(self, X, Y):
		self.conv0.reconstrain()
		self.conv1.reconstrain()
		self.conv2.reconstrain()
		self.conv3.reconstrain()
		self.conv4.reconstrain()
		self.conv5.reconstrain()
		self.conv6.reconstrain()
		self.conv7.reconstrain()
		self.conv8.reconstrain()
		self.conv9.reconstrain()
		
		v, y     = X.view(self.d.batch_size, 1, 28, 28), Y
		v        = self.bntz0(self.conv0(v))
		v        = self.bntz1(self.conv1(v))
		v        = self.bntz2(self.conv2(v))
		v        = self.bntz3(self.conv3(v))
		v        = self.bntz4(self.conv4(v))
		v        = self.bntz5(self.conv5(v))
		v        = self.bntz6(self.conv6(v))
		v        = self.bntz7(self.conv7(v))
		v        = self.bntz8(self.conv8(v))
		v        = self.pool (self.conv9(v))
		v        = v.view(self.d.batch_size, 10)
		
		ceLoss   = self.celoss(v, y)
		yPred    = T.max(v, 1)[1]
		batchErr = yPred.eq(y).long().sum(0)
		
		return {
			"user/ceLoss":   ceLoss,
			"user/batchErr": batchErr,
			"user/yPred":    yPred,
		}
