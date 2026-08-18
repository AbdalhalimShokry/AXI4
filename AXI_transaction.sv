package AXI_transaction_pkg;

  class AXI_transaction #(
      parameter DATA_WIDTH   = 32,
      parameter ADDR_WIDTH   = 16,
      parameter MEMORY_DEPTH = 1024
  );

    logic                       ARESETn;
    rand logic [ADDR_WIDTH-1:0] AWADDR;
    rand logic [7:0]            AWLEN;
    rand logic [2:0]            AWSIZE;
    logic                       AWVALID;
    rand logic [DATA_WIDTH-1:0] WDATA[];
    logic                       WVALID;
    logic                       WLAST;
    rand logic                  BREADY;
    rand logic [ADDR_WIDTH-1:0] ARADDR;
    rand logic [7:0]            ARLEN;
    rand logic [2:0]            ARSIZE;
    logic                       ARVALID;
    rand logic                  RREADY;

    logic                       AWREADY;
    logic                       WREADY;
    logic [1:0]                 BRESP;
    logic                       BVALID;
    logic                       ARREADY;
    logic [DATA_WIDTH-1:0]      RDATA;
    logic [1:0]                 RRESP;
    logic                       RVALID;
    logic                       RLAST;

    constraint c_axi_protocol {
      AWSIZE == 3'd2;
      ARSIZE == 3'd2;

      (AWADDR % 4) == 0;
      (ARADDR % 4) == 0;

      AWADDR < 4096;
      ARADDR < 4096;

      WDATA.size() == (AWLEN + 1);
    }

    function void display_transaction(string tag = "DEFAULT");
      $display("=========================================================");
      $display("[%s] AXI Transaction:", tag);
      if (AWVALID)
        $display("Write Channel: AWADDR = 0x%0h, AWLEN = %0d", AWADDR, AWLEN);
      if (ARVALID)
        $display("Read Channel : ARADDR = 0x%0h, ARLEN = %0d", ARADDR, ARLEN);
      $display("=========================================================");
    endfunction

  endclass

endpackage