`ifndef RDMA_SUBSYSTEM_SEQ_E121_SV
`define RDMA_SUBSYSTEM_SEQ_E121_SV

class seq_e121 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e121)

  function new(string name = "seq_e121");
    super.new(name);
    set_case_id("E121");
  endfunction
endclass

`endif
