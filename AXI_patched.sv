module axi4 #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter MEMORY_DEPTH = 1024
)(
    input  wire                     ACLK,
    input  wire                     ARESETn,

    // Write address channel
    input  wire [ADDR_WIDTH-1:0]    AWADDR,
    input  wire [7:0]               AWLEN,
    input  wire [2:0]               AWSIZE,
    input  wire                     AWVALID,
    output reg                      AWREADY,

    // Write data channel
    input  wire [DATA_WIDTH-1:0]    WDATA,
    input  wire                     WVALID,
    input  wire                     WLAST,
    output reg                      WREADY,

    // Write response channel
    output reg [1:0]                BRESP,
    output reg                      BVALID,
    input  wire                     BREADY,

    // Read address channel
    input  wire [ADDR_WIDTH-1:0]    ARADDR,
    input  wire [7:0]               ARLEN,
    input  wire [2:0]               ARSIZE,
    input  wire                     ARVALID,
    output reg                      ARREADY,

    // Read data channel
    output reg [DATA_WIDTH-1:0]     RDATA,
    output reg [1:0]                RRESP,
    output reg                      RVALID,
    output reg                      RLAST,
    input  wire                     RREADY
);

    // Internal memory signals
    reg mem_en, mem_we;
    reg [$clog2(MEMORY_DEPTH)-1:0] mem_addr;
    reg [DATA_WIDTH-1:0] mem_wdata;
    wire [DATA_WIDTH-1:0] mem_rdata;

    // FSM states
    reg [2:0] write_state;
    localparam W_IDLE = 3'd0,
               W_DATA = 3'd1,
               W_RESP = 3'd2;

    reg [2:0] read_state;
    localparam R_IDLE = 3'd0,
               R_ADDR = 3'd1, 
               R_DATA = 3'd2;

    // Address and burst management
    reg [ADDR_WIDTH-1:0] write_addr, read_addr;
    reg [7:0] write_burst_cnt, read_burst_cnt;
    
    // Latched errors for burst compliance
    reg write_err_latched, read_err_latched;

    // Boundary and alignment validation logic (32-bit word enforced)
    wire w_aligned = (AWADDR[1:0] == 2'b00) && (AWSIZE == 3'b010);
    wire w_bound_cross = ((AWADDR & 12'hFFF) + ((AWLEN + 1) << AWSIZE)) > 13'h1000;
    wire w_valid_range = (AWADDR >> 2) < MEMORY_DEPTH;
    wire write_is_error = !w_aligned || w_bound_cross || !w_valid_range;

    wire r_aligned = (ARADDR[1:0] == 2'b00) && (ARSIZE == 3'b010);
    wire r_bound_cross = ((ARADDR & 12'hFFF) + ((ARLEN + 1) << ARSIZE)) > 13'h1000;
    wire r_valid_range = (ARADDR >> 2) < MEMORY_DEPTH;
    wire read_is_error = !r_aligned || r_bound_cross || !r_valid_range;

    // Memory instance
    axi4_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH($clog2(MEMORY_DEPTH)),
        .DEPTH(MEMORY_DEPTH)
    ) mem_inst (
        .clk(ACLK),
        .rst_n(ARESETn),
        .mem_en(mem_en),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata)
    );

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            // Reset AXI Outputs
            AWREADY <= 1'b1;
            WREADY  <= 1'b0;
            BVALID  <= 1'b0;
            BRESP   <= 2'b00;
            
            ARREADY <= 1'b1;
            RVALID  <= 1'b0;
            RRESP   <= 2'b00;
            RDATA   <= {DATA_WIDTH{1'b0}};
            RLAST   <= 1'b0;
            
            // Reset Internal Registers
            write_state <= W_IDLE;
            read_state  <= R_IDLE;
            mem_en    <= 1'b0;
            mem_we    <= 1'b0;
            mem_addr  <= 0;
            mem_wdata <= 0;
            
            write_addr <= 0;
            read_addr  <= 0;
            write_burst_cnt <= 0;
            read_burst_cnt  <= 0;
            write_err_latched <= 1'b0;
            read_err_latched  <= 1'b0;
            
        end else begin
            // Default memory isolation
            mem_en <= 1'b0;
            mem_we <= 1'b0;

            // --------------------------
            // Write Channel FSM
            // --------------------------
            case (write_state)
                W_IDLE: begin
                    AWREADY <= 1'b1;
                    WREADY  <= 1'b0;
                    BVALID  <= 1'b0;
                    
                    if (AWVALID && AWREADY) begin
                        write_addr <= AWADDR;
                        write_burst_cnt <= AWLEN;
                        write_err_latched <= write_is_error;
                        
                        AWREADY <= 1'b0;
                        write_state <= W_DATA;
                    end
                end
                
                W_DATA: begin
                    // Trigger WREADY only after WVALID is detected
                    if (WVALID && !WREADY) begin
                        WREADY <= 1'b1;
                    end 
                    else if (WVALID && WREADY) begin
                        WREADY <= 1'b0; 
                        
                        // Execute memory write if transaction is valid
                        if (!write_err_latched) begin
                            mem_en    <= 1'b1;
                            mem_we    <= 1'b1;
                            mem_addr  <= write_addr >> 2;
                            mem_wdata <= WDATA;
                        end
                        
                        // Burst tracking
                        if (WLAST || write_burst_cnt == 0) begin
                            write_state <= W_RESP;
                            BRESP  <= write_err_latched ? 2'b10 : 2'b00; 
                            BVALID <= 1'b1;
                        end else begin
                            write_addr <= write_addr + 4; 
                            write_burst_cnt <= write_burst_cnt - 1'b1;
                        end
                    end
                end
                
                W_RESP: begin
                    if (BREADY && BVALID) begin
                        BVALID <= 1'b0;
                        write_state <= W_IDLE;
                    end
                end
            endcase

            // --------------------------
            // Read Channel FSM
            // --------------------------
            case (read_state)
                R_IDLE: begin
                    ARREADY <= 1'b1;
                    RVALID  <= 1'b0;
                    RLAST   <= 1'b0;
                    
                    if (ARVALID && ARREADY) begin
                        read_addr <= ARADDR;
                        read_burst_cnt <= ARLEN;
                        read_err_latched <= read_is_error;
                        ARREADY <= 1'b0;
                        
                        if (!read_is_error) begin
                            mem_en   <= 1'b1;
                            mem_addr <= ARADDR >> 2;
                        end
                        read_state <= R_ADDR;
                    end
                end
                
                R_ADDR: begin
                    // 1-cycle pipeline wait for synchronous RAM data alignment
                    RVALID <= 1'b1;
                    RDATA  <= read_err_latched ? {DATA_WIDTH{1'b0}} : mem_rdata;
                    RRESP  <= read_err_latched ? 2'b10 : 2'b00;
                    RLAST  <= (read_burst_cnt == 0);
                    
                    read_state <= R_DATA;
                end
                
                R_DATA: begin
                    if (RREADY && RVALID) begin
                        RVALID <= 1'b0;
                        
                        if (read_burst_cnt > 0) begin
                            read_addr <= read_addr + 4;
                            read_burst_cnt <= read_burst_cnt - 1'b1;
                            
                            if (!read_err_latched) begin
                                mem_en   <= 1'b1;
                                mem_addr <= (read_addr + 4) >> 2;
                            end
                            read_state <= R_ADDR; 
                        end else begin
                            RLAST <= 1'b0;
                            read_state <= R_IDLE;
                        end
                    end
                end
            endcase
        end
    end

endmodule