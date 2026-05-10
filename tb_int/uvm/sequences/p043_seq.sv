`ifndef RDMA_SUBSYSTEM_SEQ_P043_SV
`define RDMA_SUBSYSTEM_SEQ_P043_SV

class seq_p043 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p043)

  function new(string name = "seq_p043");
    super.new(name);
    set_case_id("P043");
  endfunction
endclass

`endif
