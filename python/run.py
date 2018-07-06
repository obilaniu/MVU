#!/usr/bin/env python
# -*- coding: utf-8 -*-
# PYTHON_ARGCOMPLETE_OK
import pickle as pkl, pdb, nauka, os, sys


DATASETS = ["mnist", "cifar10", "cifar100", "svhn"]


class root(nauka.ap.Subcommand):
	class train(nauka.ap.Subcommand):
		@classmethod
		def addArgs(kls, argp):
			mtxp = argp.add_mutually_exclusive_group()
			mtxp.add_argument("-w", "--workDir",        default=None,         type=str,
			    help="Full, precise path to an experiment's working directory.")
			mtxp.add_argument("-b", "--baseDir",        action=nauka.ap.BaseDir)
			argp.add_argument("-d", "--dataDir",        action=nauka.ap.DataDir)
			argp.add_argument("-t", "--tmpDir",         action=nauka.ap.TmpDir)
			argp.add_argument("-n", "--name",           action="append", default=[],
			    help="Build a name for the experiment.")
			argp.add_argument("-s", "--seed",           default=0x6a09e667f3bcc908, type=int,
			    help="Seed for PRNGs. Default is 64-bit fractional expansion of sqrt(2).")
			argp.add_argument("--model",                default="ttq",              type=str,
			    choices=["real", "ttq", "ttqresnet", "ttqresnet32", "bnn"],
			    help="Model Selection.")
			argp.add_argument("--dataset",              default="cifar10",    type=str,
			    choices=DATASETS,
			    help="Dataset Selection.")
			argp.add_argument("--dropout",              default=0,            type=float,
			    help="Dropout probability.")
			argp.add_argument("-e", "--num-epochs",     default=200,          type=int,
			    help="Number of epochs")
			argp.add_argument("--batch-size", "--bs",   default=50,           type=int,
			    help="Batch Size")
			argp.add_argument("--override",             default="matt",       type=str,
			    choices=["matt", "pass"],
			    help="Gradient override selection.")
			argp.add_argument("--act",                  default="sign",       type=str,
			    choices=["sign", "pact"],
			    help="Activation function selection.")
			argp.add_argument("--cuda",                 action=nauka.ap.CudaDevice)
			argp.add_argument("-p", "--preset",         action=nauka.ap.Preset,
			    choices={"fig1":  ["-n=fig1", "--opt=adam", "--bs=100"],
			             "fig2":  ["-n=fig2", "--opt=sgd",  "--bs=25"],},
			    help="Experiment presets for commonly-used settings.")
			optp = argp.add_argument_group("Optimizers", "Tunables for all optimizers.")
			optp.add_argument("--optimizer", "--opt",   action=nauka.ap.Optimizer,
			    default="adam",
			    help="Optimizer selection.")
			optp.add_argument("--clipnorm", "--cn",     default=1.0,          type=float,
			    help="The norm of the gradient will be clipped at this magnitude.")
			optp.add_argument("--clipval",  "--cv",     default=1.0,          type=float,
			    help="The values of the gradients will be individually clipped at this magnitude.")
			optp.add_argument("--l1",                   default=0,            type=float,
			    help="L1 penalty.")
			optp.add_argument("--l2",                   default=0,            type=float,
			    help="L2 penalty.")
			optp.add_argument("--decay",                default=0,            type=float,
			    help="Learning rate decay for optimizers.")
			dbgp = argp.add_argument_group("Debugging", "Flags for debugging purposes.")
			dbgp.add_argument("--summary",              action="store_true",
			    help="Print a summary of the network.")
			dbgp.add_argument("--fastdebug",            action=nauka.ap.FastDebug)
			dbgp.add_argument("--pdb",                  action="store_true",
			    help="""Breakpoint before run start.""")
		
		
		@classmethod
		def run(kls, a):
			from   experiment import Experiment;
			if a.pdb: pdb.set_trace()
			return Experiment(a).rollback().run().exitcode
	
	class download(nauka.ap.Subcommand):
		@classmethod
		def addArgs(kls, argp):
			argp.add_argument("-d", "--dataDir",        action=nauka.ap.DataDir)
			argp.add_argument("--dataset",              default="all",        type=str,
			    choices=DATASETS+["all"],
			    help="Dataset Selection.")
		
		@classmethod
		def run(kls, a):
			from   experiment import Experiment;
			return Experiment.download(a)


def main(argv=sys.argv):
	argp = root.addAllArgs()
	try:    import argcomplete; argcomplete.autocomplete(argp)
	except: pass
	a = argp.parse_args(argv[1:])
	a.__argv__ = argv
	return a.__cls__.run(a)


if __name__ == "__main__":
	sys.exit(main(sys.argv))
