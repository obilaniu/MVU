# Running Tests

Make sure you have Xilinx tools in your path. You can source the following script (check the path):

    source /opt/Xilinx/Vivado/settings64.sh
   
The main script for running simulations is do_test.py, which is found as a symbolic link in the `scripts` directory for each component. For instance, if you want to test `MVP`, by entering `MVP/scripts` directory, you can run the `MVP` test using the following script:

    python do_test.py -f files.f -t mvp_tester -s xilinx
    
The command above, uses the `files.f` as the dependency file, `mvp_tester` as the top level module and `xilinx` as the simulation tool.

Some of the tests need additional inputs. For instance, the Verilog macro "XILINX=1" is needed for design files that implement Xilinx-specific elements. These are specified in files in each `scripts` directory called `vlogmacros.f`. You can specify these on the `do_test.py` command line by specifying the `-m` option. Also, some of the tests require components from simulation libraries, e.g. IP cores. These are specified in files called `libs.f` in the `scripts` directories of each component. You can specify specify these with the `-l` option. For instance, to run the `MVU` test, run the following command:

    python do_test.py -f files.f -t mvu_tester -s xilinx -m vlogmacros.f -l libs.f