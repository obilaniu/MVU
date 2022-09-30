# MVU - Matrix-Vector Units for Quantized Neural Network Acceleration

A fully-pipelined hardware accelerator for quantized neural networks. 

Supported operations:
1. Arbitrary fixed-point precision matrix-vector multiplication
1. Scaling of matrix-vector products at high-precision fixed-point
1. MaxPool and ReLU activation
1. Quantization/truncation of output

The overall design implements an array of MVU elements (nominally 8) that can move data between each other via an crossbar interconnect.

See paper: [Bit-Slicing FPGA Accelerator for Quantized Neural Networks, ISCAS 2019](https://ieeexplore.ieee.org/document/8702332)

Developed in conjuction with the [BARVINN](https://github.com/hossein1387/BARVINN) project, which connects the MVU array to a RISC-V-based controller called [pito-riscv](https://github.com/hossein1387/pito_riscv)

## Running RTL Simulation and Synthesis:

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


# Publication

If you liked this project, please consider citing our paper:

    @INPROCEEDINGS{8702332,
        author={Bilaniuk, Olexa and Wagner, Sean and Savaria, Yvon and David, Jean-Pierre},
        booktitle={2019 IEEE International Symposium on Circuits and Systems (ISCAS)}, 
        title={Bit-Slicing FPGA Accelerator for Quantized Neural Networks}, 
        year={2019},
        volume={},
        number={},
        pages={1-5},
        doi={10.1109/ISCAS.2019.8702332}}