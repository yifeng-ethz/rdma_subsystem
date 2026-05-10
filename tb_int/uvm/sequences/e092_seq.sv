`ifndef RDMA_SUBSYSTEM_SEQ_E092_SV
`define RDMA_SUBSYSTEM_SEQ_E092_SV

class seq_e092 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e092)

  function new(string name = "seq_e092");
    super.new(name);
    set_case_id("E092");
  endfunction
endclass

`endif
