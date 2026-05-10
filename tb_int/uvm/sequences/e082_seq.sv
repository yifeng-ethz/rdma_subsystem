`ifndef RDMA_SUBSYSTEM_SEQ_E082_SV
`define RDMA_SUBSYSTEM_SEQ_E082_SV

class seq_e082 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e082)

  function new(string name = "seq_e082");
    super.new(name);
    set_case_id("E082");
  endfunction
endclass

`endif
