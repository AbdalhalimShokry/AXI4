module AXI_top;

  import AXI_env_pkg::*;

  logic ACLK;
  initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK;
  end

  AXI_interface intrf (.ACLK(ACLK));

  // Reset Driver
  initial begin
    intrf.ARESETn = 1'b0;
    repeat (5) @(posedge ACLK);
    intrf.ARESETn = 1'b1;
  end

  axi4 AXI_DUT (
      .ACLK   (intrf.ACLK),
      .ARESETn(intrf.ARESETn),
      .AWADDR (intrf.AWADDR),
      .AWLEN  (intrf.AWLEN),
      .AWSIZE (intrf.AWSIZE),
      .AWVALID(intrf.AWVALID),
      .AWREADY(intrf.AWREADY),
      .WDATA  (intrf.WDATA),
      .WVALID (intrf.WVALID),
      .WLAST  (intrf.WLAST),
      .WREADY (intrf.WREADY),
      .BRESP  (intrf.BRESP),
      .BVALID (intrf.BVALID),
      .BREADY (intrf.BREADY),
      .ARADDR (intrf.ARADDR),
      .ARLEN  (intrf.ARLEN),
      .ARSIZE (intrf.ARSIZE),
      .ARVALID(intrf.ARVALID),
      .ARREADY(intrf.ARREADY),
      .RDATA  (intrf.RDATA),
      .RRESP  (intrf.RRESP),
      .RVALID (intrf.RVALID),
      .RLAST  (intrf.RLAST),
      .RREADY (intrf.RREADY)
  );

  AXI_assertions assertion (intrf);

  AXI_environment env;

  initial begin
    env = new();
    env.vif = intrf.TB_side;
    env.run_env();
  end

endmodule