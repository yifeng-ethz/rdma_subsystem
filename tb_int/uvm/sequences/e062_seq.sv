`ifndef RDMA_SUBSYSTEM_SEQ_E062_SV
`define RDMA_SUBSYSTEM_SEQ_E062_SV

class seq_e062 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e062)

  function new(string name = "seq_e062");
    super.new(name);
    set_case_id("E062");
  endfunction
endclass

`endif
