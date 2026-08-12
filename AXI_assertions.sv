module AXI_assertions (
    AXI_interface intrf
);

  // 1. Write Address Channel
  // AWVALID and control signals must remain stable until AWREADY is asserted
  property p_awvalid_stable;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) (intrf.AWVALID && !intrf.AWREADY) |=> (intrf.AWVALID && $stable(
        intrf.AWADDR
    ) && $stable(
        intrf.AWLEN
    ) && $stable(
        intrf.AWSIZE
    ));
  endproperty

  assert_awvalid_stable :
  assert property (p_awvalid_stable)
  else $error("Protocol Violation: AWVALID or AW address/control changed before AWREADY!");


  // 2. Write Data Channel
  // WVALID and data signals must remain stable until WREADY is asserted
  property p_wvalid_stable;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) (intrf.WVALID && !intrf.WREADY) |=> (intrf.WVALID && $stable(
        intrf.WDATA
    ) && $stable(
        intrf.WLAST
    ));
  endproperty

  assert_wvalid_stable :
  assert property (p_wvalid_stable)
  else $error("Protocol Violation: WVALID or write data changed before WREADY!");


  // 3. Write Response Channel
  // BVALID and response signal must remain stable until BREADY is asserted
  property p_bvalid_stable;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) (intrf.BVALID && !intrf.BREADY) |=> (intrf.BVALID && $stable(
        intrf.BRESP
    ));
  endproperty

  assert_bvalid_stable :
  assert property (p_bvalid_stable)
  else $error("Protocol Violation: BVALID or BRESP changed before BREADY!");


  // ARVALID and control signals must remain stable until ARREADY is asserted
  property p_arvalid_stable;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) (intrf.ARVALID && !intrf.ARREADY) |=> (intrf.ARVALID && $stable(
        intrf.ARADDR
    ) && $stable(
        intrf.ARLEN
    ) && $stable(
        intrf.ARSIZE
    ));
  endproperty

  assert_arvalid_stable :
  assert property (p_arvalid_stable)
  else $error("Protocol Violation: ARVALID or AR address/control changed before ARREADY!");


  // RVALID and data/control signals must remain stable until RREADY is asserted
  property p_rvalid_stable;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) (intrf.RVALID && !intrf.RREADY) |=> (intrf.RVALID && $stable(
        intrf.RDATA
    ) && $stable(
        intrf.RRESP
    ) && $stable(
        intrf.RLAST
    ));
  endproperty

  assert_rvalid_stable :
  assert property (p_rvalid_stable)
  else $error("Protocol Violation: RVALID or read data changed before RREADY!");


  // 1. Write Address Channel
  property p_awvalid_no_x;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) intrf.AWVALID |-> !$isunknown(
        {intrf.AWADDR, intrf.AWLEN, intrf.AWSIZE}
    );
  endproperty
  assert_awvalid_no_x :
  assert property (p_awvalid_no_x)
  else $error("X/Z state on Write Address channel payload!");

  // 2. Write Data Channel
  property p_wvalid_no_x;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) intrf.WVALID |-> !$isunknown(
        {intrf.WDATA, intrf.WLAST}
    );
  endproperty
  assert_wvalid_no_x :
  assert property (p_wvalid_no_x)
  else $error("X/Z state on Write Data channel payload!");

  // 3. Write Response Channel
  property p_bvalid_no_x;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) intrf.BVALID |-> !$isunknown(
        {intrf.BRESP}
    );
  endproperty
  assert_bvalid_no_x :
  assert property (p_bvalid_no_x)
  else $error("X/Z state on Write Response channel payload!");

  // 4. Read Address Channel
  property p_arvalid_no_x;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) intrf.ARVALID |-> !$isunknown(
        {intrf.ARADDR, intrf.ARLEN, intrf.ARSIZE}
    );
  endproperty
  assert_arvalid_no_x :
  assert property (p_arvalid_no_x)
  else $error("X/Z state on Read Address channel payload!");

  // 5. Read Data Channel
  property p_rvalid_no_x;
    @(posedge intrf.ACLK) disable iff (!intrf.ARESETn) intrf.RVALID |-> !$isunknown(
        {intrf.RDATA, intrf.RRESP, intrf.RLAST}
    );
  endproperty
  assert_rvalid_no_x :
  assert property (p_rvalid_no_x)
  else $error("X/Z state on Read Data channel payload!");

endmodule
