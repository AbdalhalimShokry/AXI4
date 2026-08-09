<<<<<<< HEAD
// 1. Write Address Channel
// AWVALID and control signals must remain stable until AWREADY is asserted
property p_awvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (AWVALID && !AWREADY) |=> (AWVALID && $stable(AWADDR) && $stable(AWLEN) && $stable(AWSIZE));
endproperty

assert_awvalid_stable: assert property (p_awvalid_stable) 
    else $error("Protocol Violation: AWVALID or AW address/control changed before AWREADY!");


// 2. Write Data Channel
// WVALID and data signals must remain stable until WREADY is asserted
property p_wvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (WVALID && !WREADY) |=> (WVALID && $stable(WDATA) && $stable(WLAST));
endproperty

assert_wvalid_stable: assert property (p_wvalid_stable) 
    else $error("Protocol Violation: WVALID or write data changed before WREADY!");


// 3. Write Response Channel
// BVALID and response signal must remain stable until BREADY is asserted
property p_bvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (BVALID && !BREADY) |=> (BVALID && $stable(BRESP));
endproperty

assert_bvalid_stable: assert property (p_bvalid_stable) 
    else $error("Protocol Violation: BVALID or BRESP changed before BREADY!");


    // ARVALID and control signals must remain stable until ARREADY is asserted
property p_arvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (ARVALID && !ARREADY) |=> (ARVALID && $stable(ARADDR) && $stable(ARLEN) && $stable(ARSIZE));
endproperty

assert_arvalid_stable: assert property (p_arvalid_stable) 
    else $error("Protocol Violation: ARVALID or AR address/control changed before ARREADY!");


    // RVALID and data/control signals must remain stable until RREADY is asserted
property p_rvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (RVALID && !RREADY) |=> (RVALID && $stable(RDATA) && $stable(RRESP) && $stable(RLAST));
endproperty

assert_rvalid_stable: assert property (p_rvalid_stable) 
    else $error("Protocol Violation: RVALID or read data changed before RREADY!");


    // 1. Write Address Channel
property p_awvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    AWVALID |-> !$isunknown({AWADDR, AWLEN, AWSIZE});
endproperty
assert_awvalid_no_x: assert property (p_awvalid_no_x) 
    else $error("X/Z state on Write Address channel payload!");

// 2. Write Data Channel
property p_wvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    WVALID |-> !$isunknown({WDATA, WLAST});
endproperty
assert_wvalid_no_x: assert property (p_wvalid_no_x) 
    else $error("X/Z state on Write Data channel payload!");

// 3. Write Response Channel
property p_bvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    BVALID |-> !$isunknown({BRESP});
endproperty
assert_bvalid_no_x: assert property (p_bvalid_no_x) 
    else $error("X/Z state on Write Response channel payload!");

// 4. Read Address Channel
property p_arvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    ARVALID |-> !$isunknown({ARADDR, ARLEN, ARSIZE});
endproperty
assert_arvalid_no_x: assert property (p_arvalid_no_x) 
    else $error("X/Z state on Read Address channel payload!");

// 5. Read Data Channel
property p_rvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    RVALID |-> !$isunknown({RDATA, RRESP, RLAST});
endproperty
assert_rvalid_no_x: assert property (p_rvalid_no_x) 
=======
// 1. Write Address Channel
// AWVALID and control signals must remain stable until AWREADY is asserted
property p_awvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (AWVALID && !AWREADY) |=> (AWVALID && $stable(AWADDR) && $stable(AWLEN) && $stable(AWSIZE));
endproperty

assert_awvalid_stable: assert property (p_awvalid_stable) 
    else $error("Protocol Violation: AWVALID or AW address/control changed before AWREADY!");


// 2. Write Data Channel
// WVALID and data signals must remain stable until WREADY is asserted
property p_wvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (WVALID && !WREADY) |=> (WVALID && $stable(WDATA) && $stable(WLAST));
endproperty

assert_wvalid_stable: assert property (p_wvalid_stable) 
    else $error("Protocol Violation: WVALID or write data changed before WREADY!");


// 3. Write Response Channel
// BVALID and response signal must remain stable until BREADY is asserted
property p_bvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (BVALID && !BREADY) |=> (BVALID && $stable(BRESP));
endproperty

assert_bvalid_stable: assert property (p_bvalid_stable) 
    else $error("Protocol Violation: BVALID or BRESP changed before BREADY!");


    // ARVALID and control signals must remain stable until ARREADY is asserted
property p_arvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (ARVALID && !ARREADY) |=> (ARVALID && $stable(ARADDR) && $stable(ARLEN) && $stable(ARSIZE));
endproperty

assert_arvalid_stable: assert property (p_arvalid_stable) 
    else $error("Protocol Violation: ARVALID or AR address/control changed before ARREADY!");


    // RVALID and data/control signals must remain stable until RREADY is asserted
property p_rvalid_stable;
    @(posedge ACLK) disable iff (!ARESETn)
    (RVALID && !RREADY) |=> (RVALID && $stable(RDATA) && $stable(RRESP) && $stable(RLAST));
endproperty

assert_rvalid_stable: assert property (p_rvalid_stable) 
    else $error("Protocol Violation: RVALID or read data changed before RREADY!");


    // 1. Write Address Channel
property p_awvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    AWVALID |-> !$isunknown({AWADDR, AWLEN, AWSIZE});
endproperty
assert_awvalid_no_x: assert property (p_awvalid_no_x) 
    else $error("X/Z state on Write Address channel payload!");

// 2. Write Data Channel
property p_wvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    WVALID |-> !$isunknown({WDATA, WLAST});
endproperty
assert_wvalid_no_x: assert property (p_wvalid_no_x) 
    else $error("X/Z state on Write Data channel payload!");

// 3. Write Response Channel
property p_bvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    BVALID |-> !$isunknown({BRESP});
endproperty
assert_bvalid_no_x: assert property (p_bvalid_no_x) 
    else $error("X/Z state on Write Response channel payload!");

// 4. Read Address Channel
property p_arvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    ARVALID |-> !$isunknown({ARADDR, ARLEN, ARSIZE});
endproperty
assert_arvalid_no_x: assert property (p_arvalid_no_x) 
    else $error("X/Z state on Read Address channel payload!");

// 5. Read Data Channel
property p_rvalid_no_x;
    @(posedge ACLK) disable iff (!ARESETn)
    RVALID |-> !$isunknown({RDATA, RRESP, RLAST});
endproperty
assert_rvalid_no_x: assert property (p_rvalid_no_x) 
>>>>>>> 26658b03047a4f62ba45de5609f549604b06267a
    else $error("X/Z state on Read Data channel payload!");