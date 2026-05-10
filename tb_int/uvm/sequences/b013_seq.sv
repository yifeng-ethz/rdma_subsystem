`ifndef RDMA_SUBSYSTEM_SEQ_B013_SV
`define RDMA_SUBSYSTEM_SEQ_B013_SV

class seq_b013 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b013)

  function new(string name = "seq_b013");
    super.new(name);
    set_case_id("B013");
  endfunction
endclass

`endif
