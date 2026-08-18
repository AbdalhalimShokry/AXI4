package AXI_scoreboard_pkg;

  import AXI_transaction_pkg::*;

  class AXI_scoreboard;

    // ==================================================
    // Configuration
    // ==================================================
    int unsigned num_transactions = 1000;

    // ==================================================
    // Reference Memory
    // ==================================================
    logic [31:0] reference_memory[0:1023];

    // ==================================================
    // Mailboxes
    // ==================================================
    mailbox #(AXI_transaction) mon2scb_mbx;
    mailbox #(int)             scb2mon_mbx;

    mailbox #(AXI_transaction) gen2scb_mbx;
    mailbox #(int)             scb2gen_mbx;

    int write_pass_count = 0;
    int write_fail_count = 0;

    int read_pass_count  = 0;
    int read_fail_count  = 0;

    // ==================================================
    // Constructor
    // ==================================================
    function new();
      foreach (reference_memory[i]) reference_memory[i] = '0;
    endfunction

    // ==================================================
    // Golden Model
    // ==================================================
    function void golden_model(AXI_transaction expected);
      bit valid_write;
      bit valid_read;

      // --- WRITE ---
      if (expected.AWVALID) begin
        valid_write = 1'b1;

        if ((expected.AWADDR % 4) != 0) valid_write = 1'b0;
        if (expected.AWADDR >= 4096) valid_write = 1'b0;
        if (expected.AWADDR + ((expected.AWLEN + 1) * 4) > 4096) valid_write = 1'b0;

        if (valid_write) begin
          for (int i = 0; i <= expected.AWLEN; i++) begin
            reference_memory[(expected.AWADDR>>2)+i] = expected.WDATA[i];
          end
          expected.BRESP = 2'b00;  // OKAY
        end else begin
          expected.BRESP = 2'b10;  // SLVERR
        end
      end

      // --- READ ---
      if (expected.ARVALID) begin
        valid_read = 1'b1;

        if ((expected.ARADDR % 4) != 0) valid_read = 1'b0;
        if (expected.ARADDR >= 4096) valid_read = 1'b0;
        if (expected.ARADDR + ((expected.ARLEN + 1) * 4) > 4096) valid_read = 1'b0;

        if (valid_read) begin
          for (int i = 0; i <= expected.ARLEN; i++) begin
            expected.RDATA = reference_memory[(expected.ARADDR>>2)+i];
          end
          expected.RRESP = 2'b00;  // OKAY
        end else begin
          expected.RRESP = 2'b10;  // SLVERR
        end
      end
    endfunction

    // ==================================================
    // Scoreboard Task
    // ==================================================
    task run_scoreboard();
      AXI_transaction expected;
      AXI_transaction actual;

      bit awaddr_match, awlen_match, wdata_match, bresp_match;
      bit araddr_match, arlen_match, rdata_match, rresp_match;
      int WDATA_count;

      // Total iterations = randomized transactions + 7 directed cases
      repeat (num_transactions + 7) begin
        // 1. Get transactions
        gen2scb_mbx.get(expected);
        golden_model(expected);
        mon2scb_mbx.get(actual);

        // 2. Write Comparison
        if (expected.AWVALID) begin
          awaddr_match = (expected.AWADDR == actual.AWADDR);
          awlen_match  = (expected.AWLEN == actual.AWLEN);
          bresp_match  = (expected.BRESP == actual.BRESP);

          WDATA_count  = 0;
          for (int i = 0; i <= expected.AWLEN; i++) begin
            if (expected.WDATA[i] == actual.WDATA[i]) WDATA_count++;
          end
          wdata_match = (WDATA_count == (expected.AWLEN + 1));

          if (awaddr_match && awlen_match && wdata_match && bresp_match) begin
            $display("[%0t] WRITE PASS: AWADDR = 0x%0h, AWLEN = %0d, BRESP = 0x%0h", $time,
                     expected.AWADDR, expected.AWLEN, expected.BRESP);
            write_pass_count++;
          end else begin
            $display(
                "[%0t] WRITE FAIL: AWADDR = 0x%0h, AWLEN = %0d, Expected BRESP = 0x%0h, Actual BRESP = 0x%0h",
                $time, expected.AWADDR, expected.AWLEN, expected.BRESP, actual.BRESP);
            write_fail_count++;
          end
        end

        // 3. Read Comparison
        if (expected.ARVALID) begin
          araddr_match = (expected.ARADDR == actual.ARADDR);
          arlen_match  = (expected.ARLEN == actual.ARLEN);
          rresp_match  = (expected.RRESP == actual.RRESP);
          rdata_match  = (expected.RDATA == actual.RDATA);

          if (araddr_match && arlen_match && rdata_match && rresp_match) begin
            $display("[%0t] READ PASS: ARADDR = 0x%0h, ARLEN = %0d, RRESP = 0x%0h", $time,
                     expected.ARADDR, expected.ARLEN, expected.RRESP);
            read_pass_count++;
          end else begin
            $display(
                "[%0t] READ FAIL: ARADDR = 0x%0h, ARLEN = %0d, Expected RRESP = 0x%0h, Actual RRESP = 0x%0h",
                $time, expected.ARADDR, expected.ARLEN, expected.RRESP, actual.RRESP);
            read_fail_count++;
          end
        end

        // 4. Synchronize with BOTH Monitor and Generator
        scb2mon_mbx.put(1);
        scb2gen_mbx.put(1);
      end

      $display("\n================ SCOREBOARD REPORT ================");
      $display("Total Transactions Checked : %0d", (num_transactions + 7));
      $display("Write Passes : %0d | Write Fails : %0d", write_pass_count, write_fail_count);
      $display("Read Passes  : %0d | Read Fails  : %0d", read_pass_count, read_fail_count);
      $display("===================================================\n");
    endtask

  endclass
endpackage