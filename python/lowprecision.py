# -*- coding: utf-8 -*-



# Imports.
import cPickle                              as pkl
import ipdb
from   ipdb import set_trace as bp
import math
import numpy                                as np
import os
import pysnips.ml.experiment                as PySMlExp
import pysnips.ml.loop                      as PySMlL
import pysnips.ml.pytorch                   as PySMlPy
import sys
import torch                                as T
import torch.autograd                       as TA
import torch.cuda                           as TC
import torch.nn                             as TN
import torch.optim                          as TO
import torch.random                         as TR
import torch.utils                          as TU
import torch.utils.data                     as TUD
import torchvision                          as Tv
import torchvision.transforms               as TvT

from   models                           import *
from   pysnips.ml.eventlogger           import *


class Experiment(PySMlExp.Experiment, PySMlL.Callback):
	def __init__(self, d):
		super(Experiment, self).__init__(d.workDir, d=d)
		self.__dataDir = self.d.dataDir
		
		"""PRNG Seeding"""
		seed = self.d.seed & (2**64-1)
		seed = seed-2**63 if seed>=2**63 else seed   # manual_seed() chokes on unsigned
		TR.manual_seed(seed)
		self._masterPRNGState = TR.get_rng_state()
		self.reseed()
		
		
		"""Dataset Selection"""
		if   self.d.dataset == "mnist":
			self.Dxform  = [TvT.ToTensor()]
			self.Dxform  = TvT.Compose(self.Dxform)
			self.Dtrain  = Tv.datasets.MNIST   (self.dataDir, True,    self.Dxform, download=True)
			self.Dtest   = Tv.datasets.MNIST   (self.dataDir, False,   self.Dxform, download=True)
			self.Dimgsz  = (1, 28, 28)
			self.DNclass = 10
			self.DNvalid = 5000
		elif self.d.dataset == "cifar10":
			self.Dxform  = [TvT.ToTensor()]
			self.Dxform  = TvT.Compose(self.Dxform)
			self.Dtrain  = Tv.datasets.CIFAR10 (self.dataDir, True,    self.Dxform, download=True)
			self.Dtest   = Tv.datasets.CIFAR10 (self.dataDir, False,   self.Dxform, download=True)
			self.Dimgsz  = (3, 32, 32)
			self.DNclass = 10
			self.DNvalid = 5000
		elif self.d.dataset == "cifar100":
			self.Dxform  = [TvT.ToTensor()]
			self.Dxform  = TvT.Compose(self.Dxform)
			self.Dtrain  = Tv.datasets.CIFAR100(self.dataDir, True,    self.Dxform, download=True)
			self.Dtest   = Tv.datasets.CIFAR100(self.dataDir, False,   self.Dxform, download=True)
			self.Dimgsz  = (3, 32, 32)
			self.DNclass = 100
			self.DNvalid = 5000
		elif self.d.dataset == "svhn":
			self.Dxform  = [TvT.ToTensor()]
			self.Dxform  = TvT.Compose(self.Dxform)
			self.Dtrain  = Tv.datasets.SVHN    (self.dataDir, "train", self.Dxform, download=True)
			self.Dtest   = Tv.datasets.SVHN    (self.dataDir, "test",  self.Dxform, download=True)
			self.Dimgsz  = (3, 32, 32)
			self.DNclass = 10
			self.DNvalid = 5000
		else:
			raise ValueError("Unknown dataset \""+self.d.dataset+"\"!")
		self.DNtotal    = len(self.Dtrain)
		self.DNtest     = len(self.Dtest)
		self.DNtrain    = self.DNtotal-self.DNvalid
		
		
		"""Model Instantiation"""
		self.model = None
		if   self.d.model == "real":         self.model = RealModel       (self.d)
		elif self.d.model == "ttq":          self.model = TTQModel        (self.d)
		elif self.d.model == "ttqresnet":    self.model = TTQResnetModel  (self.d)
		elif self.d.model == "ttqresnet32":  self.model = TTQResnet32Model(self.d)
		elif self.d.model == "bnn":          self.model = MatthieuBNN     (self.d)
		if   self.model is None:
			raise ValueError("Unsupported dataset-model pair \""+self.d.dataset+"-"+self.d.model+"\"!")
		
		if self.d.cuda is None:
			self.model.cpu()
		else:
			self.model.cuda(self.d.cuda)
		
		
		
		"""Optimizer Selection"""
		if   self.d.optimizer.name in ["sgd", "nag"]:
			self.optimizer = TO.SGD(self.model.parameters(),
			                        self.d.optimizer.lr,
			                        self.d.optimizer.mom,
			                        nesterov = (self.d.optimizer.name == "nag"))
		elif self.d.optimizer.name == "rmsprop":
			self.optimizer = TO.RMSprop(self.model.parameters(),
			                            self.d.optimizer.lr,
			                            self.d.optimizer.rho,
			                            self.d.optimizer.eps)
		elif self.d.optimizer.name == "adam":
			self.optimizer = TO.Adam(self.model.parameters(),
			                         self.d.optimizer.lr,
			                         (self.d.optimizer.beta1,
			                          self.d.optimizer.beta2),
			                         self.d.optimizer.eps)
		elif self.d.optimizer.name == "yellowfin":
			if False:
				self.optimizer = PySMlPy.YellowFin(self.model.parameters(),
				                                   self.d.optimizer.lr,
				                                   self.d.optimizer.mom,
				                                   self.d.optimizer.beta,
				                                   self.d.optimizer.curvWW,
				                                   self.d.optimizer.nesterov)
			else:
				from pysnips.ml.pytorch.yfoptimizer import YFOptimizer
				self.optimizer = YFOptimizer(self.model.parameters(),
				                             self.d.optimizer.lr,
				                             self.d.optimizer.mom,
				                             clip_thresh    = self.d.clipnorm,
				                             beta           = self.d.optimizer.beta,
				                             curv_win_width = self.d.optimizer.curvWW)
		else:
			raise NotImplementedError("Optimizer "+self.d.optimizer.name+" not implemented!")
	
	
	@property
	def dataDir(self): return self.__dataDir
	@property
	def logDir(self):  return os.path.join(self.workDir, "logs")
	
	def reseed(self):
		"""Reseed all known PRNGs from the master PyTorch PRNG."""
		
		#
		# The following highly-contrived way to generate a new signed Long from 8
		# Byte is necessary because PyTorch does NOT currently generate full-range
		# random numbers for torch.LongTensor(1).random_().
		#
		TR.set_rng_state(self._masterPRNGState)
		r0 = T.LongStorage.from_buffer(T.ByteTensor(8).random_().numpy(), "little")[0]
		r1 = T.LongStorage.from_buffer(T.ByteTensor(8).random_().numpy(), "little")[0]
		r2 = T.LongStorage.from_buffer(T.ByteTensor(8).random_().numpy(), "little")[0]
		self._masterPRNGStatePrev = self._masterPRNGState
		self._masterPRNGState     = TR.get_rng_state()
		
		TR.manual_seed    (r0)
		TC.manual_seed_all(r1)
		np.random.seed    (r2 & 0xFFFFFFFF)
	
	#
	# Experiment API
	#
	def load(self, path):
		state = T.load(os.path.join(path, "snapshot.pkl"))
		self._masterPRNGState        = state["_masterPRNGState"]
		self.loopDict                = state["loopDict"]
		self.model    .load_state_dict(state["model"])
		self.optimizer.load_state_dict(state["optimizer"])
		self.reseed()
		return self
	
	def dump(self, path):
		self.mkdirp(path)
		T.save({
		    "softwareversions": {
		        "torch": T.__dict__.get("__version__", "unknown"),
		    },
		    "_masterPRNGState": self._masterPRNGStatePrev,
		    "loopDict":         self.loopDict,
		    "model":            self.model.state_dict(),
		    "optimizer":        self.optimizer.state_dict(),
		}, os.path.join(path, "snapshot.pkl"))
		return self
	def fromScratch(self):
		self.loopDict = {
			"std/loop/epochMax": self.d.num_epochs,
			"std/loop/batchMax": len(self.Dtrain)/self.d.batch_size
		}
		
		return self
	def fromSnapshot(self, path):
		return self.load(path)
	def run(self):
		#
		# With the RNGs properly seeded, create the dataset iterators.
		#
		
		self.DtrainIdx  = range(self.DNtotal)[:self.DNtrain]
		self.DvalidIdx  = range(self.DNtotal)[-self.DNvalid:]
		self.DtestIdx   = range(self.DNtest)
		self.DtrainSmp  = TUD.sampler.SubsetRandomSampler(self.DtrainIdx)
		self.DvalidSmp  = TUD.sampler.SubsetRandomSampler(self.DvalidIdx)
		self.DtestSmp   = TUD.sampler.SubsetRandomSampler(self.DtestIdx)
		self.DtrainLoad = TUD.DataLoader(dataset     = self.Dtrain,
		                                 batch_size  = self.d.batch_size,
		                                 shuffle     = False,
		                                 sampler     = self.DtrainSmp,
		                                 num_workers = 0,
		                                 pin_memory  = False)
		self.DvalidLoad = TUD.DataLoader(dataset     = self.Dtrain,
		                                 batch_size  = self.d.batch_size,
		                                 shuffle     = False,
		                                 sampler     = self.DvalidSmp,
		                                 num_workers = 0,
		                                 pin_memory  = False)
		self.DtestLoad  = TUD.DataLoader(dataset     = self.Dtest,
		                                 batch_size  = self.d.batch_size,
		                                 shuffle     = False,
		                                 sampler     = self.DtestSmp,
		                                 num_workers = 0,
		                                 pin_memory  = False)
		
		#
		# Set up the callback system.
		#
		
		self.callbacks = [
			PySMlL.CallbackProgbar(50),
		] + [self] + [
			PySMlL.CallbackLinefeed(),
			PySMlL.CallbackFlush(),
		]
		
		#
		# Run training loop.
		#
		
		with EventLogger(self.logDir):
			self.loopDict = PySMlL.loop(self.callbacks, self.loopDict)
		
		return self
	
	#
	# Callback API
	#
	
	def anteTrain(self, d): pass
	def anteEpoch(self, d):
		d["user/epochErr"] = 0
		d["user/epochErr"] = 0
		
		self.model.train()
		self.DtrainIter = enumerate(self.DtrainLoad)
		self.DvalidIter = enumerate(self.DvalidLoad)
		self.DtestIter  = enumerate(self.DtestLoad)
	def anteBatch(self, d):
		I, (X, Y) = self.DtrainIter.next()
		if self.d.cuda is None:
			X, Y = X.cpu(), Y.cpu()
		else:
			X, Y = X.cuda(self.d.cuda), Y.cuda(self.d.cuda)
		X, Y = TA.Variable(X), TA.Variable(Y)
		d["user/X"], d["user/Y"] = X, Y
	def execBatch(self, d):
		self.optimizer.zero_grad()
		d.update(self.model(d["user/X"], d["user/Y"]))
		d["user/ceLoss"].backward()
		self.optimizer.step()
	def postBatch(self, d): pass
	def postEpoch(self, d):
		d.update(self.validate())
		sys.stdout.write(
			"\nValLoss: {:6.2f}  ValAccuracy: {:6.2f}%".format(
				d["user/valLoss"],
				100.0*d["user/valAcc"],
			)
		)
		
		# LR decay hack.
		for pgroup in self.optimizer.state_dict()["param_groups"]:
			pgroup["lr"] *= (3e-7/self.d.optimizer.lr)**(1./self.d.num_epochs)
		
		# TensorBoard logging
		logScalar("valLoss", d["user/valLoss"])
		logScalar("valAcc",  d["user/valAcc"])
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
			"CE Loss: {:10.6f}  Batch Accuracy: {:6.2f}%  Accuracy: {:6.2f}%".format(
				ceLoss,
				100.0*batchErr/batchSize,
				100.0*d["user/epochErr"]/((batchNum+1)*batchSize)
			)
		)
		logScalar("ceLoss",   ceLoss)
		logScalar("batchAcc", float(batchErr)/batchSize)
		getEventLogger().step()
	def preempt  (self, d):
		if d["std/loop/state"] == "anteEpoch" and d["std/loop/epochNum"] > 0:
			self.snapshot()
	
	def validate (self):
		# Switch to validation mode
		self.model.eval()
		valErr  = 0
		valLoss = 0
		
		N       = 0
		B       = 0
		
		for I, (X, Y) in self.DvalidIter:
			if self.d.cuda is None:
				X, Y = X.cpu(), Y.cpu()
			else:
				X, Y = X.cuda(self.d.cuda), Y.cuda(self.d.cuda)
			X, Y = TA.Variable(X), TA.Variable(Y)
			
			#
			# Feed it to model and step the optimizer
			#
			d = self.model(X, Y)
			valErr  += int  (d["user/batchErr"].data.cpu().numpy())
			valLoss += float(d["user/ceLoss"]  .data.cpu().numpy())
			N       += len(X)
			B       += 1
		
		# Switch back to train mode
		self.model.train()
		
		valAcc   = float(valErr) / N
		valLoss /= B
		
		return {
			"user/valAcc":  valAcc,
			"user/valLoss": valLoss,
		}

