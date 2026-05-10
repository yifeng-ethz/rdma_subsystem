`ifndef RDMA_SUBSYSTEM_SEQ_E037_SV
`define RDMA_SUBSYSTEM_SEQ_E037_SV

class seq_e037 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_e037)

  function new(string name = "seq_e037");
    super.new(name);
    set_case_id("E037");
  endfunction
endclass

`endif
