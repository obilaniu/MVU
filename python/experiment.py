# -*- coding: utf-8 -*-
import nauka
import os, sys
import torch
import torchvision
from   torch.nn                         import (DataParallel,)
from   torch.nn.parallel                import (data_parallel,)
from   torch.optim                      import (SGD, RMSprop, Adam,)
from   torch.utils.data                 import (DataLoader,)
from   torch.utils.data.sampler         import (SubsetRandomSampler,)
from   torchvision.datasets             import (MNIST, CIFAR10, CIFAR100, SVHN,)
from   torchvision.transforms           import (Compose, ToTensor,)
from   zvit                             import *

#
# Local Imports:
#
from   models                           import *
from   layers                           import *
from   functional                       import *




class Experiment(nauka.exp.Experiment):
	def __init__(self, a):
		self.a = type(a)(**a.__dict__)
		self.a.__dict__.pop("__argp__", None)
		self.a.__dict__.pop("__argv__", None)
		self.a.__dict__.pop("__cls__",  None)
		if self.a.workDir:
			super().__init__(self.a.workDir)
		else:
			super().__init__(os.path.join(*([self.a.baseDir]+self.a.name)))
		self.mkdirp(self.logDir)
	
	def fromScratch(self):
		"""
		Reinitialize from scratch.
		"""
		pass
		
		"""Reseed PRNGs for initialization step"""
		self.reseed(password="Seed: {} Init".format(self.a.seed))
		
		
		"""Create snapshottable-state object"""
		self.S             = nauka.utils.PlainObject()
		
		
		"""Model Instantiation"""
		self.S.model = None
		if   self.a.model == "real":         self.S.model = RealModel       (self.a)
		elif self.a.model == "ttq":          self.S.model = TTQModel        (self.a)
		elif self.a.model == "ttqresnet":    self.S.model = TTQResnetModel  (self.a)
		elif self.a.model == "ttqresnet32":  self.S.model = TTQResnet32Model(self.a)
		elif self.a.model == "bnn":          self.S.model = MatthieuBNN     (self.a)
		elif self.a.model == "ff":           self.S.model = FFBNN           (self.a)
		if   self.S.model is None:
			raise ValueError("Unsupported dataset-model pair \""+self.a.dataset+"-"+self.a.model+"\"!")
		
		if self.a.cuda: self.S.model = self.S.model.cuda(self.a.cuda[0])
		else:           self.S.model = self.S.model.cpu()
			
		
		
		"""Optimizer Selection"""
		self.S.optimizer = nauka.utils.torch.optim.fromSpec(self.S.model.parameters(),
		                                                    self.a.optimizer)
		
		
		"""Epoch/Interval counters"""
		self.S.epochNum    = 0
		self.S.intervalNum = 0
		
		
		return self
	
	def run(self):
		"""
		Run by intervals until experiment completion.
		"""
		with ZvitWriter(self.logDir, 0) as self.z:
			self.readyDataset(download=False)
			while not self.isDone:
				self.interval().snapshot().purge()
		return self
	
	def interval(self):
		"""
		An interval is defined as the computation- and time-span between two
		snapshots.
		
		Hard requirements:
		- By definition, one may not invoke snapshot() within an interval.
		- Corollary: The work done by an interval is either fully recorded or
		  not recorded at all.
		- There must be a step of the event logger between any TensorBoard
		  summary log and the end of the interval.
		
		For reproducibility purposes, all PRNGs are reseeded at the beginning
		of every interval.
		"""
		
		self.reseed()
		self.readyLoaders()
		self.onIntervalBegin()
		
		with tagscope("train"):
			self.S.model.train()
			self.onTrainLoopBegin()
			for i, D in enumerate(self.DloaderTrain):
				if self.a.fastdebug and i>=self.a.fastdebug: break
				if i>0: self.z.step()
				self.onTrainBatch(D, i)
			self.onTrainLoopEnd()
		
		with tagscope("valid"):
			self.S.model.eval()
			self.onValidLoopBegin()
			for i, D in enumerate(self.DloaderValid):
				if self.a.fastdebug and i>=self.a.fastdebug: break
				self.onValidBatch(D, i)
			self.onValidLoopEnd()
		
		self.onIntervalEnd()
		self.S.epochNum    += 1
		self.S.intervalNum += 1
		self.z.step()
		return self
	
	def onTrainBatch(self, D, i):
		X, Y = D
		
		self.S.optimizer.zero_grad()
		if self.a.cuda:
			Y, X  = Y.cuda(), X.cuda()
			Ypred = data_parallel(self.S.model, X, self.a.cuda)
		else:
			Y, X  = Y.cpu(),  X.cpu()
			Ypred = self.S.model(X)
		loss = self.S.model.loss(Ypred, Y)
		loss.backward()
		self.S.optimizer.step()
		self.S.model.constrain()
		
		with torch.no_grad():
			self.recordTrainBatchStats(X, Ypred, Y, loss)
		
		return self
	
	def onValidBatch(self, D, i):
		X, Y = D
		
		with torch.no_grad():
			if self.a.cuda:
				Y, X  = Y.cuda(), X.cuda()
				Ypred = data_parallel(self.S.model, X, self.a.cuda)
			else:
				Y, X  = Y.cpu(),  X.cpu()
				Ypred = self.S.model(X)
			loss = self.S.model.loss(Ypred, Y)
		
		with torch.no_grad():
			self.recordValidBatchStats(X, Ypred, Y, loss)
		
		return self
	
	def recordTrainBatchStats(self, X, Ypred, Y, loss):
		batchSize = Y.size(0)
		self.S.totalTrainLoss += float(loss*batchSize)
		self.S.totalTrainErr  += int(torch.max(Ypred, 1)[1].eq(Y).long().sum())
		self.S.totalTrainCnt  += batchSize
		logScalar("batchLoss", loss)
		if self.a.model == "ff" and self.a.act == "pact":
			logScalar("act/alpha1", float(self.S.model.act1.alpha))
			logScalar("act/alpha2", float(self.S.model.act2.alpha))
			logScalar("act/alpha3", float(self.S.model.act3.alpha))
			logScalar("act/alpha4", float(self.S.model.act4.alpha))
			logScalar("act/alpha5", float(self.S.model.act5.alpha))
			logScalar("act/alpha6", float(self.S.model.act6.alpha))
			logScalar("act/alpha7", float(self.S.model.act7.alpha))
			logScalar("act/alpha8", float(self.S.model.act8.alpha))
	
	def recordValidBatchStats(self, X, Ypred, Y, loss):
		batchSize = Y.size(0)
		self.S.totalValidLoss += float(loss*batchSize)
		self.S.totalValidErr  += int(torch.max(Ypred, 1)[1].eq(Y).long().sum())
		self.S.totalValidCnt  += batchSize
	
	def onTrainLoopBegin(self):
		self.S.totalTrainLoss = 0
		self.S.totalTrainErr  = 0
		self.S.totalTrainCnt  = 0
		return self
	
	def onTrainLoopEnd(self):
		logScalar("loss", self.S.totalTrainLoss/self.S.totalTrainCnt)
		logScalar("err",  self.S.totalTrainErr /self.S.totalTrainCnt)
		return self
	
	def onValidLoopBegin(self):
		self.S.totalValidLoss = 0
		self.S.totalValidErr  = 0
		self.S.totalValidCnt  = 0
		return self
	
	def onValidLoopEnd(self):
		logScalar("loss", self.S.totalValidLoss/self.S.totalValidCnt)
		logScalar("err",  self.S.totalValidErr /self.S.totalValidCnt)
		return self
	
	def onIntervalBegin(self):
		return self
	
	def onIntervalEnd(self):
		for i, pgroup in enumerate(self.S.optimizer.state_dict()["param_groups"]):
			if i == 0: logScalar("lr", pgroup["lr"])
			pgroup["lr"] *= (3e-7/self.a.optimizer.lr)**(1./self.a.num_epochs)
		
		sys.stdout.write("Epoch {:d} done.\n".format(self.S.epoch))
		
		return self
	
	def reseed(self, password=None):
		"""
		Reseed PRNGs for reproducibility at beginning of interval.
		"""
		#
		# The "password" from which the seeds are derived should be unique per
		# interval to ensure different seedings. Given the same
		#   - password
		#   - salt
		#   - rounds #
		#   - hash function
		# , the reproduced seed will always be the same.
		#
		# We choose as salt the PRNG's name. Since it's different for every
		# PRNG, their sequences will be different, even if they share the same
		# "password".
		#
		password = password or "Seed: {} Interval: {:d}".format(self.a.seed,
		                                                        self.S.intervalNum,)
		nauka.utils.random.setstate           (password)
		nauka.utils.numpy.random.set_state    (password)
		nauka.utils.torch.random.manual_seed  (password)
		nauka.utils.torch.cuda.manual_seed_all(password)
		return self
	
	def readyDataset(self, download=False):
		"""
		Ready the datasets, downloading or copying if necessary, permitted and
		able.
		"""
		if   self.a.dataset == "mnist":
			self.Dxform    = [ToTensor()]
			self.Dxform    = Compose(self.Dxform)
			self.DsetTrain = MNIST   (self.dataDir, True,    self.Dxform, download=download)
			self.DsetTest  = MNIST   (self.dataDir, False,   self.Dxform, download=download)
			self.Dimgsz    = (1, 28, 28)
			self.DNclass   = 10
			self.DNvalid   = 5000
		elif self.a.dataset == "cifar10":
			self.Dxform    = [ToTensor()]
			self.Dxform    = Compose(self.Dxform)
			self.DsetTrain = CIFAR10 (self.dataDir, True,    self.Dxform, download=download)
			self.DsetTest  = CIFAR10 (self.dataDir, False,   self.Dxform, download=download)
			self.Dimgsz    = (3, 32, 32)
			self.DNclass   = 10
			self.DNvalid   = 5000
		elif self.a.dataset == "cifar100":
			self.Dxform    = [ToTensor()]
			self.Dxform    = Compose(self.Dxform)
			self.DsetTrain = CIFAR100(self.dataDir, True,    self.Dxform, download=download)
			self.DsetTest  = CIFAR100(self.dataDir, False,   self.Dxform, download=download)
			self.Dimgsz    = (3, 32, 32)
			self.DNclass   = 100
			self.DNvalid   = 5000
		elif self.a.dataset == "svhn":
			self.Dxform    = [ToTensor()]
			self.Dxform    = Compose(self.Dxform)
			self.DsetTrain = SVHN    (self.dataDir, "train", self.Dxform, download=download)
			self.DsetTest  = SVHN    (self.dataDir, "test",  self.Dxform, download=download)
			self.Dimgsz    = (3, 32, 32)
			self.DNclass   = 10
			self.DNvalid   = 5000
		else:
			raise ValueError("Unknown dataset \""+self.a.dataset+"\"!")
		self.DNtrainvalid  = len(self.DsetTrain)
		self.DNtest        = len(self.DsetTest)
		self.DNtrain       = self.DNtrainvalid-self.DNvalid
		self.DindicesTrain = range(self.DNtrainvalid)[:self.DNtrain]
		self.DindicesValid = range(self.DNtrainvalid)[-self.DNvalid:]
		self.DindicesTest  = range(self.DNtest)
		return self
	
	def readyLoaders(self):
		"""
		Ready the data loaders reproducibly, knowing and relying on the fact
		that PRNG states have been reproduced.
		"""
		self.DsamplerTrain = SubsetRandomSampler(self.DindicesTrain)
		self.DsamplerValid = SubsetRandomSampler(self.DindicesValid)
		self.DsamplerTest  = SubsetRandomSampler(self.DindicesTest)
		self.DloaderTrain  = DataLoader(dataset     = self.DsetTrain,
		                                batch_size  = self.a.batch_size,
		                                shuffle     = False,
		                                sampler     = self.DsamplerTrain,
		                                num_workers = 0,
		                                pin_memory  = False)
		self.DloaderValid  = DataLoader(dataset     = self.DsetTrain,
		                                batch_size  = self.a.batch_size,
		                                shuffle     = False,
		                                sampler     = self.DsamplerValid,
		                                num_workers = 0,
		                                pin_memory  = False)
		self.DloaderTest   = DataLoader(dataset     = self.DsetTest,
		                                batch_size  = self.a.batch_size,
		                                shuffle     = False,
		                                sampler     = self.DsamplerTest,
		                                num_workers = 0,
		                                pin_memory  = False)
		return self
	
	def load(self, path):
		self.S = torch.load(os.path.join(path, "snapshot.pkl"))
		return self
	
	def dump(self, path):
		torch.save(self.S,  os.path.join(path, "snapshot.pkl"))
		return self
	
	@staticmethod
	def download(a):
		"""
		Download the dataset or datasets required.
		"""
		if a.dataset in {"all", "mnist"}:
			MNIST   (a.dataDir, True,    download=True)
			MNIST   (a.dataDir, False,   download=True)
		if a.dataset in {"all", "cifar10"}:
			CIFAR10 (a.dataDir, True,    download=True)
			CIFAR10 (a.dataDir, False,   download=True)
		if a.dataset in {"all", "cifar100"}:
			CIFAR100(a.dataDir, True,    download=True)
			CIFAR100(a.dataDir, False,   download=True)
		if a.dataset in {"all", "svhn"}:
			SVHN    (a.dataDir, "train", download=True)
			SVHN    (a.dataDir, "extra", download=True)
			SVHN    (a.dataDir, "test",  download=True)
		return 0
	
	@property
	def name(self):
		#
		# A more informative name would be helpful here.
		#
		return "" if self.a.name is None else "-".join(self.a.name)
	@property
	def dataDir(self):
		return self.a.dataDir
	@property
	def logDir(self):
		return os.path.join(self.workDir, "logs")
	@property
	def isDone(self):
		return (self.S.epochNum >= self.a.num_epochs or
		       (self.a.fastdebug and self.S.epochNum >= self.a.fastdebug))
	@property
	def exitcode(self):
		return 0 if self.isDone else 1
