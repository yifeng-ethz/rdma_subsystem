`ifndef RDMA_SUBSYSTEM_SEQ_X063_SV
`define RDMA_SUBSYSTEM_SEQ_X063_SV

class seq_x063 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x063)

  function new(string name = "seq_x063");
    super.new(name);
    set_case_id("X063");
  endfunction
endclass

`endif
