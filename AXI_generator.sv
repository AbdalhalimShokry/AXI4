package AXI_generator_pkg;

  import AXI_transaction_pkg::*;

  class AXI_generator;

    virtual AXI_interface.TB_side vif;

    mailbox #(AXI_transaction)    gen2drv_mbx;
    mailbox #(int)                drv2gen_mbx;
    mailbox #(AXI_transaction)    gen2scb_mbx;
    mailbox #(int)                scb2gen_mbx;

    int unsigned                  num_transactions = 10000;

    task send_txn(AXI_transaction txn, string tag);
      int token;
      txn.display_transaction(tag);
      gen2scb_mbx.put(txn);
      gen2drv_mbx.put(txn);
      drv2gen_mbx.get(token);
      scb2gen_mbx.get(token);
    endtask

    task run_generator();
      AXI_transaction txn;

      if (vif != null) begin
        @(posedge vif.ARESETn);
        @(posedge vif.ACLK);
      end

      // ===== Directed Edge & Toggle Cases ====================
      // 1. Lower Bound Write
      txn = new();
      txn.AWVALID = 1'b1; txn.ARVALID = 1'b0;
      txn.AWADDR = 16'd0; txn.AWLEN = 8'd0; txn.AWSIZE = 3'd2;
      txn.WDATA = new[1]; txn.WDATA[0] = 32'hA5A5_0001;
      send_txn(txn, "DIR_LOWER_BOUND_WR");

      // 2. Lower Bound Read
      txn = new();
      txn.AWVALID = 1'b0; txn.ARVALID = 1'b1;
      txn.ARADDR = 16'd0; txn.ARLEN = 8'd0; txn.ARSIZE = 3'd2;
      send_txn(txn, "DIR_LOWER_BOUND_RD");

      // 3. Upper Bound Write
      txn = new();
      txn.AWVALID = 1'b1; txn.ARVALID = 1'b0;
      txn.AWADDR = 16'd4092; txn.AWLEN = 8'd0; txn.AWSIZE = 3'd2;
      txn.WDATA = new[1]; txn.WDATA[0] = 32'hDEAD_BEEF;
      send_txn(txn, "DIR_UPPER_BOUND_WR");

      // 4. Upper Bound Read
      txn = new();
      txn.AWVALID = 1'b0; txn.ARVALID = 1'b1;
      txn.ARADDR = 16'd4092; txn.ARLEN = 8'd0; txn.ARSIZE = 3'd2;
      send_txn(txn, "DIR_UPPER_BOUND_RD");

      // 5. Exact 4KB Max Burst Write
      txn = new();
      txn.AWVALID = 1'b1; txn.ARVALID = 1'b0;
      txn.AWADDR = 16'd3072; txn.AWLEN = 8'd255; txn.AWSIZE = 3'd2;
      txn.WDATA = new[256];
      foreach (txn.WDATA[k]) txn.WDATA[k] = k + 1;
      send_txn(txn, "DIR_4KB_EXACT_WR");

      // 6. Out of Bounds Write
      txn = new();
      txn.AWVALID = 1'b1; txn.ARVALID = 1'b0;
      txn.AWADDR = 16'hF000; txn.AWLEN = 8'd0; txn.AWSIZE = 3'd2;
      txn.WDATA = new[1]; txn.WDATA[0] = 32'hBAAD_F00D;
      send_txn(txn, "DIR_OUT_OF_BOUNDS_WR");

      // 7. Out of Bounds Read
      txn = new();
      txn.AWVALID = 1'b0; txn.ARVALID = 1'b1;
      txn.ARADDR = 16'hF000; txn.ARLEN = 8'd0; txn.ARSIZE = 3'd2;
      send_txn(txn, "DIR_OUT_OF_BOUNDS_RD");

      // 8. Illegal Boundary Cross Write
      txn = new();
      txn.AWVALID = 1'b1; txn.ARVALID = 1'b0;
      txn.AWADDR = 16'd4092; txn.AWLEN = 8'd1; txn.AWSIZE = 3'd2;
      txn.WDATA = new[2]; txn.WDATA[0] = 32'h1; txn.WDATA[1] = 32'h2;
      send_txn(txn, "DIR_ILLEGAL_CROSS_WR");

      // 9. Data Integrity Write
      txn = new();
      txn.AWVALID = 1'b1; txn.ARVALID = 1'b0;
      txn.AWADDR = 16'h0100; txn.AWLEN = 8'd3; txn.AWSIZE = 3'd2;
      txn.WDATA = new[4];
      foreach (txn.WDATA[k]) txn.WDATA[k] = 32'h55AA_0000 + k;
      send_txn(txn, "DIR_WRITE_CHECK");

      // 10. Data Integrity Read Same Address
      txn = new();
      txn.AWVALID = 1'b0; txn.ARVALID = 1'b1;
      txn.ARADDR = 16'h0100; txn.ARLEN = 8'd3; txn.ARSIZE = 3'd2;
      send_txn(txn, "DIR_READ_CHECK");
      // =======================================================

      // ===== Randomized Transactions =========================
      repeat (num_transactions) begin
        txn = new();
        assert (txn.randomize())
        else begin
          $display("RANDOMIZATION FAILED");
          $stop;
        end

        if ($urandom_range(0, 1)) begin
          txn.AWVALID = 1'b1;
          txn.ARVALID = 1'b0;
        end else begin
          txn.AWVALID = 1'b0;
          txn.ARVALID = 1'b1;
        end

        send_txn(txn, "GEN_RANDOM");
      end

      $display("[%0t] Generator finished: %0d transactions sent", $time, (num_transactions + 10));
    endtask

  endclass
endpackage