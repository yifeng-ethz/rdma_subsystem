`ifndef RDMA_SUBSYSTEM_SEQ_B043_SV
`define RDMA_SUBSYSTEM_SEQ_B043_SV

class seq_b043 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b043)

  function new(string name = "seq_b043");
    super.new(name);
    set_case_id("B043");
  endfunction
endclass

`endif
