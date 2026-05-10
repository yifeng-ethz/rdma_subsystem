`ifndef RDMA_SUBSYSTEM_ENV_SV
`define RDMA_SUBSYSTEM_ENV_SV

class subsystem_payload_monitor extends uvm_component;
  `uvm_component_utils(subsystem_payload_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class subsystem_lineage_monitor extends uvm_component;
  `uvm_component_utils(subsystem_lineage_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class rdma_subsystem_env extends uvm_env;
  `uvm_component_utils(rdma_subsystem_env)

  virtual rdma_subsystem_if vif;
  opq_source_cfg opq_cfg;
  host_axi_completer_cfg host_cfg;
  runtool_model_cfg runtool_cfg;
  opq_source_agent opq;
  host_axi_completer_agent host;
  runtool_model_agent runtool;
  subsystem_scoreboard scb;
  subsystem_coverage cov;
  subsystem_payload_monitor env_dbg1;
  subsystem_lineage_monitor env_dbg2;
  int unsigned debug_level;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    debug_level = 1;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual rdma_subsystem_if)::get(this, "", "vif", vif))
      `uvm_fatal("ENV", "Missing rdma_subsystem_if")
    void'($value$plusargs("DEBUG_LEVEL=%d", debug_level));

    opq_cfg = opq_source_cfg::type_id::create("opq_cfg");
    host_cfg = host_axi_completer_cfg::type_id::create("host_cfg");
    runtool_cfg = runtool_model_cfg::type_id::create("runtool_cfg");
    opq_cfg.vif = vif;
    host_cfg.vif = vif;
    runtool_cfg.vif = vif;
    runtool_cfg.mem = host_cfg.mem;

    uvm_config_db#(opq_source_cfg)::set(this, "opq", "cfg", opq_cfg);
    uvm_config_db#(host_axi_completer_cfg)::set(this, "host", "cfg", host_cfg);
    uvm_config_db#(runtool_model_cfg)::set(this, "runtool", "cfg", runtool_cfg);

    opq = opq_source_agent::type_id::create("opq", this);
    host = host_axi_completer_agent::type_id::create("host", this);
    runtool = runtool_model_agent::type_id::create("runtool", this);
    scb = subsystem_scoreboard::type_id::create("scb", this);
    cov = subsystem_coverage::type_id::create("cov", this);
    env_dbg1 = subsystem_payload_monitor::type_id::create("env_dbg1", this);
    env_dbg2 = subsystem_lineage_monitor::type_id::create("env_dbg2", this);
    runtool_cfg.opq = opq;
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    opq.word_ap.connect(scb.opq_imp);
    host.write_ap.connect(scb.host_write_imp);
    runtool.cqe_ap.connect(scb.cqe_imp);
    runtool.state_ap.connect(scb.state_imp);
  endfunction

  function void configure_case(subsystem_case_cfg cfg,
                               string scorecard_path);
    host_cfg.mem.clear();
    host_cfg.awready_lag = cfg.aw_lag;
    host_cfg.wready_lag = cfg.w_lag;
    host_cfg.bvalid_lag = cfg.b_lag;
    host_cfg.arready_lag = cfg.ar_lag;
    host_cfg.rvalid_lag = cfg.r_lag;
    host_cfg.next_bresp.delete();
    host_cfg.next_rresp.delete();
    if (cfg.inject_bresp_error)
      host_cfg.push_bresp(2'b10);
    if (cfg.inject_rresp_error)
      host_cfg.push_rresp(2'b10);
    scb.configure(host_cfg.mem, cfg, scorecard_path, debug_level);
    cov.sample_case(cfg, debug_level);
  endfunction

  function void sample_state(runtool_state_e state);
    cov.sample_state(state);
  endfunction
endclass

`endif
