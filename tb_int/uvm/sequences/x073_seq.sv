`ifndef RDMA_SUBSYSTEM_SEQ_X073_SV
`define RDMA_SUBSYSTEM_SEQ_X073_SV

class seq_x073 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x073)

  function new(string name = "seq_x073");
    super.new(name);
    set_case_id("X073");
  endfunction
endclass

`endif
