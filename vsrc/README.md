# Running Tests

Make sure you have Xilinx tools in your path. You can source the following script (check the path):

    source /opt/Xilinx/Vivado/settings64.sh
   
Assuming you want to test `MVP`, by entering `MVP/scripts` directory, you can run the `MVP` test using the following script:

    python do_test.py -f files.f -t mvp_tester -s xilinx
    
The command above, uses the `files.f` as the dependency file, `mvp_tester` as the top level module and `xilinx` as the simulation tool.