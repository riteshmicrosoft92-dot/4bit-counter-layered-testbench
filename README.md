# 4-bit Synchronous Up-Counter: Layered Testbench

SystemVerilog RTL and a class-based layered testbench for a 4-bit synchronous up-counter with enable and active-high synchronous reset.

## Behavior

- At each rising clock edge, rst=1 clears the count to 0.
- Otherwise, enable=1 increments the count.
- Otherwise, the count holds its previous value.
- Four-bit arithmetic rolls over from 15 to 0.

## Project layout

- rtl/counter.sv: design under test (DUT)
- tb/counter_if.sv: signals connecting the testbench and DUT
- tb/counter_tb.sv: transaction, generator, driver, monitor, scoreboard, environment, test, and top module

## Testbench layers

1. Transaction stores reset and enable inputs and the sampled output.
2. Generator creates directed reset, count and rollover, hold, and reset-during-counting stimulus, followed by randomized inputs.
3. Driver applies each transaction on the falling clock edge.
4. Monitor samples the output after each rising edge.
5. Scoreboard calculates the expected count and reports a mismatch immediately.
6. Environment connects the components with mailboxes; the test starts the environment.

## Run with Questa/ModelSim

From the repository root:

    vlog -sv rtl/counter.sv tb/counter_if.sv tb/counter_tb.sv
    vsim -c tb_top -do "run -all; quit"

A successful run ends with ALL TESTS PASSED (55 cycles). A mismatch prints a FAIL message and stops the simulation.
