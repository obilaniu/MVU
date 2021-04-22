# Low-Precision Ternary Arithmetic for Neural Networks

## Dependencies:

- PyTorch 0.2.0
- PyTorch Vision 0.1.9

## Downloading & Installing

The repository includes as a Git submodule a reference to a personal collection of
code snippets called CodeSnips. The python portion of it must be installed as a
Python package.

    git clone --recursive 'git@bitbucket.org:obilaniu/lowprecision.git' LowPrecision
    cd 3rdparty/CodeSnips/python
    python setup.py install --no-deps --upgrade --force --user

## Running

The primary entry point for all purposes is `experiments/run.py`. The script has a few subcommands, which are listed when passing `--help` as an argument.

Currently, the primary subcommand of interest is `train`. Its arguments are listed with `run.py train --help`. Among the more notable ones:

- `-w WORKDIR` indicates a self-contained _working directory_ within which an experiment is run. The directory is created if it does not yet exist. All snapshots, logs and other artifacts will be kept in the workspace directory.
- `-d DATADIR` indicates a directory where the dataset is either found or may be downloaded.
- `-s SEED` is an integer that serves as the PRNG seed for this experiment.
- `--model MODEL` selects from a menu of available models.
- `--dataset DATASET` selects from a menu of available datasets.
- `-n N` sets the number of epochs to run the experiment for.
- `-b N` sets the batch size.
- `--opt OPTIMIZERSPEC` selects an optimizer. You should probably use `--opt adam`.
- `--cuda <DEVICENUM>` requests accelerated execution on the specified CUDA GPU.


## Running RTL Simulation and Synthesis:

# How to Run:

First make sure the Vivado is sourced, example for Vivado 2019.1: 
    
    source /opt/Xilinx/Vivado/2019.1/settings64.sh

Then make sure you have fusesoc installed:

    python3 -m pip install fusesoc

Then add `mvu` to your fusesoc libraries:
    
    git clone https://github.com/obilaniu/MVU.git
    cd MVU
    fusesoc library add mvu .
	
Generate the required IP components. For Xilinx Vivado, do the following:

    cd tclscripts
    vivado -mode batch -nolog -nojournal -source gen_xilinx_ip.tcl

Then run simulation (No GUI):
   
    fusesoc run --target=sim mvu

For synthesis:
    
    fusesoc run --target=synth mvu

To open sim in GUI mode:

    cd build/mvu_0/sim-vivado/ 
    make run-gui

And for synthesis:

    cd build/mvu_0/synth-vivado/ 
    make build-gui


This should open the project for you. Make sure you have run simulation or synthesis atleast once, otherwise fusesoc would not create a 
project file for you.

