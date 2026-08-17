package AXI_monitor_pkg;

  import AXI_transaction_pkg::*;

  class AXI_monitor;

    virtual AXI_interface.TB_side vif;

    mailbox #(AXI_transaction)    mon2scb_mbx;
    mailbox #(int)                scb2mon_mbx;

    task run_monitor();
      AXI_transaction sampled;
      int token;

      // Wait until reset is fully released
      @(posedge vif.ARESETn);
      @(posedge vif.ACLK);

      forever begin
        // Wait for an active address request
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
          // WRITE OPERATION
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

          // READ OPERATION
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

        sampled.cg_axi_protocol.sample();

        mon2scb_mbx.put(sampled);
        scb2mon_mbx.get(token);
      end
    endtask

  endclass
endpackage
