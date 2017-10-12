# Low-Precision Ternary Arithmetic for Neural Networks

## Dependencies:

- PyTorch 0.2.0
- PyTorch Vision 0.1.9

## Downloading

    git clone --recursive 'git@bitbucket.org:obilaniu/lowprecision.git' LowPrecision

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
