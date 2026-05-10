`ifndef RDMA_SUBSYSTEM_SEQ_B072_SV
`define RDMA_SUBSYSTEM_SEQ_B072_SV

class seq_b072 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b072)

  function new(string name = "seq_b072");
    super.new(name);
    set_case_id("B072");
  endfunction
endclass

`endif
