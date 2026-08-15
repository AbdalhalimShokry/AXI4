package AXI_monitor_pkg;

  import AXI_transaction_pkg::*;

  class AXI_monitor;

    // ===== Virtual Interface ==========================
    virtual AXI_interface.TB_side vif;
    // ==================================================


    // ===== Mailbox ====================================
    mailbox #(AXI_transaction) mon2scb_mbx;
    // ==================================================


    // ===== Run Monitor ================================
    task run_monitor();

      AXI_transaction sampled;

      forever begin

        sampled = new();

        // --------------------------------------------------
        // Wait until at least one operation is requested
        // --------------------------------------------------
        @(posedge vif.ACLK);

        if (!vif.ARESETn) continue;

        do begin
          @(posedge vif.ACLK);
        end while (!(vif.AWVALID || vif.ARVALID));

        sampled.ARESETn = vif.ARESETn;

        // --------------------------------------------------
        // Record which operations belong to this transaction
        // --------------------------------------------------
        sampled.AWVALID = vif.AWVALID;
        sampled.ARVALID = vif.ARVALID;


        fork

          // ==================================================
          // WRITE OPERATION
          // ==================================================
          if (sampled.AWVALID) begin
            begin

              // ---------------- Write Address ----------------
              do begin
                @(posedge vif.ACLK);
              end while (!(vif.AWVALID && vif.AWREADY));

              sampled.AWADDR = vif.AWADDR;
              sampled.AWLEN  = vif.AWLEN;
              sampled.AWSIZE = vif.AWSIZE;

              // Allocate write data array
              sampled.WDATA  = new[sampled.AWLEN + 1];

              // ---------------- Write Data -------------------
              for (int i = 0; i <= sampled.AWLEN; i++) begin

                do begin
                  @(posedge vif.ACLK);
                end while (!(vif.WVALID && vif.WREADY));

                sampled.WDATA[i] = vif.WDATA;

                if (vif.WLAST) break;

              end

              // ---------------- Write Response ---------------
              do begin
                @(posedge vif.ACLK);
              end while (!(vif.BVALID && vif.BREADY));

              sampled.BRESP = vif.BRESP;

            end
          end


          // ==================================================
          // READ OPERATION
          // ==================================================
          if (sampled.ARVALID) begin
            begin

              // ---------------- Read Address -----------------
              do begin
                @(posedge vif.ACLK);
              end while (!(vif.ARVALID && vif.ARREADY));

              sampled.ARADDR = vif.ARADDR;
              sampled.ARLEN  = vif.ARLEN;
              sampled.ARSIZE = vif.ARSIZE;

              // Allocate read data array
              sampled.RDATA  = new[sampled.ARLEN + 1];

              // ---------------- Read Data --------------------
              for (int i = 0; i <= sampled.ARLEN; i++) begin

                do begin
                  @(posedge vif.ACLK);
                end while (!(vif.RVALID && vif.RREADY));

                sampled.RDATA[i] = vif.RDATA;
                sampled.RRESP[i] = vif.RRESP;

                if (vif.RLAST) begin
                  sampled.RLAST = vif.RLAST;
                  break;
                end

              end

            end
          end

        join


        // --------------------------------------------------
        // Send complete transaction to scoreboard
        // --------------------------------------------------
        mon2scb_mbx.put(sampled);

      end

    endtask

  endclass

endpackage
