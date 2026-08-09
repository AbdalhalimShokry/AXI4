package AXI_env_pkg;

  import AXI_transaction_pkg::*;
  import AXI_generator_pkg::*;
  import AXI_driver_pkg::*;
  import AXI_monitor_pkg::*;
  import AXI_scoreboard_pkg::*;

  class AXI_environment;

    // components
    AXI_generator gen;
    AXI_driver drv;
    AXI_monitor mon;
    AXI_scoreboard scb;

    // virtual interface
    virtual AXI_interface.TB_side vif;

    // mailboxes
    mailbox #(AXI_transaction) gen2drv_mbx;
    mailbox #(int) drv2gen_mbx;

    mailbox #(AXI_transaction) gen2scb_mbx;
    mailbox #(int) scb2gen_mbx;

    mailbox #(AXI_transaction) mon2scb_mbx;
    mailbox #(int) scb2mon_mbx;

    task run_env();
      // 1. Create mailboxes
      gen2drv_mbx = new(1);
      drv2gen_mbx = new(1);
      gen2scb_mbx = new(1);
      scb2gen_mbx = new(1);
      mon2scb_mbx = new(1);
      scb2mon_mbx = new(1);

      // 2. Create components
      gen = new();
      drv = new();
      mon = new();
      scb = new();

      // 3. Wire generator mailboxes
      gen.gen2drv_mbx = gen2drv_mbx;
      gen.drv2gen_mbx = drv2gen_mbx;
      gen.gen2scb_mbx = gen2scb_mbx;
      gen.scb2gen_mbx = scb2gen_mbx;

      // 4. Wire driver mailboxes
      drv.gen2drv_mbx = gen2drv_mbx;
      drv.drv2gen_mbx = drv2gen_mbx;

      // 5. Wire monitor mailboxes
      mon.mon2scb_mbx = mon2scb_mbx;
      mon.scb2mon_mbx = scb2mon_mbx;

      // 6. Wire scoreboard mailboxes
      scb.gen2scb_mbx = gen2scb_mbx;
      scb.scb2gen_mbx = scb2gen_mbx;
      scb.mon2scb_mbx = mon2scb_mbx;
      scb.scb2mon_mbx = scb2mon_mbx;

      // 7. Share Virtual Interface
      drv.vif = vif;
      mon.vif = vif;

      // 8. Fork all tasks concurrently
      fork
        gen.run_generator();
        drv.run_driver();
        mon.run_monitor();
        scb.run_scoreboard();
      join_any

      // Generator is done, wait one extra cycle then stop
      @(posedge vif.ACLK);
      @(posedge vif.ACLK);
      scb.report();
      $stop;
    endtask

  endclass
endpackage
