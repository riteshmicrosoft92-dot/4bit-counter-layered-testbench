`timescale 1ns/1ps

class counter_transaction;
    bit rst;
    bit enable;
    bit [3:0] observed_count;
endclass

class counter_generator;
    mailbox #(counter_transaction) gen2drv;
    int unsigned total;
    function new(mailbox #(counter_transaction) gen2drv, int unsigned total);
        this.gen2drv = gen2drv; this.total = total;
    endfunction
    task run();
        counter_transaction tr;
        for (int unsigned i = 0; i < total; i++) begin
            tr = new();
            if (i < 2) begin tr.rst = 1; tr.enable = 0; end
            else if (i < 20) begin tr.rst = 0; tr.enable = 1; end
            else if (i < 25) begin tr.rst = 0; tr.enable = 0; end
            else if (i == 25) begin tr.rst = 1; tr.enable = 1; end
            else begin
                tr.rst = ($urandom_range(0, 9) == 0);
                tr.enable = $urandom_range(0, 1);
            end
            gen2drv.put(tr);
        end
    endtask
endclass

class counter_driver;
    virtual counter_if vif;
    mailbox #(counter_transaction) gen2drv;
    int unsigned total;
    function new(virtual counter_if vif, mailbox #(counter_transaction) gen2drv, int unsigned total);
        this.vif = vif; this.gen2drv = gen2drv; this.total = total;
    endfunction
    task run();
        counter_transaction tr;
        for (int unsigned i = 0; i < total; i++) begin
            gen2drv.get(tr);
            @(negedge vif.clk);
            vif.rst = tr.rst;
            vif.enable = tr.enable;
        end
    endtask
endclass

class counter_monitor;
    virtual counter_if vif;
    mailbox #(counter_transaction) mon2scb;
    int unsigned total;
    function new(virtual counter_if vif, mailbox #(counter_transaction) mon2scb, int unsigned total);
        this.vif = vif; this.mon2scb = mon2scb; this.total = total;
    endfunction
    task run();
        counter_transaction tr;
        for (int unsigned i = 0; i < total; i++) begin
            @(posedge vif.clk);
            #1;
            tr = new();
            tr.rst = vif.rst;
            tr.enable = vif.enable;
            tr.observed_count = vif.count;
            mon2scb.put(tr);
        end
    endtask
endclass

class counter_scoreboard;
    mailbox #(counter_transaction) mon2scb;
    int unsigned total;
    bit [3:0] expected_count;
    function new(mailbox #(counter_transaction) mon2scb, int unsigned total);
        this.mon2scb = mon2scb; this.total = total; expected_count = 0;
    endfunction
    task run();
        counter_transaction tr;
        for (int unsigned i = 0; i < total; i++) begin
            mon2scb.get(tr);
            if (tr.rst) expected_count = 0;
            else if (tr.enable) expected_count = expected_count + 4'd1;
            if (tr.observed_count !== expected_count) begin
                $error("FAIL cycle %0d: rst=%0b enable=%0b expected=%0d got=%0d",
                       i, tr.rst, tr.enable, expected_count, tr.observed_count);
                $fatal(1);
            end
            $display("PASS cycle %0d: rst=%0b enable=%0b count=%0d",
                     i, tr.rst, tr.enable, tr.observed_count);
        end
        $display("ALL TESTS PASSED (%0d cycles)", total);
    endtask
endclass

class counter_environment;
    mailbox #(counter_transaction) gen2drv, mon2scb;
    counter_generator generator;
    counter_driver driver;
    counter_monitor monitor;
    counter_scoreboard scoreboard;
    function new(virtual counter_if vif, int unsigned total);
        gen2drv = new(); mon2scb = new();
        generator = new(gen2drv, total);
        driver = new(vif, gen2drv, total);
        monitor = new(vif, mon2scb, total);
        scoreboard = new(mon2scb, total);
    endfunction
    task run();
        fork
            generator.run();
            driver.run();
            monitor.run();
            scoreboard.run();
        join
    endtask
endclass

class counter_test;
    counter_environment env;
    function new(virtual counter_if vif);
        env = new(vif, 55);
    endfunction
    task run();
        env.run();
    endtask
endclass

module tb_top;
    logic clk = 0;
    counter_if intf(clk);
    counter dut(.clk(clk), .rst(intf.rst), .enable(intf.enable), .count(intf.count));
    always #5 clk = ~clk;
    initial begin
        counter_test test;
        test = new(intf);
        test.run();
        $finish;
    end
endmodule
