package AXI_env_pkg;

  import AXI_transaction_pkg::*;
  import AXI_generator_pkg::*;
  import AXI_driver_pkg::*;
  import AXI_monitor_pkg::*;
  import AXI_scoreboard_pkg::*;

  class AXI_environment;

    AXI_generator              gen;
    AXI_driver                 drv;
    AXI_monitor                mon;
    AXI_scoreboard             scb;

    virtual AXI_interface.TB_side vif;

    mailbox #(AXI_transaction) gen2drv_mbx;
    mailbox #(int)             drv2gen_mbx;
    mailbox #(AXI_transaction) gen2scb_mbx;
    mailbox #(int)             scb2gen_mbx;
    mailbox #(AXI_transaction) mon2scb_mbx;
    mailbox #(int)             scb2mon_mbx;

    task run_env();
      gen2drv_mbx = new(1);
      drv2gen_mbx = new(1);
      gen2scb_mbx = new(1);
      scb2gen_mbx = new(1);
      mon2scb_mbx = new(1);
      scb2mon_mbx = new(1);

      gen = new();
      drv = new();
      mon = new();
      scb = new();

      // Dynamic transaction count linking
      scb.num_transactions = gen.num_transactions;

      gen.gen2drv_mbx = gen2drv_mbx;
      gen.drv2gen_mbx = drv2gen_mbx;
      gen.gen2scb_mbx = gen2scb_mbx;
      gen.scb2gen_mbx = scb2gen_mbx;

      drv.gen2drv_mbx = gen2drv_mbx;
      drv.drv2gen_mbx = drv2gen_mbx;

      mon.mon2scb_mbx = mon2scb_mbx;
      mon.scb2mon_mbx = scb2mon_mbx;

      scb.gen2scb_mbx = gen2scb_mbx;
      scb.scb2gen_mbx = scb2gen_mbx;
      scb.mon2scb_mbx = mon2scb_mbx;
      scb.scb2mon_mbx = scb2mon_mbx;

      gen.vif = vif;
      drv.vif = vif;
      mon.vif = vif;

      fork
        gen.run_generator();
        drv.run_driver();
        mon.run_monitor();
        scb.run_scoreboard();
      join_any

      disable fork;

      @(posedge vif.ACLK);
      @(posedge vif.ACLK);
      $stop;
    endtask

  endclass
endpackage