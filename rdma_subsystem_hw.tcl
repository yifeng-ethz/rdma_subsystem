package require -exact qsys 16.1

set VERSION_MAJOR_DEFAULT_CONST 26
set VERSION_MINOR_DEFAULT_CONST 1
set VERSION_PATCH_DEFAULT_CONST 0
set BUILD_DEFAULT_CONST         510
set VERSION_DATE_DEFAULT_CONST  20260510
set VERSION_GIT_DEFAULT_CONST   0x0b66a91b
set IP_UID_DEFAULT_CONST        0x44514f50
set INSTANCE_ID_DEFAULT_CONST   0
set VERSION_STRING_DEFAULT_CONST [format "%d.%d.%d.%04d" \
    $VERSION_MAJOR_DEFAULT_CONST \
    $VERSION_MINOR_DEFAULT_CONST \
    $VERSION_PATCH_DEFAULT_CONST \
    $BUILD_DEFAULT_CONST]

set DEFAULT_DMA_DATA_W_CONST  256
set DEFAULT_WQE_BUS_W_CONST   512
set DEFAULT_DEBUG_LEVEL_CONST 0

set_module_property NAME                         rdma_subsystem_top
set_module_property DISPLAY_NAME                 "RDMA Subsystem Supercore"
set_module_property VERSION                      $VERSION_STRING_DEFAULT_CONST
set_module_property DESCRIPTION                  "RDMA subsystem supercore Mu3e IP Core"
set_module_property GROUP                        "Mu3e Data Plane/RDMA"
set_module_property AUTHOR                       "Yifeng Wang"
set_module_property INTERNAL                     false
set_module_property OPAQUE_ADDRESS_MAP           true
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE                     true
set_module_property REPORT_TO_TALKBACK           false
set_module_property ALLOW_GREYBOX_GENERATION     false
set_module_property REPORT_HIERARCHY             false
set_module_property ELABORATION_CALLBACK         elaborate
set_module_property VALIDATION_CALLBACK          validate

proc add_html_text {group_name item_name html_text} {
    add_display_item $group_name $item_name TEXT ""
    set_display_item_property $item_name DISPLAY_HINT html
    set_display_item_property $item_name TEXT $html_text
}

proc add_common_interface_props {if_name} {
    set_interface_property $if_name associatedClock clk
    set_interface_property $if_name associatedReset reset_n
}

proc validate {} {
    set dma_data_w  [get_parameter_value DMA_DATA_W]
    set wqe_bus_w   [get_parameter_value WQE_BUS_W]
    set debug_level [get_parameter_value DEBUG_LEVEL]

    if {$dma_data_w != 256} {
        send_message error "DMA_DATA_W is fixed at 256 bits for Phase 1 A10 host-DMA signoff."
    }
    if {$wqe_bus_w != 512} {
        send_message error "WQE_BUS_W is fixed at 512 bits for one 64 B RQE/CQE cacheline beat."
    }
    if {$debug_level < 0 || $debug_level > 2} {
        send_message error "DEBUG_LEVEL must be 0, 1, or 2."
    }
}

proc add_subsystem_files {fileset_name} {
    add_fileset_file rdma_subsystem_pkg.sv SYSTEM_VERILOG PATH rtl/rdma_subsystem_pkg.sv
    add_fileset_file rdma_subsystem_reset_chain.sv SYSTEM_VERILOG PATH rtl/rdma_subsystem_reset_chain.sv
    add_fileset_file rdma_subsystem_axi_xbar.sv SYSTEM_VERILOG PATH rtl/rdma_subsystem_axi_xbar.sv
    add_fileset_file rdma_subsystem_csr_decoder.sv SYSTEM_VERILOG PATH rtl/rdma_subsystem_csr_decoder.sv
    add_fileset_file rdma_rq_ring_state.sv SYSTEM_VERILOG PATH ../rdma_rq_fetcher/rtl/rdma_rq_ring_state.sv
    add_fileset_file rdma_rq_axi_reader.sv SYSTEM_VERILOG PATH ../rdma_rq_fetcher/rtl/rdma_rq_axi_reader.sv
    add_fileset_file rdma_rq_fetcher.sv SYSTEM_VERILOG PATH ../rdma_rq_fetcher/rtl/rdma_rq_fetcher.sv
    add_fileset_file rdma_dma_packer.sv SYSTEM_VERILOG PATH ../rdma_dma_engine/rtl/rdma_dma_packer.sv
    add_fileset_file rdma_dma_data_fifo.sv SYSTEM_VERILOG PATH ../rdma_dma_engine/rtl/rdma_dma_data_fifo.sv
    add_fileset_file rdma_dma_writer.sv SYSTEM_VERILOG PATH ../rdma_dma_engine/rtl/rdma_dma_writer.sv
    add_fileset_file rdma_dma_engine.sv SYSTEM_VERILOG PATH ../rdma_dma_engine/rtl/rdma_dma_engine.sv
    add_fileset_file rdma_cq_ring_state.sv SYSTEM_VERILOG PATH ../rdma_cq_pusher/rtl/rdma_cq_ring_state.sv
    add_fileset_file rdma_cq_axi_writer.sv SYSTEM_VERILOG PATH ../rdma_cq_pusher/rtl/rdma_cq_axi_writer.sv
    add_fileset_file rdma_cq_msix.sv SYSTEM_VERILOG PATH ../rdma_cq_pusher/rtl/rdma_cq_msix.sv
    add_fileset_file rdma_cq_pusher.sv SYSTEM_VERILOG PATH ../rdma_cq_pusher/rtl/rdma_cq_pusher.sv
    add_fileset_file rdma_run_manager_csr.sv SYSTEM_VERILOG PATH ../rdma_run_manager/rtl/rdma_run_manager_csr.sv
    add_fileset_file rdma_run_manager_status.sv SYSTEM_VERILOG PATH ../rdma_run_manager/rtl/rdma_run_manager_status.sv
    add_fileset_file rdma_run_manager_fsm.sv SYSTEM_VERILOG PATH ../rdma_run_manager/rtl/rdma_run_manager_fsm.sv
    add_fileset_file rdma_run_manager.sv SYSTEM_VERILOG PATH ../rdma_run_manager/rtl/rdma_run_manager.sv
    add_fileset_file rdma_subsystem_top.sv SYSTEM_VERILOG PATH rtl/rdma_subsystem_top.sv TOP_LEVEL_FILE
}

add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL rdma_subsystem_top
add_subsystem_files QUARTUS_SYNTH

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL rdma_subsystem_top
add_subsystem_files SIM_VERILOG

add_fileset SIM_VHDL SIM_VHDL "" ""
set_fileset_property SIM_VHDL TOP_LEVEL rdma_subsystem_top
add_subsystem_files SIM_VHDL

add_parameter DMA_DATA_W NATURAL $DEFAULT_DMA_DATA_W_CONST
set_parameter_property DMA_DATA_W DISPLAY_NAME "DMA Data Width"
set_parameter_property DMA_DATA_W UNITS Bits
set_parameter_property DMA_DATA_W ALLOWED_RANGES {256}
set_parameter_property DMA_DATA_W HDL_PARAMETER true
set_parameter_property DMA_DATA_W DESCRIPTION "External host AXI4 data width. Phase 1 fixes this at 256 bits."

add_parameter WQE_BUS_W NATURAL $DEFAULT_WQE_BUS_W_CONST
set_parameter_property WQE_BUS_W DISPLAY_NAME "WQE Bus Width"
set_parameter_property WQE_BUS_W UNITS Bits
set_parameter_property WQE_BUS_W ALLOWED_RANGES {512}
set_parameter_property WQE_BUS_W HDL_PARAMETER true
set_parameter_property WQE_BUS_W DESCRIPTION "Internal RQE and CQE AXI4-Stream width. Phase 1 fixes this at one 64 B WQE per beat."

add_parameter DEBUG_LEVEL NATURAL $DEFAULT_DEBUG_LEVEL_CONST
set_parameter_property DEBUG_LEVEL DISPLAY_NAME "Debug Level"
set_parameter_property DEBUG_LEVEL UNITS None
set_parameter_property DEBUG_LEVEL ALLOWED_RANGES {0 1 2}
set_parameter_property DEBUG_LEVEL HDL_PARAMETER true
set_parameter_property DEBUG_LEVEL DESCRIPTION "Broadcast debug level. 0 is production, 1 exposes synthesizable taps, and 2 enables simulation-only lineage sidecars."

add_parameter IP_UID NATURAL $IP_UID_DEFAULT_CONST
set_parameter_property IP_UID DISPLAY_NAME "IP UID"
set_parameter_property IP_UID HDL_PARAMETER true
set_parameter_property IP_UID ENABLED true
set_parameter_property IP_UID DISPLAY_HINT hexadecimal

add_parameter VERSION_MAJOR NATURAL $VERSION_MAJOR_DEFAULT_CONST
set_parameter_property VERSION_MAJOR DISPLAY_NAME "Version Major"
set_parameter_property VERSION_MAJOR HDL_PARAMETER true
set_parameter_property VERSION_MAJOR ENABLED false

add_parameter VERSION_MINOR NATURAL $VERSION_MINOR_DEFAULT_CONST
set_parameter_property VERSION_MINOR DISPLAY_NAME "Version Minor"
set_parameter_property VERSION_MINOR HDL_PARAMETER true
set_parameter_property VERSION_MINOR ENABLED false

add_parameter VERSION_PATCH NATURAL $VERSION_PATCH_DEFAULT_CONST
set_parameter_property VERSION_PATCH DISPLAY_NAME "Version Patch"
set_parameter_property VERSION_PATCH HDL_PARAMETER true
set_parameter_property VERSION_PATCH ENABLED false

add_parameter BUILD NATURAL $BUILD_DEFAULT_CONST
set_parameter_property BUILD DISPLAY_NAME "Build"
set_parameter_property BUILD HDL_PARAMETER true
set_parameter_property BUILD ENABLED false

add_parameter VERSION_DATE NATURAL $VERSION_DATE_DEFAULT_CONST
set_parameter_property VERSION_DATE DISPLAY_NAME "Version Date"
set_parameter_property VERSION_DATE HDL_PARAMETER true
set_parameter_property VERSION_DATE ENABLED false

add_parameter VERSION_GIT NATURAL $VERSION_GIT_DEFAULT_CONST
set_parameter_property VERSION_GIT DISPLAY_NAME "Version Git"
set_parameter_property VERSION_GIT HDL_PARAMETER true
set_parameter_property VERSION_GIT ENABLED false
set_parameter_property VERSION_GIT DISPLAY_HINT hexadecimal

add_parameter INSTANCE_ID NATURAL $INSTANCE_ID_DEFAULT_CONST
set_parameter_property INSTANCE_ID DISPLAY_NAME "Instance ID"
set_parameter_property INSTANCE_ID HDL_PARAMETER true
set_parameter_property INSTANCE_ID ENABLED true

set TAB_CONFIGURATION "Configuration"
set TAB_IDENTITY      "Identity"
set TAB_INTERFACES    "Interfaces"
set TAB_REGMAP        "Register Map"

add_display_item "" $TAB_CONFIGURATION GROUP tab
add_display_item "" $TAB_IDENTITY      GROUP tab
add_display_item "" $TAB_INTERFACES    GROUP tab
add_display_item "" $TAB_REGMAP        GROUP tab

add_display_item $TAB_CONFIGURATION "Overview" GROUP
add_display_item $TAB_CONFIGURATION "Sizing" GROUP
add_display_item $TAB_CONFIGURATION "Debug" GROUP
add_display_item "Sizing" DMA_DATA_W parameter
add_display_item "Sizing" WQE_BUS_W parameter
add_display_item "Debug" DEBUG_LEVEL parameter
add_html_text "Overview" overview_html {<html><b>Role</b><br/>The RDMA subsystem supercore wires rdma_rq_fetcher, rdma_dma_engine, rdma_cq_pusher, and rdma_run_manager behind one BAR1 CSR slave and one host AXI4 master. Phase 1 keeps a single queue pair, a pure RTL AXI4 xbar, 512-bit RQ/CQ cacheline beats, and a 256-bit host DMA beat.</html>}

add_display_item $TAB_IDENTITY "Delivered Profile" GROUP
add_display_item "Delivered Profile" IP_UID parameter
add_display_item "Delivered Profile" VERSION_MAJOR parameter
add_display_item "Delivered Profile" VERSION_MINOR parameter
add_display_item "Delivered Profile" VERSION_PATCH parameter
add_display_item "Delivered Profile" BUILD parameter
add_display_item "Delivered Profile" VERSION_DATE parameter
add_display_item "Delivered Profile" VERSION_GIT parameter
add_display_item "Delivered Profile" INSTANCE_ID parameter
add_html_text "Delivered Profile" identity_html {<html><b>Packaged revision</b><br/>This component is delivered as version 26.1.0.0510.<br/><br/>The host-visible UID and META words are implemented by the embedded rdma_run_manager CSR aperture and use the same version parameters surfaced here. META page 0=VERSION, page 1=DATE, page 2=GIT, page 3=INSTANCE_ID.</html>}

add_display_item $TAB_INTERFACES "Clock / Reset" GROUP
add_display_item $TAB_INTERFACES "BAR1 CSR" GROUP
add_display_item $TAB_INTERFACES "OPQ Stream" GROUP
add_display_item $TAB_INTERFACES "Host AXI4" GROUP
add_display_item $TAB_INTERFACES "MSI-X" GROUP
add_html_text "Clock / Reset" clk_rst_html {<html>One clock input <b>clk</b> and active-low reset input <b>reset_n</b>. The wrapper generates per-block reset deassertion synchronizers.</html>}
add_html_text "BAR1 CSR" csr_html {<html>AXI4-Lite slave, 32-bit data, 8-bit byte address. The supercore decoder passes all traffic to rdma_run_manager, which owns the CSR map and SVD.</html>}
add_html_text "OPQ Stream" opq_html {<html>AXI4-Stream sink for OPQ egress. TDATA is 36 bits with {datak[3:0], data[31:0]}; TUSER[0] carries SOP and TLAST carries OPQ EOP. TREADY is asserted only when the active RQE rxbuffer has more than one maximum OPQ frame available and the PCIe posted-write path reports more than one maximum OPQ frame of credit.</html>}
add_html_text "Host AXI4" host_html {<html>Single AXI4 master toward host DRAM. Internal RQ/CQ 512-bit cacheline transactions are adapted to the 256-bit host data path by rdma_subsystem_axi_xbar.</html>}
add_html_text "MSI-X" msix_html {<html>Phase 1 exposes the MSI-X conduit but the embedded CQ pusher keeps msix_req low. Phase 2 replaces the quiet stub with real interrupt generation.</html>}

add_display_item $TAB_REGMAP "CSR Words" GROUP
add_html_text "CSR Words" regmap_html {<html><table border="1" cellpadding="3"><tr><th>Word</th><th>Name</th><th>Access</th><th>Description</th></tr><tr><td>0x00</td><td>UID</td><td>RO</td><td>ASCII DQOP from rdma_run_manager.</td></tr><tr><td>0x01</td><td>META</td><td>RW/RO</td><td>Page mux: page 0=VERSION, page 1=DATE, page 2=GIT, page 3=INSTANCE_ID.</td></tr><tr><td>0x02</td><td>CTRL</td><td>RW</td><td>enable, reset_counters W1P, halt.</td></tr><tr><td>0x03</td><td>STATUS</td><td>RO</td><td>Run-manager FSM and live worker handshake snapshot.</td></tr><tr><td>0x04..0x0C</td><td>RQ/CQ config and doorbells</td><td>RW/RO/WO</td><td>Host-side RQ/CQ ring bases, depths, tail/head doorbells, and CQ tail.</td></tr><tr><td>0x0D..0x12</td><td>CNT_*</td><td>RO</td><td>Sideband counter shadows from RQ fetcher, DMA engine, and CQ pusher.</td></tr></table><br/>Full field-level authority remains <b>../rdma_run_manager/rdma_run_manager.svd</b> and <b>../rdma_run_manager/doc/csr_map.md</b>.</html>}

proc elaborate {} {
    set dma_data_w [get_parameter_value DMA_DATA_W]

    add_interface clk clock sink
    set_interface_property clk ENABLED true
    add_interface_port clk clk clk Input 1

    add_interface reset_n reset sink
    set_interface_property reset_n associatedClock clk
    set_interface_property reset_n synchronousEdges DEASSERT
    set_interface_property reset_n ENABLED true
    add_interface_port reset_n reset_n reset_n Input 1

    add_interface csr axi4lite slave
    add_common_interface_props csr
    set_interface_property csr CMSIS_SVD_VARIABLES {SVD_FILE=../rdma_run_manager/rdma_run_manager.svd}
    set_interface_property csr SVD_ADDRESS_GROUP RDMA_SUBSYSTEM_CSR
    add_interface_port csr s_axil_awaddr awaddr Input 8
    add_interface_port csr s_axil_awvalid awvalid Input 1
    add_interface_port csr s_axil_awready awready Output 1
    add_interface_port csr s_axil_wdata wdata Input 32
    add_interface_port csr s_axil_wstrb wstrb Input 4
    add_interface_port csr s_axil_wvalid wvalid Input 1
    add_interface_port csr s_axil_wready wready Output 1
    add_interface_port csr s_axil_bresp bresp Output 2
    add_interface_port csr s_axil_bvalid bvalid Output 1
    add_interface_port csr s_axil_bready bready Input 1
    add_interface_port csr s_axil_araddr araddr Input 8
    add_interface_port csr s_axil_arvalid arvalid Input 1
    add_interface_port csr s_axil_arready arready Output 1
    add_interface_port csr s_axil_rdata rdata Output 32
    add_interface_port csr s_axil_rresp rresp Output 2
    add_interface_port csr s_axil_rvalid rvalid Output 1
    add_interface_port csr s_axil_rready rready Input 1

    add_interface opq_in axi4stream sink
    add_common_interface_props opq_in
    add_interface_port opq_in s_axis_opq_tdata tdata Input 36
    add_interface_port opq_in s_axis_opq_tvalid tvalid Input 1
    add_interface_port opq_in s_axis_opq_tready tready Output 1
    add_interface_port opq_in s_axis_opq_tlast tlast Input 1
    add_interface_port opq_in s_axis_opq_tuser tuser Input 2

    add_interface pcie_posted_write_credit conduit end
    add_common_interface_props pcie_posted_write_credit
    add_interface_port pcie_posted_write_credit pcie_posted_write_credit_valid credit_valid Input 1
    add_interface_port pcie_posted_write_credit pcie_posted_write_credit_words credit_words Input 32

    add_interface host_axi axi4 master
    add_common_interface_props host_axi
    add_interface_port host_axi m_axi_awid awid Output 4
    add_interface_port host_axi m_axi_awaddr awaddr Output 64
    add_interface_port host_axi m_axi_awlen awlen Output 8
    add_interface_port host_axi m_axi_awsize awsize Output 3
    add_interface_port host_axi m_axi_awburst awburst Output 2
    add_interface_port host_axi m_axi_awvalid awvalid Output 1
    add_interface_port host_axi m_axi_awready awready Input 1
    add_interface_port host_axi m_axi_wdata wdata Output $dma_data_w
    add_interface_port host_axi m_axi_wstrb wstrb Output [expr {$dma_data_w / 8}]
    add_interface_port host_axi m_axi_wlast wlast Output 1
    add_interface_port host_axi m_axi_wvalid wvalid Output 1
    add_interface_port host_axi m_axi_wready wready Input 1
    add_interface_port host_axi m_axi_bid bid Input 4
    add_interface_port host_axi m_axi_bresp bresp Input 2
    add_interface_port host_axi m_axi_bvalid bvalid Input 1
    add_interface_port host_axi m_axi_bready bready Output 1
    add_interface_port host_axi m_axi_arid arid Output 4
    add_interface_port host_axi m_axi_araddr araddr Output 64
    add_interface_port host_axi m_axi_arlen arlen Output 8
    add_interface_port host_axi m_axi_arsize arsize Output 3
    add_interface_port host_axi m_axi_arburst arburst Output 2
    add_interface_port host_axi m_axi_arvalid arvalid Output 1
    add_interface_port host_axi m_axi_arready arready Input 1
    add_interface_port host_axi m_axi_rid rid Input 4
    add_interface_port host_axi m_axi_rdata rdata Input $dma_data_w
    add_interface_port host_axi m_axi_rresp rresp Input 2
    add_interface_port host_axi m_axi_rlast rlast Input 1
    add_interface_port host_axi m_axi_rvalid rvalid Input 1
    add_interface_port host_axi m_axi_rready rready Output 1

    add_interface msix conduit start
    add_common_interface_props msix
    add_interface_port msix msix_req req Output 1
    add_interface_port msix msix_vector vector Output 5
    add_interface_port msix msix_ack ack Input 1
}
