`ifndef RDMA_SUBSYSTEM_SEQ_P103_SV
`define RDMA_SUBSYSTEM_SEQ_P103_SV

class seq_p103 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p103)

  function new(string name = "seq_p103");
    super.new(name);
    set_case_id("P103");
  endfunction
endclass

`endif
