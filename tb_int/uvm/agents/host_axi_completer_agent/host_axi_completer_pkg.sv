`ifndef HOST_AXI_COMPLETER_PKG_SV
`define HOST_AXI_COMPLETER_PKG_SV

package host_axi_completer_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef struct {
    bit [63:0] addr;
    bit [255:0] data;
    bit [31:0] strb;
    bit last;
  } host_axi_write_beat_t;

  class host_sparse_mem extends uvm_object;
    `uvm_object_utils(host_sparse_mem)

    byte unsigned mem[longint unsigned];

    function new(string name = "host_sparse_mem");
      super.new(name);
    endfunction

    function void clear();
      mem.delete();
    endfunction

    function void write_byte(input longint unsigned addr, input byte unsigned data);
      mem[addr] = data;
    endfunction

    function byte unsigned read_byte(input longint unsigned addr);
      if (mem.exists(addr))
        return mem[addr];
      return 8'h00;
    endfunction

    function void write_word64_le(input longint unsigned addr, input bit [63:0] data);
      for (int i = 0; i < 8; i++)
        write_byte(addr + i, data[i * 8 +: 8]);
    endfunction

    function bit [63:0] read_word64_le(input longint unsigned addr);
      bit [63:0] data;
      data = '0;
      for (int i = 0; i < 8; i++)
        data[i * 8 +: 8] = read_byte(addr + i);
      return data;
    endfunction

    function void write_beat256(input longint unsigned addr,
                                input bit [255:0] data,
                                input bit [31:0] strb);
      for (int i = 0; i < 32; i++) begin
        if (strb[i])
          write_byte(addr + i, data[i * 8 +: 8]);
      end
    endfunction

    function bit [255:0] read_beat256(input longint unsigned addr);
      bit [255:0] data;
      data = '0;
      for (int i = 0; i < 32; i++)
        data[i * 8 +: 8] = read_byte(addr + i);
      return data;
    endfunction

    function void write_wqe512(input longint unsigned addr, input bit [511:0] data);
      write_beat256(addr, data[255:0], 32'hffff_ffff);
      write_beat256(addr + 32, data[511:256], 32'hffff_ffff);
    endfunction

    function bit [511:0] read_wqe512(input longint unsigned addr);
      bit [511:0] data;
      data[255:0] = read_beat256(addr);
      data[511:256] = read_beat256(addr + 32);
      return data;
    endfunction
  endclass

  class host_axi_completer_cfg extends uvm_object;
    `uvm_object_utils(host_axi_completer_cfg)

    virtual rdma_subsystem_if vif;
    host_sparse_mem mem;
    int unsigned awready_lag;
    int unsigned wready_lag;
    int unsigned bvalid_lag;
    int unsigned arready_lag;
    int unsigned rvalid_lag;
    bit [1:0] next_bresp[$];
    bit [1:0] next_rresp[$];

    function new(string name = "host_axi_completer_cfg");
      super.new(name);
      mem = host_sparse_mem::type_id::create("mem");
      awready_lag = 0;
      wready_lag = 0;
      bvalid_lag = 0;
      arready_lag = 0;
      rvalid_lag = 0;
    endfunction

    function void push_bresp(input bit [1:0] resp);
      next_bresp.push_back(resp);
    endfunction

    function void push_rresp(input bit [1:0] resp);
      next_rresp.push_back(resp);
    endfunction

    function bit [1:0] pop_bresp();
      if (next_bresp.size() == 0)
        return 2'b00;
      return next_bresp.pop_front();
    endfunction

    function bit [1:0] pop_rresp();
      if (next_rresp.size() == 0)
        return 2'b00;
      return next_rresp.pop_front();
    endfunction
  endclass

  class host_axi_completer_driver extends uvm_component;
    `uvm_component_utils(host_axi_completer_driver)

    host_axi_completer_cfg cfg;
    uvm_analysis_port #(host_axi_write_beat_t) write_ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      write_ap = new("write_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(host_axi_completer_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal("HOSTCFG", "Missing host_axi_completer_cfg")
    endfunction

    task wait_reset_release();
      cfg.vif.init_completer_side();
      while (cfg.vif.reset_n !== 1'b1)
        @(posedge cfg.vif.clk);
    endtask

    task automatic lag(input int unsigned cycles);
      repeat (cycles) @(posedge cfg.vif.clk);
    endtask

    task handle_write_channel();
      bit [63:0] addr;
      bit [7:0] len;
      bit [2:0] size;
      bit [3:0] id;
      int unsigned beat_bytes;
      host_axi_write_beat_t item;
      forever begin
        wait_reset_release();
        while (cfg.vif.reset_n) begin
          cfg.vif.m_axi_awready <= 1'b0;
          cfg.vif.m_axi_wready <= 1'b0;
          while (cfg.vif.reset_n && !cfg.vif.m_axi_awvalid)
            @(posedge cfg.vif.clk);
          if (!cfg.vif.reset_n)
            break;
          lag(cfg.awready_lag);
          cfg.vif.m_axi_awready <= 1'b1;
          @(posedge cfg.vif.clk);
          addr = cfg.vif.m_axi_awaddr;
          len = cfg.vif.m_axi_awlen;
          size = cfg.vif.m_axi_awsize;
          id = cfg.vif.m_axi_awid;
          cfg.vif.m_axi_awready <= 1'b0;
          beat_bytes = 1 << size;
          for (int unsigned beat = 0; beat <= len; beat++) begin
            while (cfg.vif.reset_n && !cfg.vif.m_axi_wvalid)
              @(posedge cfg.vif.clk);
            if (!cfg.vif.reset_n)
              break;
            lag(cfg.wready_lag);
            cfg.vif.m_axi_wready <= 1'b1;
            @(posedge cfg.vif.clk);
            item.addr = addr + beat * beat_bytes;
            item.data = cfg.vif.m_axi_wdata;
            item.strb = cfg.vif.m_axi_wstrb;
            item.last = cfg.vif.m_axi_wlast;
            cfg.mem.write_beat256(item.addr, item.data, item.strb);
            write_ap.write(item);
            cfg.vif.m_axi_wready <= 1'b0;
          end
          lag(cfg.bvalid_lag);
          cfg.vif.m_axi_bid <= id;
          cfg.vif.m_axi_bresp <= cfg.pop_bresp();
          cfg.vif.m_axi_bvalid <= 1'b1;
          while (cfg.vif.reset_n && !cfg.vif.m_axi_bready)
            @(posedge cfg.vif.clk);
          @(posedge cfg.vif.clk);
          cfg.vif.m_axi_bvalid <= 1'b0;
        end
      end
    endtask

    task handle_read_channel();
      bit [63:0] addr;
      bit [7:0] len;
      bit [2:0] size;
      bit [3:0] id;
      bit [1:0] resp;
      int unsigned beat_bytes;
      forever begin
        wait_reset_release();
        while (cfg.vif.reset_n) begin
          cfg.vif.m_axi_arready <= 1'b0;
          while (cfg.vif.reset_n && !cfg.vif.m_axi_arvalid)
            @(posedge cfg.vif.clk);
          if (!cfg.vif.reset_n)
            break;
          lag(cfg.arready_lag);
          cfg.vif.m_axi_arready <= 1'b1;
          @(posedge cfg.vif.clk);
          addr = cfg.vif.m_axi_araddr;
          len = cfg.vif.m_axi_arlen;
          size = cfg.vif.m_axi_arsize;
          id = cfg.vif.m_axi_arid;
          resp = cfg.pop_rresp();
          cfg.vif.m_axi_arready <= 1'b0;
          beat_bytes = 1 << size;
          for (int unsigned beat = 0; beat <= len; beat++) begin
            lag(cfg.rvalid_lag);
            cfg.vif.m_axi_rid <= id;
            cfg.vif.m_axi_rdata <= cfg.mem.read_beat256(addr + beat * beat_bytes);
            cfg.vif.m_axi_rresp <= resp;
            cfg.vif.m_axi_rlast <= (beat == len);
            cfg.vif.m_axi_rvalid <= 1'b1;
            while (cfg.vif.reset_n && !cfg.vif.m_axi_rready)
              @(posedge cfg.vif.clk);
            @(posedge cfg.vif.clk);
            cfg.vif.m_axi_rvalid <= 1'b0;
            cfg.vif.m_axi_rlast <= 1'b0;
            if (!cfg.vif.reset_n)
              break;
          end
        end
      end
    endtask

    task run_phase(uvm_phase phase);
      fork
        handle_write_channel();
        handle_read_channel();
      join
    endtask
  endclass

  class host_axi_completer_agent extends uvm_component;
    `uvm_component_utils(host_axi_completer_agent)

    host_axi_completer_cfg cfg;
    host_axi_completer_driver driver;
    uvm_analysis_port #(host_axi_write_beat_t) write_ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      write_ap = new("write_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(host_axi_completer_cfg)::get(this, "", "cfg", cfg))
        `uvm_fatal("HOSTCFG", "Missing host_axi_completer_cfg")
      uvm_config_db#(host_axi_completer_cfg)::set(this, "driver", "cfg", cfg);
      driver = host_axi_completer_driver::type_id::create("driver", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      driver.write_ap.connect(write_ap);
    endfunction
  endclass
endpackage

`endif
