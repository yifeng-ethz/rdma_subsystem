`ifndef RDMA_SUBSYSTEM_SEQ_B044_SV
`define RDMA_SUBSYSTEM_SEQ_B044_SV

class seq_b044 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_b044)

  function new(string name = "seq_b044");
    super.new(name);
    set_case_id("B044");
  endfunction
endclass

`endif
