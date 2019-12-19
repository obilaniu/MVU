`timescale 1 ps / 1 ps

import utils::*;

`define NUM_TEST_VECS 100000

/**** Test Module test_mvp ****/
module mvp_tester();


/* Local parameters for test */
localparam n    = 64;
localparam a    = $clog2(n);


/* Create input registers and output wires */
reg                  clk = 0;
reg [     n*n-1 : 0] W;
reg [       n-1 : 0] D;
reg [         1 : 0] mode;
wire[ n*(a+2)-1 : 0] S;


integer i;

function int get_sum_val(logic[n-1 : 0] val, int n);
    automatic int sum = 0;
    // print($sformatf("sum=%d", sum));
    for (int i=0; i<n; i++) begin
        sum += val[i];
    end
    return sum;
endfunction

function void gen_weight_vector();
    if (n>16) begin
        for (int i=0; i<(n/16)*n; i++) begin
            W[i*16 +: 16] = $urandom_range(0,2**16-1);
        end
    end else begin
        for (int i=0; i<n; i++) begin
            W[i*n +: n] = $urandom_range(0,2**n-1);
        end
    end
endfunction


/* Create instance */
mvp #(n) master (clk, mode, W, D, S);

/* Run test */
initial begin
    string input_str, res_str;
    automatic int sum_val=0, test_cnt = 0;
    automatic test_stats test_stat;
    assert (2**$clog2(n) == n) else begin print("n must be power of 2", "ERROR"); $finish;end
    print_banner("Testing MVP module");
    assign D = {n{1'b1}};
    assign mode = 2'b01;
    // assign W = {4'h1, 4'h2, 4'h3, 4'h4} ;
    for (int test_num=0; test_num<`NUM_TEST_VECS; test_num++) begin
        gen_weight_vector();
        //assign D = 6'b11111;
        #10;
        $display("\n");
        for(i=0;i<n;i=i+1) begin
            sum_val = get_sum_val(W[i*n +: n], n);
            if (sum_val == S[i*(a+2) +: a+2]) begin
                res_str = "PASS";
                test_stat.pass_cnt+=1;
            end else begin
                res_str = "FAIL";
                test_stat.fail_cnt += 1;
            end
            // input_str = $sformatf("W=%bk    actual=%d    expected=%d", W[i*n +: n], S[i*(a+2) +: a+2], sum_val);
            // input_str = $sformatf("[%4d] mode=%d    W=%b    D=%h    S=%h    S[%4d +: %4d]=%4d    %s", test_cnt, mode, W[i*n +: n], D, S, i*(a+2), a+2, S[i*(a+2) +: a+2], res_str);
            input_str = $sformatf("[%4d] mode=%d    W=%b    D=%h    S[%4d +: %4d]=%4d    %s", test_cnt, mode, W[i*n +: n], D, i*(a+2), a+2, S[i*(a+2) +: a+2], res_str);
            print(input_str);
            test_cnt += 1;
        end
    end
    print_result(test_stat, VERB_LOW);
end

endmodule
