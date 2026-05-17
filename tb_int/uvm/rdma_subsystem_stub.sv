`ifndef RDMA_SUBSYSTEM_STUB_SV
`define RDMA_SUBSYSTEM_STUB_SV

module rdma_subsystem_top #(
  parameter int unsigned DMA_DATA_W = 256,
  parameter int unsigned WQE_BUS_W = 512,
  parameter int unsigned DEBUG_LEVEL = 0
) (
  input  logic                       clk,
  input  logic                       reset_n,

  input  logic [35:0]                s_axis_opq_tdata,
  input  logic                       s_axis_opq_tvalid,
  output logic                       s_axis_opq_tready,
  input  logic                       s_axis_opq_tlast,
  input  logic [1:0]                 s_axis_opq_tuser,

  input  logic                       pcie_posted_write_credit_valid,
  input  logic [31:0]                pcie_posted_write_credit_words,

  input  logic [7:0]                 s_axil_awaddr,
  input  logic                       s_axil_awvalid,
  output logic                       s_axil_awready,
  input  logic [31:0]                s_axil_wdata,
  input  logic [3:0]                 s_axil_wstrb,
  input  logic                       s_axil_wvalid,
  output logic                       s_axil_wready,
  output logic [1:0]                 s_axil_bresp,
  output logic                       s_axil_bvalid,
  input  logic                       s_axil_bready,
  input  logic [7:0]                 s_axil_araddr,
  input  logic                       s_axil_arvalid,
  output logic                       s_axil_arready,
  output logic [31:0]                s_axil_rdata,
  output logic [1:0]                 s_axil_rresp,
  output logic                       s_axil_rvalid,
  input  logic                       s_axil_rready,

  output logic [3:0]                 m_axi_awid,
  output logic [63:0]                m_axi_awaddr,
  output logic [7:0]                 m_axi_awlen,
  output logic [2:0]                 m_axi_awsize,
  output logic [1:0]                 m_axi_awburst,
  output logic                       m_axi_awvalid,
  input  logic                       m_axi_awready,
  output logic [DMA_DATA_W-1:0]      m_axi_wdata,
  output logic [DMA_DATA_W/8-1:0]    m_axi_wstrb,
  output logic                       m_axi_wlast,
  output logic                       m_axi_wvalid,
  input  logic                       m_axi_wready,
  input  logic [3:0]                 m_axi_bid,
  input  logic [1:0]                 m_axi_bresp,
  input  logic                       m_axi_bvalid,
  output logic                       m_axi_bready,
  output logic [3:0]                 m_axi_arid,
  output logic [63:0]                m_axi_araddr,
  output logic [7:0]                 m_axi_arlen,
  output logic [2:0]                 m_axi_arsize,
  output logic [1:0]                 m_axi_arburst,
  output logic                       m_axi_arvalid,
  input  logic                       m_axi_arready,
  input  logic [3:0]                 m_axi_rid,
  input  logic [DMA_DATA_W-1:0]      m_axi_rdata,
  input  logic [1:0]                 m_axi_rresp,
  input  logic                       m_axi_rlast,
  input  logic                       m_axi_rvalid,
  output logic                       m_axi_rready,

  output logic                       msix_req,
  output logic [4:0]                 msix_vector,
  input  logic                       msix_ack
);
  localparam logic [31:0] UID_CONST = 32'h4451_4f50;

  typedef struct packed {
    logic [63:0] rq_base;
    logic [63:0] cq_base;
    logic [31:0] ctrl;
    logic [31:0] status;
    logic [15:0] rq_depth;
    logic [15:0] cq_depth;
    logic [15:0] rq_tail;
    logic [15:0] rq_head;
    logic [15:0] cq_tail;
    logic [15:0] cq_head;
    logic [31:0] cnt_rqe_consumed;
    logic [31:0] cnt_cqe_posted;
    logic [31:0] cnt_bytes_written;
    logic [31:0] cnt_opq_input_w;
    logic [31:0] cnt_halt;
    logic [31:0] cnt_eoe_observed;
    logic [63:0] retire_seq;
  } csr_state_t;

  csr_state_t csr;
  logic worker_busy;

  assign msix_req = 1'b0;
  assign msix_vector = 5'h0;

  function automatic logic [31:0] apply_wstrb(input logic [31:0] old_value,
                                              input logic [31:0] new_value,
                                              input logic [3:0] strb);
    logic [31:0] result;
    result = old_value;
    for (int i = 0; i < 4; i++) begin
      if (strb[i])
        result[i * 8 +: 8] = new_value[i * 8 +: 8];
    end
    return result;
  endfunction

  task automatic reset_axi_outputs();
    m_axi_awid <= '0;
    m_axi_awaddr <= '0;
    m_axi_awlen <= '0;
    m_axi_awsize <= 3'd5;
    m_axi_awburst <= 2'b01;
    m_axi_awvalid <= 1'b0;
    m_axi_wdata <= '0;
    m_axi_wstrb <= '0;
    m_axi_wlast <= 1'b0;
    m_axi_wvalid <= 1'b0;
    m_axi_bready <= 1'b0;
    m_axi_arid <= '0;
    m_axi_araddr <= '0;
    m_axi_arlen <= '0;
    m_axi_arsize <= 3'd5;
    m_axi_arburst <= 2'b01;
    m_axi_arvalid <= 1'b0;
    m_axi_rready <= 1'b0;
  endtask

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      csr <= '0;
      s_axil_awready <= 1'b0;
      s_axil_wready <= 1'b0;
      s_axil_bvalid <= 1'b0;
      s_axil_bresp <= 2'b00;
      s_axil_arready <= 1'b0;
      s_axil_rdata <= '0;
      s_axil_rresp <= 2'b00;
      s_axil_rvalid <= 1'b0;
    end else begin
      s_axil_awready <= !s_axil_bvalid;
      s_axil_wready <= !s_axil_bvalid;
      s_axil_arready <= !s_axil_rvalid;
      if (s_axil_awvalid && s_axil_wvalid && s_axil_awready && s_axil_wready) begin
        unique case (s_axil_awaddr)
          8'h08: begin
            csr.ctrl <= apply_wstrb(csr.ctrl, s_axil_wdata, s_axil_wstrb);
            if (s_axil_wdata[1]) begin
              csr.cnt_rqe_consumed <= '0;
              csr.cnt_cqe_posted <= '0;
              csr.cnt_bytes_written <= '0;
              csr.cnt_opq_input_w <= '0;
              csr.cnt_halt <= '0;
              csr.cnt_eoe_observed <= '0;
            end
          end
          8'h10: csr.rq_base[31:0] <= apply_wstrb(csr.rq_base[31:0], s_axil_wdata, s_axil_wstrb);
          8'h14: csr.rq_base[63:32] <= apply_wstrb(csr.rq_base[63:32], s_axil_wdata, s_axil_wstrb);
          8'h18: csr.rq_depth <= s_axil_wdata[15:0];
          8'h1c: csr.rq_tail <= s_axil_wdata[15:0];
          8'h20: csr.cq_base[31:0] <= apply_wstrb(csr.cq_base[31:0], s_axil_wdata, s_axil_wstrb);
          8'h24: csr.cq_base[63:32] <= apply_wstrb(csr.cq_base[63:32], s_axil_wdata, s_axil_wstrb);
          8'h28: csr.cq_depth <= s_axil_wdata[15:0];
          8'h30: csr.cq_head <= s_axil_wdata[15:0];
          default: begin end
        endcase
        s_axil_bvalid <= 1'b1;
        s_axil_bresp <= 2'b00;
      end else if (s_axil_bvalid && s_axil_bready) begin
        s_axil_bvalid <= 1'b0;
      end

      if (s_axil_arvalid && s_axil_arready) begin
        unique case (s_axil_araddr)
          8'h00: s_axil_rdata <= UID_CONST;
          8'h04: s_axil_rdata <= {24'h0, DEBUG_LEVEL[7:0]};
          8'h08: s_axil_rdata <= csr.ctrl;
          8'h0c: s_axil_rdata <= csr.status | {31'h0, worker_busy};
          8'h10: s_axil_rdata <= csr.rq_base[31:0];
          8'h14: s_axil_rdata <= csr.rq_base[63:32];
          8'h18: s_axil_rdata <= {16'h0, csr.rq_depth};
          8'h1c: s_axil_rdata <= {16'h0, csr.rq_tail};
          8'h20: s_axil_rdata <= csr.cq_base[31:0];
          8'h24: s_axil_rdata <= csr.cq_base[63:32];
          8'h28: s_axil_rdata <= {16'h0, csr.cq_depth};
          8'h2c: s_axil_rdata <= {16'h0, csr.cq_tail};
          8'h30: s_axil_rdata <= {16'h0, csr.cq_head};
          8'h34: s_axil_rdata <= csr.cnt_rqe_consumed;
          8'h38: s_axil_rdata <= csr.cnt_cqe_posted;
          8'h3c: s_axil_rdata <= csr.cnt_bytes_written;
          8'h40: s_axil_rdata <= csr.cnt_opq_input_w;
          8'h44: s_axil_rdata <= csr.cnt_halt;
          8'h48: s_axil_rdata <= csr.cnt_eoe_observed;
          default: s_axil_rdata <= 32'h0;
        endcase
        s_axil_rvalid <= 1'b1;
        s_axil_rresp <= 2'b00;
      end else if (s_axil_rvalid && s_axil_rready) begin
        s_axil_rvalid <= 1'b0;
      end
    end
  end

  task automatic axi_read_wqe(input logic [63:0] addr,
                              output logic [511:0] data,
                              output logic [1:0] resp);
    data = '0;
    resp = 2'b00;
    @(posedge clk);
    m_axi_arid <= 4'h1;
    m_axi_araddr <= addr;
    m_axi_arlen <= 8'd1;
    m_axi_arsize <= 3'd5;
    m_axi_arburst <= 2'b01;
    m_axi_arvalid <= 1'b1;
    while (reset_n && !m_axi_arready)
      @(posedge clk);
    @(posedge clk);
    m_axi_arvalid <= 1'b0;
    m_axi_rready <= 1'b1;
    for (int beat = 0; beat < 2; beat++) begin
      while (reset_n && !m_axi_rvalid)
        @(posedge clk);
      if (!reset_n)
        break;
      data[beat * 256 +: 256] = m_axi_rdata;
      resp |= m_axi_rresp;
      @(posedge clk);
    end
    m_axi_rready <= 1'b0;
  endtask

  task automatic axi_write_beat(input logic [63:0] addr,
                                input logic [255:0] data,
                                input logic [31:0] strb,
                                output logic [1:0] resp);
    resp = 2'b00;
    @(posedge clk);
    m_axi_awid <= 4'h2;
    m_axi_awaddr <= addr;
    m_axi_awlen <= 8'd0;
    m_axi_awsize <= 3'd5;
    m_axi_awburst <= 2'b01;
    m_axi_awvalid <= 1'b1;
    while (reset_n && !m_axi_awready)
      @(posedge clk);
    @(posedge clk);
    m_axi_awvalid <= 1'b0;
    m_axi_wdata <= data;
    m_axi_wstrb <= strb;
    m_axi_wlast <= 1'b1;
    m_axi_wvalid <= 1'b1;
    while (reset_n && !m_axi_wready)
      @(posedge clk);
    @(posedge clk);
    m_axi_wvalid <= 1'b0;
    m_axi_wlast <= 1'b0;
    m_axi_wstrb <= '0;
    m_axi_bready <= 1'b1;
    while (reset_n && !m_axi_bvalid)
      @(posedge clk);
    resp = m_axi_bresp;
    @(posedge clk);
    m_axi_bready <= 1'b0;
  endtask

  task automatic axi_write_wqe(input logic [63:0] addr,
                               input logic [511:0] data,
                               output logic [1:0] resp);
    logic [1:0] resp0;
    logic [1:0] resp1;
    axi_write_beat(addr, data[255:0], 32'hffff_ffff, resp0);
    axi_write_beat(addr + 64'd32, data[511:256], 32'hffff_ffff, resp1);
    resp = resp0 | resp1;
  endtask

  function automatic logic [511:0] make_cqe(input logic [15:0] rqe_id,
                                            input logic [63:0] bytes_total,
                                            input logic [31:0] seg0_bytes,
                                            input logic [31:0] seg1_bytes,
                                            input logic [15:0] status,
                                            input logic [63:0] event_count);
    logic [511:0] cqe;
    cqe = '0;
    cqe[63:0] = bytes_total;
    cqe[95:64] = seg0_bytes;
    cqe[127:96] = seg1_bytes;
    cqe[143:128] = status;
    cqe[159:144] = rqe_id;
    cqe[191:160] = 32'h0;
    cqe[255:192] = event_count;
    cqe[319:256] = csr.cnt_opq_input_w;
    cqe[383:320] = csr.cnt_opq_input_w + event_count;
    cqe[447:384] = 64'h0;
    cqe[511:448] = csr.retire_seq;
    return cqe;
  endfunction

  task automatic drain_one_rqe(input logic [511:0] rqe);
    logic [63:0] seg0_addr;
    logic [63:0] seg0_span;
    logic [63:0] seg1_addr;
    logic [63:0] seg1_span;
    logic [15:0] opcode;
    logic [15:0] rqe_id;
    logic [15:0] status;
    logic [63:0] write_addr;
    logic [63:0] bytes_total;
    logic [31:0] seg0_bytes;
    logic [31:0] seg1_bytes;
    logic [255:0] beat_data;
    logic [31:0] beat_strb;
    logic [1:0] resp;
    logic done;

    seg0_addr = rqe[63:0];
    seg0_span = rqe[127:64];
    seg1_addr = rqe[191:128];
    seg1_span = rqe[255:192];
    opcode = rqe[271:256];
    rqe_id = rqe[303:288];
    status = 16'h0;
    bytes_total = 64'h0;
    seg0_bytes = 32'h0;
    seg1_bytes = 32'h0;
    done = 1'b0;

    if ((opcode != 16'h0001) || (seg0_span == 64'h0) || (seg0_addr[11:0] != 12'h0)) begin
      status[5] = 1'b1;
    end else if (csr.ctrl[2]) begin
      status[2] = 1'b1;
      csr.cnt_halt <= csr.cnt_halt + 1;
    end else begin
      s_axis_opq_tready <= 1'b1;
      while (reset_n && !done) begin
        logic [31:0] opq_word;
        logic opq_last;
        while (reset_n && !s_axis_opq_tvalid)
          @(posedge clk);
        if (!reset_n)
          break;
        opq_word = s_axis_opq_tdata[31:0];
        opq_last = s_axis_opq_tlast;
        s_axis_opq_tready <= 1'b0;
        beat_data = '0;
        beat_strb = 32'h0000_000f;
        beat_data[31:0] = opq_word;
        write_addr = (bytes_total < seg0_span) ? (seg0_addr + bytes_total) :
                     (seg1_addr + (bytes_total - seg0_span));
        if (bytes_total < seg0_span)
          seg0_bytes += 4;
        else
          seg1_bytes += 4;
        axi_write_beat(write_addr, beat_data, beat_strb, resp);
        csr.cnt_opq_input_w <= csr.cnt_opq_input_w + 1;
        csr.cnt_bytes_written <= csr.cnt_bytes_written + 4;
        bytes_total += 4;
        if (opq_last) begin
          status[0] = 1'b1;
          csr.cnt_eoe_observed <= csr.cnt_eoe_observed + 1;
          done = 1'b1;
        end
        if (!done && (bytes_total >= (seg0_span + seg1_span))) begin
          status[1] = 1'b1;
          done = 1'b1;
        end
        if (!done)
          s_axis_opq_tready <= 1'b1;
        @(posedge clk);
      end
      s_axis_opq_tready <= 1'b0;
      if (seg1_bytes != 0)
        status[3] = 1'b1;
      if (seg1_bytes == 0)
        status[4] = 1'b1;
    end

    axi_write_wqe(csr.cq_base + (longint'(csr.cq_tail % csr.cq_depth) << 6),
                  make_cqe(rqe_id, bytes_total, seg0_bytes, seg1_bytes, status,
                           status[0] ? 64'd1 : 64'd0),
                  resp);
    csr.retire_seq <= csr.retire_seq + 1;
    csr.cq_tail <= csr.cq_tail + 1;
    csr.cnt_rqe_consumed <= csr.cnt_rqe_consumed + 1;
    csr.cnt_cqe_posted <= csr.cnt_cqe_posted + 1;
  endtask

  initial begin
    worker_busy = 1'b0;
    s_axis_opq_tready = 1'b0;
    reset_axi_outputs();
    forever begin
      while (reset_n !== 1'b1)
        @(posedge clk);
      if (csr.ctrl[0] && csr.rq_head != csr.rq_tail && !worker_busy) begin
        logic [511:0] rqe;
        logic [1:0] resp;
        worker_busy = 1'b1;
        axi_read_wqe(csr.rq_base + (longint'(csr.rq_head % csr.rq_depth) << 6), rqe, resp);
        csr.rq_head <= csr.rq_head + 1;
        drain_one_rqe(rqe);
        worker_busy = 1'b0;
      end else begin
        @(posedge clk);
      end
    end
  end
endmodule

`endif
