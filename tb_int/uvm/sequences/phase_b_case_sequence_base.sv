`ifndef RDMA_SUBSYSTEM_PHASE_B_CASE_SEQUENCE_BASE_SV
`define RDMA_SUBSYSTEM_PHASE_B_CASE_SEQUENCE_BASE_SV

class rdma_subsystem_phase_b_case_seq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(rdma_subsystem_phase_b_case_seq)

  local string m_case_id;

  function new(string name = "rdma_subsystem_phase_b_case_seq");
    super.new(name);
    m_case_id = "B001";
  endfunction

  function void set_case_id(string selected_case_id);
    m_case_id = selected_case_id;
  endfunction

  function string case_id();
    return m_case_id;
  endfunction

  virtual task drive(rdma_subsystem_env env,
                     subsystem_case_cfg cfg,
                     string scorecard_path,
                     output int unsigned observed);
    env.configure_case(cfg, scorecard_path);
    env.runtool.execute_case(cfg, observed);
  endtask
endclass

`endif
