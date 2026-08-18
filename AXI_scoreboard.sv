package AXI_scoreboard_pkg;

  import AXI_transaction_pkg::*;

  class AXI_scoreboard;

    int unsigned num_transactions = 1000;
    logic [31:0] reference_memory[0:1023];

    mailbox #(AXI_transaction) mon2scb_mbx;
    mailbox #(int)             scb2mon_mbx;

    mailbox #(AXI_transaction) gen2scb_mbx;
    mailbox #(int)             scb2gen_mbx;

    int write_pass_count = 0;
    int write_fail_count = 0;
    int read_pass_count  = 0;
    int read_fail_count  = 0;

    function new();
      foreach (reference_memory[i]) reference_memory[i] = '0;
    endfunction

    function void golden_model(AXI_transaction expected);
      bit valid_write;
      bit valid_read;
      logic [15:0] final_waddr, final_raddr;

      if (expected.AWVALID) begin
        valid_write = 1'b1;
        if ((expected.AWADDR % 4) != 0) valid_write = 1'b0;
        if (expected.AWADDR >= 4096) valid_write = 1'b0;
        
        final_waddr = expected.AWADDR + (expected.AWLEN * 4);
        if (((expected.AWADDR & 12'hFFF) + (expected.AWLEN * 4)) > 12'hFFF) valid_write = 1'b0;
        if (((final_waddr & 12'hFFF) + (expected.AWLEN * 4)) > 12'hFFF)     valid_write = 1'b0;
        if ((final_waddr >> 2) >= 1024)                                    valid_write = 1'b0;

        if (valid_write) begin
          for (int i = 0; i <= expected.AWLEN; i++) begin
            reference_memory[(expected.AWADDR >> 2) + i] = expected.WDATA[i];
          end
          expected.BRESP = 2'b00;
        end else begin
          expected.BRESP = 2'b10;
        end
      end

      if (expected.ARVALID) begin
        valid_read = 1'b1;
        if ((expected.ARADDR % 4) != 0) valid_read = 1'b0;
        if (expected.ARADDR >= 4096) valid_read = 1'b0;
        
        final_raddr = expected.ARADDR + (expected.ARLEN * 4);
        if (((expected.ARADDR & 12'hFFF) + (expected.ARLEN * 4)) > 12'hFFF) valid_read = 1'b0;
        if (((final_raddr & 12'hFFF) + (expected.ARLEN * 4)) > 12'hFFF)     valid_read = 1'b0;
        if ((final_raddr >> 2) >= 1024)                                    valid_read = 1'b0;

        if (valid_read) begin
          expected.RRESP = 2'b00;
        end else begin
          expected.RRESP = 2'b10;
        end
      end
    endfunction

    task run_scoreboard();
      AXI_transaction expected;
      AXI_transaction actual;

      bit awaddr_match, awlen_match, wdata_match, bresp_match;
      bit araddr_match, arlen_match, rresp_match;
      int WDATA_count;

      repeat (num_transactions + 10) begin
        gen2scb_mbx.get(expected);
        golden_model(expected);
        mon2scb_mbx.get(actual);

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
            $display("[%0t] WRITE PASS: AWADDR = 0x%0h, AWLEN = %0d, BRESP = 0x%0h", $time, expected.AWADDR, expected.AWLEN, expected.BRESP);
            write_pass_count++;
          end else begin
            $display("[%0t] WRITE FAIL: AWADDR = 0x%0h, AWLEN = %0d, Expected BRESP = 0x%0h, Actual BRESP = 0x%0h", $time, expected.AWADDR, expected.AWLEN, expected.BRESP, actual.BRESP);
            write_fail_count++;
          end
        end

        if (expected.ARVALID) begin
          araddr_match = (expected.ARADDR == actual.ARADDR);
          arlen_match  = (expected.ARLEN == actual.ARLEN);
          rresp_match  = (expected.RRESP == actual.RRESP);

          if (araddr_match && arlen_match && rresp_match) begin
            $display("[%0t] READ PASS: ARADDR = 0x%0h, ARLEN = %0d, RRESP = 0x%0h", $time, expected.ARADDR, expected.ARLEN, expected.RRESP);
            read_pass_count++;
          end else begin
            $display("[%0t] READ FAIL: ARADDR = 0x%0h, ARLEN = %0d, Expected RRESP = 0x%0h, Actual RRESP = 0x0h", $time, expected.ARADDR, expected.ARLEN, expected.RRESP, actual.RRESP);
            read_fail_count++;
          end
        end

        scb2mon_mbx.put(1);
        scb2gen_mbx.put(1);
      end

      $display("\n================ SCOREBOARD REPORT ================");
      $display("Total Transactions Tested : %0d", (num_transactions + 10));
      $display("Write Passes : %0d | Write Fails : %0d", write_pass_count, write_fail_count);
      $display("Read Passes  : %0d | Read Fails  : %0d", read_pass_count, read_fail_count);
      $display("===================================================\n");
    endtask

  endclass
endpackage