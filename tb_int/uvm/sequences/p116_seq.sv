`ifndef RDMA_SUBSYSTEM_SEQ_P116_SV
`define RDMA_SUBSYSTEM_SEQ_P116_SV

class seq_p116 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p116)

  function new(string name = "seq_p116");
    super.new(name);
    set_case_id("P116");
  endfunction
endclass

`endif
