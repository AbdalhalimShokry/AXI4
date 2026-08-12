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

        // Wait for the next clock edge
        @(posedge vif.ACLK);

        sampled = new();

        // Reset
        if (!vif.ARESETn) begin
          continue;
        end

        sampled.ARESETn = vif.ARESETn;


        fork

          // ==================================================
          // WRITE OPERATION
          // AW -> W -> B
          // ==================================================
          begin

            // ---------------- Write Address ----------------
            do begin
              @(posedge vif.ACLK);
            end while (!(vif.AWVALID && vif.AWREADY));

            sampled.AWADDR = vif.AWADDR;
            sampled.AWLEN  = vif.AWLEN;
            sampled.AWSIZE = vif.AWSIZE;

            // Allocate space for all write data beats
            sampled.WDATA  = new[vif.AWLEN + 1];


            // ---------------- Write Data -------------------
            for (int i = 0; i <= vif.AWLEN; i++) begin
              do begin
                @(posedge vif.ACLK);
              end while (!(vif.WVALID && vif.WREADY));

              sampled.WDATA[i] = vif.WDATA;

              // Last write beat
              if (vif.WLAST) begin
                break;
              end
            end


            // ---------------- Write Response ---------------
            do begin
              @(posedge vif.ACLK);
            end while (!(vif.BVALID && vif.BREADY));

            sampled.BRESP = vif.BRESP;
          end


          // ==================================================
          // READ OPERATION
          // AR -> R
          // ==================================================
          begin

            // ---------------- Read Address -----------------
            do begin
              @(posedge vif.ACLK);
            end while (!(vif.ARVALID && vif.ARREADY));

            sampled.ARADDR = vif.ARADDR;
            sampled.ARLEN  = vif.ARLEN;
            sampled.ARSIZE = vif.ARSIZE;

            // Allocate space for all read data beats
            sampled.RDATA  = new[vif.ARLEN + 1];


            // ---------------- Read Data --------------------
            for (int i = 0; i <= vif.ARLEN; i++) begin
              do begin
                @(posedge vif.ACLK);
              end while (!(vif.RVALID && vif.RREADY));

              sampled.RDATA[i] = vif.RDATA;
              sampled.RRESP = vif.RRESP;

              // Last read beat
              if (vif.RLAST) begin
                sampled.RLAST = vif.RLAST;
                break;
              end
            end
          end
        join

        // Send the complete transaction to scoreboard
        mon2scb_mbx.put(sampled);

      end
    endtask

  endclass
endpackage
