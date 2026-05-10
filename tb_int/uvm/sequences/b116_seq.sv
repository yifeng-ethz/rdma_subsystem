`ifndef RDMA_SUBSYSTEM_SEQ_B116_SV
`define RDMA_SUBSYSTEM_SEQ_B116_SV

class seq_b116 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b116)

  function new(string name = "seq_b116");
    super.new(name);
    set_case_id("B116");
  endfunction
endclass

`endif
