`ifndef RDMA_SUBSYSTEM_SEQ_E119_SV
`define RDMA_SUBSYSTEM_SEQ_E119_SV

class seq_e119 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e119)

  function new(string name = "seq_e119");
    super.new(name);
    set_case_id("E119");
  endfunction
endclass

`endif
