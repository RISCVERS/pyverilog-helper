import "DPI-C" function void init_ram();

module tb_top();

reg clock;
reg reset;
wire uart_valid;
wire [7:0] uart_ch;

initial begin
  init_ram();
  clock = 0;
  reset = 1;
  //$vcdplusfile("fix.vpd");
  //$vcdpluson;
  #100 reset = 0;
  // #10000 $finish;
  //#220000 $vcdplusfile("fix.vpd");
  // $vcdpluson;
end

always #1 clock = ~clock;

sim_top sim (
  .clock(clock),
  .reset(reset),
  .uart_valid(uart_valid),
  .uart_ch(uart_ch)
);

always @(posedge clock) begin
  if (uart_valid) begin
    $write("%c", uart_ch);
  end
end

reg [63:0] stuck_timer;
reg [63:0] commit_count;
reg [63:0] cycle_count;

`define ROQ sim.CPU.core.ctrlBlock.roq
`define CSR sim.CPU.core.integerBlock.jmpExeUnit.csr

wire has_commit = !`ROQ.io_commits_isWalk && `ROQ.io_commits_valid_0;

always @(posedge clock) begin
  if (reset || has_commit)
    stuck_timer <= 0;
  else
    stuck_timer <= stuck_timer + 1;

  if (reset)
    commit_count <= 0;
  else if (!`ROQ.io_commits_isWalk)
    commit_count <= commit_count + `ROQ.io_commits_valid_0 + `ROQ.io_commits_valid_1 + `ROQ.io_commits_valid_2 + `ROQ.io_commits_valid_3 + `ROQ.io_commits_valid_4 + `ROQ.io_commits_valid_5;

  if (reset)
    cycle_count <= 0;
  else
    cycle_count <= cycle_count + 1;

  if (!reset && stuck_timer > 5000) begin
    $display("no instruction commits for 5000 cycles");
    $finish;
  end
  if (!reset && !`ROQ.io_commits_isWalk && `ROQ.io_commits_valid_0) begin
    // $display("instr commit %b", {`ROQ.io_commits_valid_0,`ROQ.io_commits_valid_1,`ROQ.io_commits_valid_2,`ROQ.io_commits_valid_3,`ROQ.io_commits_valid_4,`ROQ.io_commits_valid_5});
  end
  if (!reset && cycle_count % 10000 == 0) begin
    $display("[time=%d] instrCnt = %d", cycle_count, commit_count);
    //$display("[time=%d] mcycle=%d, minstret=%d, bpRight=%d, bpWrong=%d", cycle_count, `CSR.mcycle, `CSR.minstret, `CSR.bpRight, `CSR.bpWrong);
  end
end

endmodule

