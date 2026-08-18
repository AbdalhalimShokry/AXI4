package AXI_driver_pkg;

  import AXI_transaction_pkg::*;

  class AXI_driver;

    virtual AXI_interface.TB_side vif;
    mailbox #(AXI_transaction)    gen2drv_mbx;
    mailbox #(int)                drv2gen_mbx;

    task run_driver();
      AXI_transaction txn;

      vif.AWVALID <= 1'b0;
      vif.AWADDR  <= '0;
      vif.AWLEN   <= '0;
      vif.AWSIZE  <= '0;
      vif.WVALID  <= 1'b0;
      vif.WDATA   <= '0;
      vif.WLAST   <= 1'b0;
      vif.BREADY  <= 1'b0;
      vif.ARVALID <= 1'b0;
      vif.ARADDR  <= '0;
      vif.ARLEN   <= '0;
      vif.ARSIZE  <= '0;
      vif.RREADY  <= 1'b0;

      @(posedge vif.ARESETn);
      repeat (2) @(posedge vif.ACLK);

      forever begin
        gen2drv_mbx.get(txn);

        fork
          // ================= WRITE =================
          if (txn.AWVALID) begin
            begin
              fork
                // Write Address
                begin
                  @(negedge vif.ACLK);
                  vif.AWADDR  <= txn.AWADDR;
                  vif.AWLEN   <= txn.AWLEN;
                  vif.AWSIZE  <= txn.AWSIZE;
                  vif.AWVALID <= 1'b1;

                  do begin
                    @(posedge vif.ACLK);
                  end while (!vif.AWREADY);

                  @(negedge vif.ACLK);
                  vif.AWVALID <= 1'b0;
                end

                // Write Data
                begin
                  for (int i = 0; i <= txn.AWLEN; i++) begin
                    @(negedge vif.ACLK);
                    vif.WDATA  <= txn.WDATA[i];
                    vif.WLAST  <= (i == txn.AWLEN) ? 1'b1 : 1'b0;
                    vif.WVALID <= 1'b1;

                    do begin
                      @(posedge vif.ACLK);
                    end while (!vif.WREADY);
                  end

                  @(negedge vif.ACLK);
                  vif.WVALID <= 1'b0;
                  vif.WLAST  <= 1'b0;
                end
              join_none

              // Backpressure on BREADY to test BVALID stability property
              @(posedge vif.ACLK);
              while (!vif.BVALID) @(posedge vif.ACLK);
              repeat (2) @(posedge vif.ACLK); // Hold BREADY low while BVALID is high!

              @(negedge vif.ACLK);
              vif.BREADY <= 1'b1;
              @(posedge vif.ACLK);
              @(negedge vif.ACLK);
              vif.BREADY <= 1'b0;
            end
          end

          // ================= READ =================
          if (txn.ARVALID) begin
            begin
              // Read Address
              @(negedge vif.ACLK);
              vif.ARADDR  <= txn.ARADDR;
              vif.ARLEN   <= txn.ARLEN;
              vif.ARSIZE  <= txn.ARSIZE;
              vif.ARVALID <= 1'b1;

              do begin
                @(posedge vif.ACLK);
              end while (!vif.ARREADY);

              @(negedge vif.ACLK);
              vif.ARVALID <= 1'b0;

              // Backpressure on RREADY to test RVALID stability property
              @(posedge vif.ACLK);
              while (!vif.RVALID) @(posedge vif.ACLK);
              repeat (2) @(posedge vif.ACLK); // Hold RREADY low while RVALID is high!

              for (int i = 0; i <= txn.ARLEN; i++) begin
                @(negedge vif.ACLK);
                vif.RREADY <= 1'b1;
                do begin
                  @(posedge vif.ACLK);
                end while (!vif.RVALID);
                @(negedge vif.ACLK);
                vif.RREADY <= 1'b0;
              end
            end
          end
        join

        drv2gen_mbx.put(1);
      end
    endtask

  endclass
endpackage