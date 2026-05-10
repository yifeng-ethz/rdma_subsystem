`ifndef RDMA_SUBSYSTEM_SEQ_P029_SV
`define RDMA_SUBSYSTEM_SEQ_P029_SV

class seq_p029 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p029)

  function new(string name = "seq_p029");
    super.new(name);
    set_case_id("P029");
  endfunction
endclass

`endif
