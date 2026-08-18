module AXI_assertions (
    input logic        ACLK,
    input logic        ARESETn,
    input logic [15:0] AWADDR,
    input logic [ 7:0] AWLEN,
    input logic [ 2:0] AWSIZE,
    input logic        AWVALID,
    input logic        AWREADY,
    input logic [31:0] WDATA,
    input logic        WVALID,
    input logic        WLAST,
    input logic        WREADY,
    input logic [ 1:0] BRESP,
    input logic        BVALID,
    input logic        BREADY,
    input logic [15:0] ARADDR,
    input logic [ 7:0] ARLEN,
    input logic [ 2:0] ARSIZE,
    input logic        ARVALID,
    input logic        ARREADY,
    input logic [31:0] RDATA,
    input logic [ 1:0] RRESP,
    input logic        RVALID,
    input logic        RLAST,
    input logic        RREADY
);

  // 1. Stability Assertions
  property p_awvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    AWVALID && !AWREADY |=> AWVALID && $stable(AWADDR) && $stable(AWLEN) && $stable(AWSIZE);
  endproperty
  assert_awvalid_stable: assert property (p_awvalid_stable);
  cover_awvalid_stable:  cover  property (p_awvalid_stable);

  property p_wvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    WVALID && !WREADY |=> WVALID && $stable(WDATA) && $stable(WLAST);
  endproperty
  assert_wvalid_stable: assert property (p_wvalid_stable);
  cover_wvalid_stable:  cover  property (p_wvalid_stable);

  property p_bvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    BVALID && !BREADY |=> BVALID && $stable(BRESP);
  endproperty
  assert_bvalid_stable: assert property (p_bvalid_stable);
  cover_bvalid_stable:  cover  property (p_bvalid_stable);

  property p_arvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    ARVALID && !ARREADY |=> ARVALID && $stable(ARADDR) && $stable(ARLEN) && $stable(ARSIZE);
  endproperty
  assert_arvalid_stable: assert property (p_arvalid_stable);
  cover_arvalid_stable:  cover  property (p_arvalid_stable);

  property p_rvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    RVALID && !RREADY |=> RVALID && $stable(RDATA) && $stable(RRESP) && $stable(RLAST);
  endproperty
  assert_rvalid_stable: assert property (p_rvalid_stable);
  cover_rvalid_stable:  cover  property (p_rvalid_stable);

  // 2. Known-Value (No-X) Checks
  assert_awvalid_no_x: assert property (@(posedge ACLK) disable iff (!ARESETn) AWVALID |-> !$isunknown({AWADDR, AWLEN, AWSIZE}));
  assert_wvalid_no_x:  assert property (@(posedge ACLK) disable iff (!ARESETn) WVALID  |-> !$isunknown({WDATA, WLAST}));
  assert_bvalid_no_x:  assert property (@(posedge ACLK) disable iff (!ARESETn) BVALID  |-> !$isunknown(BRESP));
  assert_arvalid_no_x: assert property (@(posedge ACLK) disable iff (!ARESETn) ARVALID |-> !$isunknown({ARADDR, ARLEN, ARSIZE}));
  assert_rvalid_no_x:  assert property (@(posedge ACLK) disable iff (!ARESETn) RVALID  |-> !$isunknown({RDATA, RRESP, RLAST}));

endmodule