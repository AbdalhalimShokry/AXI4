import AXI_transaction_pkg::*;

package AXI_driver_pkg;

  class AXI_driver;

    // ===== Virtual Interface ==========================
    virtual AXI_interface.TB_side vif;
    // ==================================================


    // ===== Mailboxes ==================================
    mailbox #(AXI_transaction)    gen2drv_mbx;
    mailbox #(int)                drv2gen_mbx;
    // ==================================================


    // ===== Run Task ===================================
    task run_driver();
      AXI_transaction txn;

      // Initialize signals
      vif.AWVALID <= 1'b0;
      vif.WVALID  <= 1'b0;
      vif.WLAST   <= 1'b0;
      vif.BREADY  <= 1'b0;
      vif.ARVALID <= 1'b0;
      vif.RREADY  <= 1'b0;

      forever begin

        gen2drv_mbx.get(txn);

        fork
          // ==================================================
          // THREAD 1: Write Channels
          // ==================================================
          begin
            // --- AW Channel (Write Address) ---
            @(negedge vif.ACLK);
            vif.AWADDR  <= txn.AWADDR;
            vif.AWLEN   <= txn.AWLEN;
            vif.AWSIZE  <= txn.AWSIZE;
            vif.AWVALID <= 1'b1;

            // Wait for handshake
            do begin
              @(negedge vif.ACLK);
            end while (vif.AWREADY !== 1'b1);
            vif.AWVALID <= 1'b0;

            // --- W Channel (Write Data Burst) ---
            for (int i = 0; i <= txn.AWLEN; i++) begin
              vif.WDATA  <= txn.WDATA[i];  // Driving the same randomized word across the burst
              vif.WLAST  <= (i == txn.AWLEN) ? 1'b1 : 1'b0;
              vif.WVALID <= 1'b1;

              do begin
                @(negedge vif.ACLK);
              end while (vif.WREADY !== 1'b1);
            end
            vif.WVALID <= 1'b0;
            vif.WLAST  <= 1'b0;

            // --- B Channel (Write Response) ---
            vif.BREADY <= 1'b1;
            do begin
              @(negedge vif.ACLK);
            end while (vif.BVALID !== 1'b1);
            vif.BREADY <= 1'b0;
          end

          // ==================================================
          // THREAD 2: Read Channels (AR, R)
          // ==================================================
          begin
            // --- AR Channel (Read Address) ---
            @(negedge vif.ACLK);
            vif.ARADDR  <= txn.ARADDR;
            vif.ARLEN   <= txn.ARLEN;
            vif.ARSIZE  <= txn.ARSIZE;
            vif.ARVALID <= 1'b1;

            do begin
              @(negedge vif.ACLK);
            end while (vif.ARREADY !== 1'b1);
            vif.ARVALID <= 1'b0;

            // --- R Channel (Read Data Burst) ---
            vif.RREADY  <= 1'b1;
            for (int i = 0; i <= txn.ARLEN; i++) begin
              do begin
                @(negedge vif.ACLK);
              end while (vif.RVALID !== 1'b1);
            end
            vif.RREADY <= 1'b0;
          end
        join

        // Return done token to generator
        drv2gen_mbx.put(1);
      end
    endtask

  endclass
endpackage
