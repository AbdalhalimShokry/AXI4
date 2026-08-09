interface AXI_interface (
    input logic ACLK
);

  // Reset
  logic ARESETn;

  // Preparing Writing
  logic [15:0] AWADDR;
  logic [7:0] AWLEN;
  logic [2:0] AWSIZE;
  logic AWVALID, AWREADY;

  // Writing
  logic [31:0] WDATA;
  logic WLAST, WVALID, WREADY;

  // Response
  logic [1:0] BRESP;
  logic BVALID, BREADY;

  // Preparing Reading
  logic [31:0] ARADDR;
  logic [ 7:0] ARLEN;
  logic [ 2:0] ARSIZE;
  logic ARVALID, ARREADY;

  // Reading
  logic [31:0] RDATA;
  logic [ 1:0] RRESP;
  logic RLAST, RVALID, RREADY;

  modport TB_side(
      output ARESETn, AWADDR, AWLEN, AWSIZE, AWVALID, WDATA, WLAST, WVALID, BREADY, ARADDR, ARLEN, ARSIZE, ARVALID, RREADY,
      input ACLK, AWREADY, WREADY, BRESP, BVALID, ARREADY, RDATA, RRESP, RLAST, RVALID
  );
endinterface
