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

  virtual function rdma_subsystem_phase_b_case_seq create_case_sequence(string selected_case_id);
    rdma_subsystem_phase_b_case_seq seq;
    seq = rdma_subsystem_phase_b_case_seq::type_id::create("seq_generic");
    seq.set_case_id(selected_case_id);
    return seq;
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
    rdma_subsystem_phase_b_case_seq seq;
    cfg = make_case_cfg(case_id);
    seq = create_case_sequence(case_id);
    `uvm_info("CASE", $sformatf("Starting %s bucket=%s cov=%s",
                                seq.case_id(), cfg.bucket, cfg.coverage_bin), UVM_LOW)
    seq.drive(env, cfg, scorecard_path, observed);
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
