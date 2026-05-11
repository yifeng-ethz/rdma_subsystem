// File name: rdma_subsystem_reset_chain.sv
// Author  : Yifeng Wang (yifenwan@phys.ethz.ch)
// Version : 26.1.0
// Date    : 20260510
// Change  : add two-flop reset deassertion synchronizers per subsystem block

`default_nettype none

module rdma_subsystem_reset_chain (
    input  wire logic clk,
    input  wire logic reset_n,

    output logic      rq_fetcher_reset_n,
    output logic      dma_engine_reset_n,
    output logic      cq_pusher_reset_n,
    output logic      run_manager_reset_n,
    output logic      xbar_reset_n,
    output logic      csr_decoder_reset_n
);

    logic [1:0] rq_fetcher_sync;
    logic [1:0] dma_engine_sync;
    logic [1:0] cq_pusher_sync;
    logic [1:0] run_manager_sync;
    logic [1:0] xbar_sync;
    logic [1:0] csr_decoder_sync;

    always_ff @(posedge clk or negedge reset_n) begin : reset_synchronizers
        if (!reset_n) begin
            rq_fetcher_sync     <= 2'b00;
            dma_engine_sync     <= 2'b00;
            cq_pusher_sync      <= 2'b00;
            run_manager_sync    <= 2'b00;
            xbar_sync           <= 2'b00;
            csr_decoder_sync    <= 2'b00;
        end else begin
            rq_fetcher_sync     <= {rq_fetcher_sync[0], 1'b1};
            dma_engine_sync     <= {dma_engine_sync[0], 1'b1};
            cq_pusher_sync      <= {cq_pusher_sync[0], 1'b1};
            run_manager_sync    <= {run_manager_sync[0], 1'b1};
            xbar_sync           <= {xbar_sync[0], 1'b1};
            csr_decoder_sync    <= {csr_decoder_sync[0], 1'b1};
        end
    end

    assign rq_fetcher_reset_n  = rq_fetcher_sync[1];
    assign dma_engine_reset_n  = dma_engine_sync[1];
    assign cq_pusher_reset_n   = cq_pusher_sync[1];
    assign run_manager_reset_n = run_manager_sync[1];
    assign xbar_reset_n        = xbar_sync[1];
    assign csr_decoder_reset_n = csr_decoder_sync[1];

endmodule

`default_nettype wire
