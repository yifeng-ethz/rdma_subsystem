`ifndef RDMA_SUBSYSTEM_SEQ_X076_SV
`define RDMA_SUBSYSTEM_SEQ_X076_SV

class seq_x076 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x076)

  function new(string name = "seq_x076");
    super.new(name);
    set_case_id("X076");
  endfunction
endclass

`endif
