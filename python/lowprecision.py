# -*- coding: utf-8 -*-



# Imports.
import cPickle                              as pkl
import ipdb
from   ipdb import set_trace as bp
import math
import numpy                                as np
import os
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

from   pysnips.ml.eventlogger           import *
from   pysnips.ml.experiment            import (Experiment)

from   models                           import *


class Experiment(Experiment):
	def __init__(self, d):
		super(Experiment, self).__init__(d.workDir)
		self.d = d
		self.S = type("PlainObject", (object,), {})()
		self.mkdirp(self.logDir)
		self.fromScratch()
	
	@property
	def dataDir(self):
		return self.d.dataDir
	
	@property
	def logDir(self):
		return os.path.join(self.workDir, "logs")
	
	def reseed(self):
		"""Reseed all known PRNGs from the master PyTorch PRNG."""
		
		#
		# The following highly-contrived way to generate a new signed Long from 8
		# Byte is necessary because PyTorch does NOT currently generate full-range
		# random numbers for torch.LongTensor(1).random_().
		#
		TR.set_rng_state(self.S.masterPRNGState)
		r0 = T.LongStorage.from_buffer(T.ByteTensor(8).random_().numpy(), "little")[0]
		r1 = T.LongStorage.from_buffer(T.ByteTensor(8).random_().numpy(), "little")[0]
		r2 = T.LongStorage.from_buffer(T.ByteTensor(8).random_().numpy(), "little")[0]
		self.S.masterPRNGStatePrev = self.S.masterPRNGState
		self.S.masterPRNGState     = TR.get_rng_state()
		
		TR.manual_seed    (r0)
		TC.manual_seed_all(r1)
		np.random.seed    (r2 & 0xFFFFFFFF)
		
		return self
	
	#
	# Experiment API
	#
	def load(self, path):
		snapFile = os.path.join(path, "snapshot.pkl")
		S        = T.load(snapFile)
		
		self.S.epoch                   = S["epoch"]
		self.S.step                    = S["step"]
		self.S.masterPRNGState         = S["masterPRNGState"]
		self.S.model    .load_state_dict(S["model"])
		self.S.optimizer.load_state_dict(S["optimizer"])
		
		return self
	
	def dump(self, path):
		self.mkdirp(path)
		snapFile = os.path.join(path, "snapshot.pkl")
		S        = {
		    "softwareversions": {
		        "torch": T.__dict__.get("__version__", "unknown"),
		    },
		    "epoch":            self.S.epoch,
		    "step":             self.eventLogger._currentStep,
		    "masterPRNGState":  self.S.masterPRNGStatePrev,
		    "model":            self.S.model.state_dict(),
		    "optimizer":        self.S.optimizer.state_dict(),
		}
		
		T.save(S, snapFile)
		
		return self
	
	def fromScratch(self):
		"""Training State"""
		self.S.epoch = 0
		self.S.step  = 0
		
		
		"""PRNG Seeding"""
		T.manual_seed(int(np.random.randint(0, 2**64, 1, np.uint64).astype(np.int64)))
		self.S.masterPRNGState = TR.get_rng_state()
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
		if   self.d.model == "real":         self.S.model = RealModel       (self.d)
		elif self.d.model == "ttq":          self.S.model = TTQModel        (self.d)
		elif self.d.model == "ttqresnet":    self.S.model = TTQResnetModel  (self.d)
		elif self.d.model == "ttqresnet32":  self.S.model = TTQResnet32Model(self.d)
		elif self.d.model == "bnn":          self.S.model = MatthieuBNN     (self.d)
		if   self.S.model is None:
			raise ValueError("Unsupported dataset-model pair \""+self.d.dataset+"-"+self.d.model+"\"!")
		
		if self.d.cuda is None:
			self.S.model.cpu()
		else:
			self.S.model.cuda(self.d.cuda)
		
		
		"""Optimizer Selection"""
		if   self.d.optimizer.name in ["sgd", "nag"]:
			self.S.optimizer = TO.SGD(self.S.model.parameters(),
			                          self.d.optimizer.lr,
			                          self.d.optimizer.mom,
			                          nesterov = (self.d.optimizer.name == "nag"))
		elif self.d.optimizer.name == "rmsprop":
			self.S.optimizer = TO.RMSprop(self.S.model.parameters(),
			                              self.d.optimizer.lr,
			                              self.d.optimizer.rho,
			                              self.d.optimizer.eps)
		elif self.d.optimizer.name == "adam":
			self.S.optimizer = TO.Adam(self.S.model.parameters(),
			                           self.d.optimizer.lr,
			                           (self.d.optimizer.beta1,
			                            self.d.optimizer.beta2),
			                           self.d.optimizer.eps)
		else:
			raise NotImplementedError("Optimizer "+self.d.optimizer.name+" not implemented!")
		
		
		"""Return self-reference for fluent interface"""
		return self
	
	def fromSnapshot(self, path):
		return self.load(path).reseed()
	
	def run(self):
		#
		# With the RNGs properly seeded, create the dataset samplers and
		# iterators.
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
		# Run training loop under event logger.
		#
		
		with EventLogger(self.logDir, self.S.step, flushSecs=5) as self.eventLogger:
			while self.S.epoch < self.d.num_epochs:
				self.runEpoch().snapshot().purge()
		
		#
		# Eventually, return.
		#
		return self
	
	def runEpoch(self):
		"""Run one epoch of training."""
		
		#
		# If a module has a reconstrain() method, invoke it.
		#
		def reconstrain(module):
			if hasattr(module, "reconstrain"):
				module.reconstrain()
		
		
		#
		# Training.
		#
		self.S.model.train()
		for I, (X,Y) in enumerate(self.DtrainLoad):
			"""Data Load"""
			if self.d.cuda is None:
				X, Y = X.cpu(), Y.cpu()
			else:
				X, Y = X.cuda(self.d.cuda), Y.cuda(self.d.cuda)
			X, Y = TA.Variable(X), TA.Variable(Y)
			
			
			"""Data Step"""
			self.S.optimizer.zero_grad()
			Ypred = self.S.model(X)
			loss  = self.S.model.loss(Ypred, Y)
			loss.backward()
			self.trainStats(X, Ypred, Y, loss)
			self.S.optimizer.step()
			self.S.model.apply(reconstrain)
			self.eventLogger.step()
		
		
		#
		# Validation.
		#
		self.S.model.eval()
		self.S.valLoss = 0.0
		self.S.valAcc  = 0.0
		self.S.valNum  = 0.0
		for I, (X,Y) in enumerate(self.DvalidLoad):
			"""Data Load"""
			if self.d.cuda is None:
				X, Y = X.cpu(), Y.cpu()
			else:
				X, Y = X.cuda(self.d.cuda), Y.cuda(self.d.cuda)
			X, Y = TA.Variable(X, volatile=True), TA.Variable(Y, volatile=True)
			
			
			"""Data Step"""
			Ypred = self.S.model(X)
			loss  = self.S.model.loss(Ypred, Y)
			self.validStats(X, Ypred, Y, loss)
		with tagscope("valid"):
			with tagscope("losses"):
				logScalar("loss", self.S.valLoss/self.S.valNum)
				logScalar("acc",  self.S.valAcc /self.S.valNum)
		
		#
		# Epoch step and return.
		#
		
		# LR decay hack.
		for pgroup in self.S.optimizer.state_dict()["param_groups"]:
			pgroup["lr"] *= (3e-7/self.d.optimizer.lr)**(1./self.d.num_epochs)
		
		sys.stdout.write("Epoch {:d} done.\n".format(self.S.epoch))
		self.S.epoch += 1
		
		return self
	
	def trainStats(self, X, Ypred, Y, loss):
		with tagscope("train"):
			with tagscope("losses"):
				with tagscope("batch"):
					correct = T.max(Ypred, 1)[1].eq(Y).long().sum()
					batchSz = Y.size(0)
					
					logScalar("size", float(batchSz))
					logScalar("loss", float(loss))
					logScalar("acc",  float(correct)/batchSz)
	
	def validStats(self, X, Ypred, Y, loss):
		correct = T.max(Ypred, 1)[1].eq(Y).long().sum()
		batchSz = Y.size(0)
		
		self.S.valNum  += float(batchSz)
		self.S.valAcc  += float(correct)
		self.S.valLoss += float(loss*batchSz) # Because the loss is a mean

