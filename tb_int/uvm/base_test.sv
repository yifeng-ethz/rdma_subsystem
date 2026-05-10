`ifndef RDMA_SUBSYSTEM_BASE_TEST_SV
`define RDMA_SUBSYSTEM_BASE_TEST_SV

class rdma_subsystem_base_test extends uvm_test;
  `uvm_component_utils(rdma_subsystem_base_test)

  rdma_subsystem_env env;
  virtual rdma_subsystem_if vif;
  string case_id;
  string scorecard_path;
  subsystem_case_cfg cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    case_id = "B001";
    scorecard_path = "";
  endfunction

  function string default_case_id();
    return "B001";
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = rdma_subsystem_env::type_id::create("env", this);
    if (!$value$plusargs("CASE_ID=%s", case_id))
      case_id = default_case_id();
    void'($value$plusargs("SCORECARD=%s", scorecard_path));
  endfunction

  task apply_reset();
    if (!uvm_config_db#(virtual rdma_subsystem_if)::get(this, "", "vif", vif))
      `uvm_fatal("BASE", "Missing rdma_subsystem_if")
    vif.reset_n <= 1'b0;
    vif.init_master_side();
    repeat (12) @(posedge vif.clk);
    vif.reset_n <= 1'b1;
    repeat (8) @(posedge vif.clk);
  endtask

  task run_case();
    int unsigned observed;
    cfg = make_case_cfg(case_id);
    env.configure_case(cfg, scorecard_path);
    `uvm_info("CASE", $sformatf("Starting %s bucket=%s cov=%s",
                                cfg.case_id, cfg.bucket, cfg.coverage_bin), UVM_LOW)
    env.runtool.execute_case(cfg, observed);
    repeat (20) @(posedge vif.clk);
    env.scb.final_check();
    env.scb.write_scorecard();
    `uvm_info("CASE", $sformatf("TEST_DONE PASS %s observed_txn=%0d",
                                cfg.case_id, observed), UVM_LOW)
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    apply_reset();
    run_case();
    phase.drop_objection(this);
  endtask
endclass

`endif
