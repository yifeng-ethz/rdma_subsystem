`ifndef RDMA_SUBSYSTEM_SEQ_P121_SV
`define RDMA_SUBSYSTEM_SEQ_P121_SV

class seq_p121 extends rdma_subsystem_phase_b_case_seq;
  `uvm_object_utils(seq_p121)

  function new(string name = "seq_p121");
    super.new(name);
    set_case_id("P121");
  endfunction
endclass

`endif
