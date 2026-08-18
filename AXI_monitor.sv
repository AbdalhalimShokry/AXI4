package AXI_monitor_pkg;

  import AXI_transaction_pkg::*;

  class AXI_monitor;

    virtual AXI_interface.TB_side vif;
    mailbox #(AXI_transaction)    mon2scb_mbx;
    mailbox #(int)                scb2mon_mbx;

    // Persistent transaction container for coverage
    AXI_transaction cov_txn;

    covergroup cg_axi_protocol;
  option.per_instance = 1;
  option.name = "AXI_Protocol_Coverage";

  // Address bins
  cp_awaddr: coverpoint cov_txn.AWADDR {
    bins lower_bound = {16'd0};
    bins upper_bound = {16'd4092};
    bins normal_range[512] = {[16'd4 : 16'd4088]};
    ignore_bins out_of_range = {[16'd4096 : $]};
  }
  cp_araddr: coverpoint cov_txn.ARADDR {
    bins lower_bound = {16'd0};
    bins upper_bound = {16'd4092};
    bins normal_range[512] = {[16'd4 : 16'd4088]};
    ignore_bins out_of_range = {[16'd4096 : $]};
  }
  cp_awlen: coverpoint cov_txn.AWLEN { bins len_vals[] = {[0 : 255]}; }
  cp_arlen: coverpoint cov_txn.ARLEN { bins len_vals[] = {[0 : 255]}; }
  
  // Boundary bins
  cp_write_boundary: coverpoint (cov_txn.AWADDR + ((cov_txn.AWLEN + 1) * 4)) {
    bins safe_transfer[] = {[0 : 4092]};
    bins perfect_4kb = {4096};
    ignore_bins illegal_cross = {[4097 : $]};
  }
  cp_read_boundary: coverpoint (cov_txn.ARADDR + ((cov_txn.ARLEN + 1) * 4)) {
    bins safe_transfer[] = {[0 : 4092]};
    bins perfect_4kb = {4096};
    ignore_bins illegal_cross = {[4097 : $]};
  }

  // Response bins
  cp_bresp_trans: coverpoint cov_txn.BRESP {
    bins okay = {2'b00};
    bins slverr = {2'b10};
    bins okay_okay = (2'b00 => 2'b00);
    bins okay_slverr = (2'b00 => 2'b10);
    bins slverr_okay = (2'b10 => 2'b00);
    bins slverr_slverr = (2'b10 => 2'b10);
  }
  cp_rresp_trans: coverpoint cov_txn.RRESP {
    bins okay = {2'b00};
    bins slverr = {2'b10};
    bins okay_okay = (2'b00 => 2'b00);
    bins okay_slverr = (2'b00 => 2'b10);
    bins slverr_okay = (2'b10 => 2'b00);
    bins slverr_slverr = (2'b10 => 2'b10);
  }

  /*// Cross coverage
  cross_awaddr_awlen: cross cp_awaddr, cp_awlen {
    ignore_bins ignore_out = binsof (cp_awaddr.out_of_range);
  }
  cross_araddr_arlen: cross cp_araddr, cp_arlen {
    ignore_bins ignore_out = binsof (cp_araddr.out_of_range);
  }*/
endgroup
    function new();
      cg_axi_protocol = new();
    endfunction

    task run_monitor();
      AXI_transaction sampled;
      int token;

      @(posedge vif.ARESETn);
      @(posedge vif.ACLK);

      forever begin
        while (!(vif.AWVALID || vif.ARVALID)) begin
          @(posedge vif.ACLK);
          if (!vif.ARESETn) break;
        end

        if (!vif.ARESETn) begin
          @(posedge vif.ARESETn);
          @(posedge vif.ACLK);
          continue;
        end

        sampled = new();
        sampled.ARESETn = vif.ARESETn;
        sampled.AWVALID = vif.AWVALID;
        sampled.ARVALID = vif.ARVALID;

        fork
          if (sampled.AWVALID) begin
            begin
              while (!(vif.AWVALID && vif.AWREADY)) @(posedge vif.ACLK);
              sampled.AWADDR = vif.AWADDR;
              sampled.AWLEN  = vif.AWLEN;
              sampled.AWSIZE = vif.AWSIZE;
              sampled.WDATA  = new[sampled.AWLEN + 1];

              for (int i = 0; i <= sampled.AWLEN; i++) begin
                @(posedge vif.ACLK);
                while (!(vif.WVALID && vif.WREADY)) @(posedge vif.ACLK);
                sampled.WDATA[i] = vif.WDATA;
                if (vif.WLAST) break;
              end

              @(posedge vif.ACLK);
              while (!(vif.BVALID && vif.BREADY)) @(posedge vif.ACLK);
              sampled.BRESP = vif.BRESP;
            end
          end

          if (sampled.ARVALID) begin
            begin
              while (!(vif.ARVALID && vif.ARREADY)) @(posedge vif.ACLK);
              sampled.ARADDR = vif.ARADDR;
              sampled.ARLEN  = vif.ARLEN;
              sampled.ARSIZE = vif.ARSIZE;

              for (int i = 0; i <= sampled.ARLEN; i++) begin
                @(posedge vif.ACLK);
                while (!(vif.RVALID && vif.RREADY)) @(posedge vif.ACLK);
                sampled.RDATA = vif.RDATA;
                sampled.RRESP = vif.RRESP;
                if (vif.RLAST) begin
                  sampled.RLAST = vif.RLAST;
                  break;
                end
              end
            end
          end
        join

        // Sample on persistent covergroup
        cov_txn = sampled;
        cg_axi_protocol.sample();

        mon2scb_mbx.put(sampled);
        scb2mon_mbx.get(token);
      end
    endtask

  endclass
endpackage