import utils::*;

class tb_config extends BaseObj;

    string firmware;
    string testname;

    function new(Logger logger);
        super.new(logger);
    endfunction

    function parse_args();

        if ($value$plusargs("testname=%s", this.testname)) begin
            logger.print($sformatf("Using %s as testname", firmware));
        end else begin
            logger.print($sformatf("Expecting a command line argument %s", testname));
        end

    endfunction

endclass
