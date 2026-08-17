package AXI_transaction_pkg;

  class AXI_transaction #(
      parameter DATA_WIDTH   = 32,
      parameter ADDR_WIDTH   = 16,
      parameter MEMORY_DEPTH = 1024
  );

    // ===== Randomized inputss ==========================
    logic ARESETn;  // not in the waveform in the specs
    rand logic [ADDR_WIDTH-1:0] AWADDR;
    rand logic [7:0] AWLEN;  // not in the waveform in the specs
    rand logic [2:0] AWSIZE;  // not in the waveform in the specs
    logic AWVALID;
    rand logic [DATA_WIDTH-1:0] WDATA[];
    logic WVALID;
    logic WLAST;
    rand logic BREADY;
    rand logic [ADDR_WIDTH-1:0] ARADDR;
    rand logic [7:0] ARLEN;  // not in the waveform in the specs
    rand logic [2:0] ARSIZE;  // not in the waveform in the specs
    logic ARVALID;
    rand logic RREADY;
    // ==================================================


    // ===== Sampled outputs ============================
    logic AWREADY;
    logic WREADY;
    logic [1:0] BRESP;
    logic BVALID;
    logic ARREADY;
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0] RRESP;
    logic RVALID;
    logic RLAST;
    // ==================================================


    // ===== Constraints ================================
    constraint c1 {
      AWSIZE == 2;  // as data is 32 bit, so 4 bytes
      ARSIZE == 2;  // as data is 32 bit, so 4 bytes

      (AWADDR % 4) == 0;  // the address must be multible of 4
      (ARADDR % 4) == 0;  // the address must be multible of 4

      AWADDR + ((AWLEN + 1) * 4) <= 4096; // make sure not to exceed the last address in the memory 
                                          // [ ((AWLEN + 1) * 4) this represents the number of bytes added to the address, no. of beats*no. of bytes in each beat]
      ARADDR + ((ARLEN + 1) * 4) <= 4096; // make sure not to exceed the last address in the memory
                                          // [ ((ARLEN + 1) * 4) this represents the number of bytes added to the address, no. of beats*no. of bytes in each beat]

      WDATA.size() == (AWLEN + 1);  // the burst (no. of beats) must be equal to awlen +1
    }
    // ==================================================


    // ===== Coverage ===================================
    covergroup cg_axi_protocol;

      // ===== 1. Address Regions (Write and Read) =================================================
      cp_awaddr: coverpoint AWADDR {
        bins lower_bound = {16'd0};
        bins upper_bound = {16'd4092};
        bins normal_range[512] = {[16'd4 : 16'd4088]};
        bins out_of_range = {[16'd4096 : $]};
      }

      cp_araddr: coverpoint ARADDR {
        bins lower_bound = {16'd0};
        bins upper_bound = {16'd4092};
        bins normal_range[512] = {[16'd4 : 16'd4088]};
        bins out_of_range = {[16'd4096 : $]};
      }
      // ===========================================================================================


      // ===== 2. Burst Lengths ====================================================================
      cp_awlen: coverpoint AWLEN {
        bins len_vals[] = {[0 : 255]};
      }

      cp_arlen: coverpoint ARLEN {bins len_vals[] = {[0 : 255]};}
      // ===========================================================================================


      // ===== 3. 4KB Boundary Conditions ==========================================================
      cp_write_boundary: coverpoint (AWADDR + ((AWLEN + 1) * 4)) {
        bins safe_transfer[] = {[0 : 4092]};
        bins perfect_4kb = {4096};
        bins illegal_cross = {[4097 : $]};
      }

      cp_read_boundary: coverpoint (ARADDR + ((ARLEN + 1) * 4)) {
        bins safe_transfer[] = {[0 : 4092]};
        bins perfect_4kb = {4096};
        bins illegal_cross = {[4097 : $]};
      }
      // ===========================================================================================


      // ===== 4. Slave Response Transitions =======================================================
      cp_bresp_trans: coverpoint BRESP {
        bins okay = {2'b00};
        bins slverr = {2'b10};
        bins okay_okay = (2'b00 => 2'b00);
        bins okay_slverr = (2'b00 => 2'b10);
        bins slverr_okay = (2'b10 => 2'b00);
        bins slverr_slverr = (2'b10 => 2'b10);
      }

      cp_rresp_trans: coverpoint RRESP {
        bins okay = {2'b00};
        bins slverr = {2'b10};
        bins okay_okay = (2'b00 => 2'b00);
        bins okay_slverr = (2'b00 => 2'b10);
        bins slverr_okay = (2'b10 => 2'b00);
        bins slverr_slverr = (2'b10 => 2'b10);
      }
      // ===========================================================================================


      // ===== 5. Cross Coverage (Address Regions x Burst Lengths) =================================
      cross_awaddr_awlen: cross cp_awaddr, cp_awlen{
        ignore_bins ignore_out = binsof (cp_awaddr.out_of_range);
      }

      cross_araddr_arlen: cross cp_araddr, cp_arlen{
        ignore_bins ignore_out = binsof (cp_araddr.out_of_range);
      }
    // ===========================================================================================

    endgroup
    // ==================================================


    // ===== Display ====================================
    function void display_transaction(string tag = "DEFAULT");
      $display("=========================================================");
      $display("[%s] AXI Transaction:", tag);
      $display("Write Channel: AWADDR = 'h%0h, AWLEN = %0d, WDATA = %p", AWADDR, AWLEN, WDATA);
      $display("Read Channel : ARADDR = 'h%0h, ARLEN = %0d", ARADDR, ARLEN);
      $display("=========================================================");
    endfunction
    // ==================================================

    function new();
      cg_axi_protocol = new();
    endfunction

  endclass  //AXI_transaction

endpackage
