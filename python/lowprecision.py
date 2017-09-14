# -*- coding: utf-8 -*-



# Imports.
import cPickle                              as pkl
import numpy                                as np
import os
import pysnips.ml.experiment                as PySMlExp
import pysnips.ml.loop                      as PySMlL
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
		self.model = Model(self.d)
		
		
		# Create Optimizer
		if   self.d.optimizer.name == "adam":
			self.optimizer = TO.Adam(self.model.parameters(),
			                         self.d.optimizer.lr,
			                         (self.d.optimizer.beta1,
			                          self.d.optimizer.beta2),
			                         self.d.optimizer.eps)
		else:
			raise NotImplementedError("Optimizer "+self.d.optimizer.name+" not implemented!")
	
	@property
	def dataDir(self): return self.__dataDir
	
	
	#
	# Experiment API
	#
	def dump(path):
		return self
	def load(path):
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
		self.callbacks += [
			PySMlL.CallbackProgbar(50),
			PySMlL.CallbackLinefeed(),
			PySMlL.CallbackFlush(),
		]
		self.loopDict = PySMlL.loop(self.callbacks, self.loopDict)
		
		return self
	
	#
	# Callback API
	#
	
	def anteTrain(self, d): pass
	def anteEpoch(self, d): pass
	def anteBatch(self, d): pass
	def execBatch(self, d):
		b = d["std/loop/batchNum"]
		
		#
		# Get the data...
		#
		X = T.Variable(self.trainX[b*self.d.batch_size:(b+1)*self.d.batch_size])
		Y = T.Variable(self.trainY[b*self.d.batch_size:(b+1)*self.d.batch_size])
		
		#
		# Feed it to model and step the optimizer
		#
		self.optimizer.zero_grad()
		d["/user/loss"] = self.model(X,Y)
		d["/user/loss"].backward()
		self.optimizer.step()
	def postBatch(self, d): pass
	def postEpoch(self, d): pass
	def postTrain(self, d): pass
	def finiTrain(self, d): pass
	def finiEpoch(self, d): pass
	def finiBatch(self, d): pass
	def preempt  (self, d):
		# Choose a more intelligent snapshot rule here
		if False:
			self.snapshot()



class Model(TN.Module):
	def __init__(self, d):
		super(Model, self).__init__()
		self.conv = TN.Conv2d(64, 64, (3,3))
