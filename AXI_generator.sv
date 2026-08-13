package AXI_generator_pkg;

  import AXI_transaction_pkg::*;

  class AXI_generator;

    // ===== Mailboxes ==========================
    mailbox #(AXI_transaction) gen2drv_mbx;
    mailbox #(int) drv2gen_mbx;
    mailbox #(AXI_transaction) gen2scb_mbx;
    mailbox #(int) scb2gen_mbx;
    // ==========================================


    int unsigned num_transactions = 10000;  // increse this if you did not hit the coverage goals
    bit done = 0;

    task run_generator();
      AXI_transaction txn;
      int token;

      // ===== Directed Cases ==================================
      // 1. Lower Bound (Address 0, Single Beat)
      txn = new();
      txn.AWADDR = 16'd0;
      txn.AWLEN = 8'd0;
      txn.AWSIZE = 3'd2;
      txn.display_transaction("DIR_LOWER_BOUND");
      gen2drv_mbx.put(txn);
      drv2gen_mbx.get(token);
      gen2scb_mbx.put(txn);
      scb2gen_mbx.get(token);

      // 2. Upper Bound (Last valid address, Single Beat)
      txn = new();
      txn.AWADDR = 16'd4092;
      txn.AWLEN = 8'd0;
      txn.AWSIZE = 3'd2;
      txn.display_transaction("DIR_UPPER_BOUND");
      gen2drv_mbx.put(txn);
      drv2gen_mbx.get(token);
      gen2scb_mbx.put(txn);
      scb2gen_mbx.get(token);

      // 3. Exact 4KB Boundary Termination (Max Burst)
      // 256 beats * 4 bytes = 1024 bytes. 3072 + 1024 = 4096 (Exact boundary).
      txn = new();
      txn.AWADDR = 16'd3072;
      txn.AWLEN = 8'd255;
      txn.AWSIZE = 3'd2;
      txn.display_transaction("DIR_4KB_EXACT");
      gen2drv_mbx.put(txn);
      drv2gen_mbx.get(token);
      gen2scb_mbx.put(txn);
      scb2gen_mbx.get(token);

      // 4. Out of Bounds Address (Triggers SLVERR)
      txn = new();
      txn.AWADDR = 16'd4096;  // Exceeds 4092 limit
      txn.AWLEN = 8'd0;
      txn.AWSIZE = 3'd2;
      txn.display_transaction("DIR_OUT_OF_BOUNDS");
      gen2drv_mbx.put(txn);
      drv2gen_mbx.get(token);
      gen2scb_mbx.put(txn);
      scb2gen_mbx.get(token);

      // 5. Illegal 4KB Boundary Crossing (Triggers SLVERR)
      // 2 beats * 4 bytes = 8 bytes. 4092 + 8 = 4100 (Crosses boundary).
      txn = new();
      txn.AWADDR = 16'd4092;
      txn.AWLEN = 8'd1;
      txn.AWSIZE = 3'd2;
      txn.display_transaction("DIR_ILLEGAL_CROSS");
      gen2drv_mbx.put(txn);
      drv2gen_mbx.get(token);
      gen2scb_mbx.put(txn);
      scb2gen_mbx.get(token);

      // 6. Write and Read Same Address (Data Integrity Check)
      txn = new();
      txn.AWADDR = 16'h0100;
      txn.AWLEN = 8'd3;
      txn.AWSIZE = 3'd2;
      txn.WDATA = 32'hAABBCCDD;
      txn.ARADDR = 16'h0100;
      txn.ARLEN = 8'd3;
      txn.ARSIZE = 3'd2;
      txn.display_transaction("DIR_WRITE_READ_CHECK");
      gen2drv_mbx.put(txn);
      drv2gen_mbx.get(token);
      gen2scb_mbx.put(txn);
      scb2gen_mbx.get(token);
      // =======================================================


      // ===== Randomize =======================================
      repeat (num_transactions) begin
        txn = new();
        assert (txn.randomize())
        else begin
          $display("RANDOMIZATION FAILED");
          $stop;
        end
        txn.display_transaction("GEN");

        // Hand-off to Driver
        gen2drv_mbx.put(txn);
        drv2gen_mbx.get(token);  // wait for driver done token

        // Hand-off to Scoreboard
        gen2scb_mbx.put(txn);
        scb2gen_mbx.get(token);  // wait for scoreboard sync token
      end
      // =======================================================

      $display("[%0t] Generator finished, %0d transactions sent", $time, num_transactions);
    endtask

  endclass
endpackage
