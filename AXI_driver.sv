package AXI_driver_pkg;

  import AXI_transaction_pkg::*;

  class AXI_driver;

    virtual AXI_interface.TB_side vif;
    mailbox #(AXI_transaction)    gen2drv_mbx;
    mailbox #(int)                drv2gen_mbx;

    task run_driver();
      AXI_transaction txn;

      // 1. Initialize bus signals to idle
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

      // 2. Wait for reset release
      @(posedge vif.ARESETn);
      repeat (2) @(posedge vif.ACLK);

      forever begin
        gen2drv_mbx.get(txn);

        fork
          // ==================================================
          // WRITE CHANNELS
          // ==================================================
          if (txn.AWVALID) begin
            begin
              fork
                // 1. Write Address Channel
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

                // 2. Write Data Channel
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
              join

              // 3. Write Response Channel
              @(negedge vif.ACLK);
              vif.BREADY <= 1'b1;

              do begin
                @(posedge vif.ACLK);
              end while (!vif.BVALID);

              @(negedge vif.ACLK);
              vif.BREADY <= 1'b0;
            end
          end

          // ==================================================
          // READ CHANNELS
          // ==================================================
          if (txn.ARVALID) begin
            begin
              // 1. Read Address Channel
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

              // 2. Read Data Channel
              @(negedge vif.ACLK);
              vif.RREADY <= 1'b1;

              for (int i = 0; i <= txn.ARLEN; i++) begin
                do begin
                  @(posedge vif.ACLK);
                end while (!vif.RVALID);
              end

              @(negedge vif.ACLK);
              vif.RREADY <= 1'b0;
            end
          end
        join

        drv2gen_mbx.put(1);
      end
    endtask

  endclass
endpackage