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

        task ren_env();

        

    endclass
endpackage