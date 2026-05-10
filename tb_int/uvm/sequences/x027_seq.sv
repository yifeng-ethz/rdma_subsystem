`ifndef RDMA_SUBSYSTEM_SEQ_X027_SV
`define RDMA_SUBSYSTEM_SEQ_X027_SV

class seq_x027 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x027)

  function new(string name = "seq_x027");
    super.new(name);
    set_case_id("X027");
  endfunction
endclass

`endif
