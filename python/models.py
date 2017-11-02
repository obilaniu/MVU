#!/usr/bin/env python
# -*- coding: utf-8 -*-



# Imports.
import cPickle                              as pkl
import ipdb
import numpy                                as np
import os
import sys
import torch                                as T
import torch.autograd                       as TA
import torch.cuda                           as TC
import torch.nn                             as TN
import torch.optim                          as TO
import torch.utils                          as TU
import torch.utils.data                     as TUD

from   functional                           import Residual3
from   layers                               import Conv2dTTQ, BatchNorm2dTz



#
# Real-valued model
#

class RealModel(TN.Module):
	def __init__(self, d):
		super(RealModel, self).__init__()
		self.d      = d
		self.conv0  = TN.Conv2d          (  1 if self.d.dataset == "mnist" else 3,
		                                        64, (3,3), padding=1)
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
		self.conv9  = TN.Conv2d          (256,  100 if self.d.dataset == "cifar100" else 10,
		                                            (1,1), padding=0)
		self.pool   = TN.MaxPool2d       ((7,7) if self.d.dataset == "mnist" else (8,8))
		self.celoss = TN.CrossEntropyLoss()
	def forward(self, X, Y):
		v, y     = X.view(-1, 1, 28, 28), Y
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
		v        = v.view(-1, 10)
		
		ceLoss   = self.celoss(v, y)
		yPred    = T.max(v, 1)[1]
		batchErr = yPred.eq(y).long().sum(0)
		
		return {
			"user/ceLoss":   ceLoss,
			"user/batchErr": batchErr,
			"user/yPred":    yPred,
		}





#
# TTQ model
#

class TTQModel(TN.Module):
	def __init__(self, d):
		super(TTQModel, self).__init__()
		self.d      = d
		self.conv0  = Conv2dTTQ        (  1 if self.d.dataset == "mnist" else 3,
		                                      64, (3,3), padding=1)
		self.bntz0  = BatchNorm2dTz    ( 64, lo=0, hi=0)
		self.conv1  = Conv2dTTQ        ( 64,  64, (3,3), padding=1)
		self.bntz1  = BatchNorm2dTz    ( 64, lo=0, hi=0)
		self.conv2  = Conv2dTTQ        ( 64, 128, (3,3), padding=1, stride=2)
		self.bntz2  = BatchNorm2dTz    (128, lo=0, hi=0)
		self.conv3  = Conv2dTTQ        (128, 128, (3,3), padding=1)
		self.bntz3  = BatchNorm2dTz    (128, lo=0, hi=0)
		self.conv4  = Conv2dTTQ        (128, 128, (3,3), padding=1)
		self.bntz4  = BatchNorm2dTz    (128, lo=0, hi=0)
		self.conv5  = Conv2dTTQ        (128, 256, (3,3), padding=1, stride=2)
		self.bntz5  = BatchNorm2dTz    (256, lo=0, hi=0)
		self.conv6  = Conv2dTTQ        (256, 256, (3,3), padding=1)
		self.bntz6  = BatchNorm2dTz    (256, lo=0, hi=0)
		self.conv7  = Conv2dTTQ        (256, 256, (3,3), padding=1)
		self.bntz7  = BatchNorm2dTz    (256, lo=0, hi=0)
		self.conv8  = Conv2dTTQ        (256, 256, (3,3), padding=1)
		self.bntz8  = BatchNorm2dTz    (256, lo=0, hi=0)
		self.conv9  = Conv2dTTQ        (256, 100 if self.d.dataset == "cifar100" else 10,
		                                          (1,1), padding=0)
		self.pool   = TN.MaxPool2d     ((7,7) if self.d.dataset == "mnist" else (8,8))
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
		
		shape = (-1, 1, 28, 28) if self.d.dataset == "mnist" else (-1, 3, 32, 32)
		v, y     = X.view(*shape), Y
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
		v        = v.view(-1, 100 if self.d.dataset == "cifar100" else 10)
		
		ceLoss   = self.celoss(v, y)
		yPred    = T.max(v, 1)[1]
		batchErr = yPred.eq(y).long().sum(0)
		
		return {
			"user/ceLoss":   ceLoss,
			"user/batchErr": batchErr,
			"user/yPred":    yPred,
		}







#
# TTQ Resnet model
#

class TTQResnetModel(TN.Module):
	def __init__(self, d):
		super(TTQResnetModel, self).__init__()
		self.d      = d
		self.conv0  = Conv2dTTQ        (  1 if self.d.dataset == "mnist" else 3,
		                                      64, (3,3), padding=1)
		self.bntz0  = BatchNorm2dTz    ( 64, lo=0, hi=0)
		self.conv1  = Conv2dTTQ        ( 64,  64, (3,3), padding=1)
		self.bntz1  = BatchNorm2dTz    ( 64, lo=0, hi=0)
		self.conv2  = Conv2dTTQ        ( 64, 128, (3,3), padding=1, stride=2)
		self.bntz2  = BatchNorm2dTz    (128, lo=0, hi=0)
		self.conv3  = Conv2dTTQ        (128, 128, (3,3), padding=1)
		self.bntz3  = BatchNorm2dTz    (128, lo=0, hi=0)
		self.conv4  = Conv2dTTQ        (128, 128, (3,3), padding=1)
		self.bntz4  = BatchNorm2dTz    (128, lo=0, hi=0)
		self.conv5  = Conv2dTTQ        (128, 256, (3,3), padding=1, stride=2)
		self.bntz5  = BatchNorm2dTz    (256, lo=0, hi=0)
		self.conv6  = Conv2dTTQ        (256, 256, (3,3), padding=1)
		self.bntz6  = BatchNorm2dTz    (256, lo=0, hi=0)
		self.conv7  = Conv2dTTQ        (256, 256, (3,3), padding=1)
		self.bntz7  = BatchNorm2dTz    (256, lo=0, hi=0)
		self.conv8  = Conv2dTTQ        (256, 256, (3,3), padding=1)
		self.bntz8  = BatchNorm2dTz    (256, lo=0, hi=0)
		self.conv9  = Conv2dTTQ        (256, 100 if self.d.dataset == "cifar100" else 10,
		                                          (1,1), padding=0)
		self.pool   = TN.MaxPool2d     ((7,7) if self.d.dataset == "mnist" else (8,8))
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
		
		shape = (-1, 1, 28, 28) if self.d.dataset == "mnist" else (-1, 3, 32, 32)
		v, y     = X.view(*shape), Y
		v        = self.bntz0(self.conv0(v))
		v        = self.bntz1(self.conv1(v))
		v        = self.bntz2(self.conv2(v))
		vR       = self.bntz3(self.conv3(v))
		vR       = self.bntz4(self.conv4(vR))
		v        = Residual3.apply(v, vR) # v + v Residual
		v        = self.bntz5(self.conv5(v))
		vR       = self.bntz6(self.conv6(v))
		vR       = self.bntz7(self.conv7(vR))
		v        = Residual3.apply(v, vR) # v + v Residual
		v        = self.bntz8(self.conv8(v))
		v        = self.pool (self.conv9(v))
		v        = v.view(-1, 100 if self.d.dataset == "cifar100" else 10)
		
		ceLoss   = self.celoss(v, y)
		yPred    = T.max(v, 1)[1]
		batchErr = yPred.eq(y).long().sum(0)
		
		return {
			"user/ceLoss":   ceLoss,
			"user/batchErr": batchErr,
			"user/yPred":    yPred,
		}
