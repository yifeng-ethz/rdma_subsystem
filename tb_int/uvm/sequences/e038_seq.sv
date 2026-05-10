`ifndef RDMA_SUBSYSTEM_SEQ_E038_SV
`define RDMA_SUBSYSTEM_SEQ_E038_SV

class seq_e038 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e038)

  function new(string name = "seq_e038");
    super.new(name);
    set_case_id("E038");
  endfunction
endclass

`endif
