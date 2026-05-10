`ifndef RDMA_SUBSYSTEM_SEQ_X116_SV
`define RDMA_SUBSYSTEM_SEQ_X116_SV

class seq_x116 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_x116)

  function new(string name = "seq_x116");
    super.new(name);
    set_case_id("X116");
  endfunction
endclass

`endif
