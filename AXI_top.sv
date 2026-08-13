module top;

  import AXI_env_pkg::*;

  // CLock
  logic ACLK;
  initial begin
    ACLK = 0;
    forever #5 ACLK = ~ACLK;
  end


  // Interface Instansiation
  AXI_interface intrf (.ACLK(ACLK));


  // DUT Instansiation
  axi4 AXI_DUT (
      .ACLK(intrf.ACLK),
      .ARESETn(intrf.ARESETn),

      .AWADDR (intrf.AWADDR),
      .AWLEN  (intrf.AWLEN),
      .AWSIZE (intrf.AWSIZE),
      .AWVALID(intrf.AWVALID),
      .AWREADY(intrf.AWREADY),

      .WDATA (intrf.WDATA),
      .WVALID(intrf.WVALID),
      .WLAST (intrf.WLAST),
      .WREADY(intrf.WREADY),

      .BRESP (intrf.BRESP),
      .BVALID(intrf.BVALID),
      .BREADY(intrf.BREADY),

      .ARADDR (intrf.ARADDR),
      .ARLEN  (intrf.ARLEN),
      .ARSIZE (intrf.ARSIZE),
      .ARVALID(intrf.ARVALID),
      .ARREADY(intrf.ARREADY),

      .RDATA (intrf.RDATA),
      .RRESP (intrf.RRESP),
      .RVALID(intrf.RVALID),
      .RLAST (intrf.RLAST),
      .RREADY(intrf.RREADY)
  );


  // Assertions Instansiation
  AXI_assertions assertion (intrf);


  // Environment
  AXI_environment env;

  initial begin
    env = new();
    env.vif = intrf.TB_side;
    env.run_env();
  end

endmodule
