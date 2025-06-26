//---------------------------------------------------------------------------
// Copyright [2014] [Ztachip Technologies Inc]
//
// Author: Vuong Nguyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except IN compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to IN writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//----------------------------------------------------------------------------
//
// This is the reference design to show how to build a SOC with ztachip as 
// accelerator for vision/AI workload
//
//  +-----------+
//  +           + AXI-MM     +--------------+
//  +           +----------->+  DDR         +--> DDR3 Bus
//  +           +            +  Controller  +
//  +           +            +--------------+
//  +           +
//  + soc_base  + AXI-Stream +--------------+
//  +           +------------+     VGA      +--> VGA signals
//  +           +            +--------------+
//  +           +
//  +           + AXI-Stream +--------------+
//  +           +------------+    Camera    +--> OV7670 I2C/Signals               
//  +           +            +--------------+
//  +-----------+
//

//--------------------------------------------------------------------------
//                  TOP COMPONENT DECLARATION
//                  SIGNAL/PIN ASSIGNMENTS
//--------------------------------------------------------------------------
                              
module main(
     
   // Reference clock/external reset
   
   input          sys_resetn,
   input CLK_125_P,   // G21
   input CLK_125_N,   // F21
   input SI570_P,   // AL8
   input SI570_N,   // AL7
   //  DDR signals 
   
   output [16:0]  c0_ddr4_adr,
   output [2:0]   c0_ddr4_ba,
   output         c0_ddr4_cas_n,  // Not used in DDR4, act_n instead
   output [0:0]   c0_ddr4_ck_c,
   output [0:0]   c0_ddr4_ck_t,
   output [0:0]   c0_ddr4_cke,
   output [0:0]   c0_ddr4_cs_n,
   inout  [1:0]   c0_ddr4_dm_dbi_n,
   inout  [15:0]  c0_ddr4_dq,
   inout  [1:0]   c0_ddr4_dqs_c,
   inout  [1:0]   c0_ddr4_dqs_t,
   output [0:0]   c0_ddr4_odt,
   output         c0_ddr4_act_n,
   output         c0_ddr4_reset_n,
   output         c0_ddr4_we_n,   // Not used in DDR4, act_n instead
   output [0:0]   c0_ddr4_bg,
   
   // UART signals
   
   output         UART_TXD,
   input          UART_RXD,
   
   // GPIO signals
   
   output [3:0]   led,
   input [3:0]    pushbutton,
   
   // VGA signals
   
   output         VGA_HS_O,
   output         VGA_VS_O,
   output [3:0]   VGA_R,
   output [3:0]   VGA_B,
   output [3:0]   VGA_G,
   
   // CAMERA signals

   output         CAMERA_SCL,
   input          CAMERA_VS,
   input          CAMERA_PCLK,
   input [7:0]    CAMERA_D,
   output         CAMERA_RESET,
   inout          CAMERA_SDR,
   input          CAMERA_RS,
   output         CAMERA_MCLK,
   output         CAMERA_PWDN,   
   
   input c0_sys_clk_i

   
   );
   wire               sys_clock;
   wire               SDRAM_clk;
   wire [31:0]        SDRAM_araddr;
   wire [1:0]         SDRAM_arburst;
   wire [7:0]         SDRAM_arlen;
   wire               SDRAM_arready;
   wire [2:0]         SDRAM_arsize;
   wire               SDRAM_arvalid;
   wire [31:0]        SDRAM_awaddr;
   wire [1:0]         SDRAM_awburst;
   wire [7:0]         SDRAM_awlen;
   wire               SDRAM_awready;
   wire [2:0]         SDRAM_awsize;
   wire               SDRAM_awvalid;
   wire               SDRAM_bready;
   wire [1:0]         SDRAM_bresp;
   wire               SDRAM_bvalid;
   wire               SDRAM_rlast;
   wire               SDRAM_rready;
   wire [1:0]         SDRAM_rresp;
   wire               SDRAM_rvalid;
   wire               SDRAM_wlast;
   wire               SDRAM_wready;
   wire               SDRAM_wvalid;

   wire [64-1:0] SDRAM_rdata;
   wire [64-1:0] SDRAM_wdata;
   wire [64/8-1:0] SDRAM_wstrb;
      
   wire [31:0]        VIDEO_tdata;
   wire               VIDEO_tlast;
   wire               VIDEO_tready;
   wire               VIDEO_tvalid;

   wire [31:0]        camera_tdata;
   wire               camera_tlast;
   wire               camera_tready;
   wire [0:0]         camera_tuser;
   wire               camera_tvalid;

   wire [19:0]        APB_PADDR;
   wire               APB_PENABLE;
   wire               APB_PREADY;
   wire               APB_PWRITE;
   wire [31:0]        APB_PWDATA;
   wire [31:0]        APB_PRDATA;
   wire               APB_PSLVERROR;
   

IBUFDS #(
  .DIFF_TERM("TRUE"),
  .IBUF_LOW_PWR("FALSE")
) clk125_ibufds (
  .I(CLK_125_P),
  .IB(CLK_125_N),
  .O(sys_clock)
);

   soc_base soc_base_inst (
      .clk_main(clk_main),
      .clk_x2_main(clk_x2_main),
      .clk_camera(clk_camera),
      .clk_vga(clk_vga),
      .clk_reset(1), // Dont need reset for FPGA design. Register already initialized after programming.  

      .SDRAM_clk(SDRAM_clk),
      .SDRAM_reset(1), // Dont need reset for FPGA design. Register already intialized after programming. 
      .SDRAM_araddr(SDRAM_araddr),
      .SDRAM_arburst(SDRAM_arburst),
      .SDRAM_arlen(SDRAM_arlen),
      .SDRAM_arready(SDRAM_arready),
      .SDRAM_arsize(SDRAM_arsize),
      .SDRAM_arvalid(SDRAM_arvalid),
      .SDRAM_awaddr(SDRAM_awaddr),
      .SDRAM_awburst(SDRAM_awburst),
      .SDRAM_awlen(SDRAM_awlen),
      .SDRAM_awready(SDRAM_awready),
      .SDRAM_awsize(SDRAM_awsize),
      .SDRAM_awvalid(SDRAM_awvalid),
      .SDRAM_bready(SDRAM_bready),
      .SDRAM_bresp(SDRAM_bresp),
      .SDRAM_bvalid(SDRAM_bvalid),
      .SDRAM_rdata(SDRAM_rdata),
      .SDRAM_rlast(SDRAM_rlast),
      .SDRAM_rready(SDRAM_rready),
      .SDRAM_rresp(SDRAM_rresp),
      .SDRAM_rvalid(SDRAM_rvalid),
      .SDRAM_wdata(SDRAM_wdata),
      .SDRAM_wlast(SDRAM_wlast),
      .SDRAM_wready(SDRAM_wready),
      .SDRAM_wstrb(SDRAM_wstrb),
      .SDRAM_wvalid(SDRAM_wvalid),

      .APB_PADDR(APB_PADDR),
      .APB_PENABLE(APB_PENABLE),
      .APB_PREADY(APB_PREADY),
      .APB_PWRITE(APB_PWRITE),
      .APB_PWDATA(APB_PWDATA),
      .APB_PRDATA(APB_PRDATA),
      .APB_PSLVERROR(APB_PSLVERROR),

      .led(led),
      .pushbutton(pushbutton),

      .UART_TXD(UART_TXD),
      .UART_RXD(UART_RXD),

      .VGA_HS_O(VGA_HS_O),
      .VGA_VS_O(VGA_VS_O),
      .VGA_R(VGA_R),
      .VGA_B(VGA_B),
      .VGA_G(VGA_G),

      .CAMERA_SCL(CAMERA_SCL),
      .CAMERA_VS(CAMERA_VS),
      .CAMERA_PCLK(CAMERA_PCLK),
      .CAMERA_D(CAMERA_D),
      .CAMERA_RESET(CAMERA_RESET),
      .CAMERA_SDR(CAMERA_SDR),
      .CAMERA_RS(CAMERA_RS),
      .CAMERA_MCLK(CAMERA_MCLK),
      .CAMERA_PWDN(CAMERA_PWDN)
   );

   //---------------------------
   // DDR Memory controller
   //---------------------------

   ddr4_0 ddr4_inst (
   .c0_ddr4_adr         (c0_ddr4_adr),
   .c0_ddr4_ba          (c0_ddr4_ba),
   .c0_ddr4_cke         (c0_ddr4_cke),
   .c0_ddr4_cs_n        (c0_ddr4_cs_n),
   .c0_ddr4_dm_dbi_n    (c0_ddr4_dm_dbi_n),
   .c0_ddr4_odt         (c0_ddr4_odt),
   .c0_ddr4_dq          (c0_ddr4_dq),
   .c0_ddr4_dqs_c       (c0_ddr4_dqs_c),
   .c0_ddr4_dqs_t       (c0_ddr4_dqs_t),
   .c0_ddr4_reset_n     (c0_ddr4_reset_n),
   .c0_ddr4_act_n       (c0_ddr4_act_n),
   .c0_ddr4_ck_t        (c0_ddr4_ck_t),
   .c0_ddr4_ck_c        (c0_ddr4_ck_c),
   .c0_ddr4_bg          (c0_ddr4_bg),
      // Clocks and resets
   .c0_sys_clk_p        (SI570_P),
   .c0_sys_clk_n        (SI570_N),
   
   .c0_ddr4_aresetn (sys_resetn),
   .sys_rst             (sys_resetn),     //!!!!!!!


      // AXI interface to SoC
      .c0_ddr4_ui_clk          (SDRAM_clk),
      .c0_ddr4_ui_clk_sync_rst (),
      .c0_init_calib_complete (),

      .c0_ddr4_s_axi_awid      (4'd0),
      .c0_ddr4_s_axi_awaddr    (SDRAM_awaddr),
      .c0_ddr4_s_axi_awlen     (SDRAM_awlen),
      .c0_ddr4_s_axi_awsize    (SDRAM_awsize),
      .c0_ddr4_s_axi_awburst   (SDRAM_awburst),
      .c0_ddr4_s_axi_awlock    (1'b0),
      .c0_ddr4_s_axi_awcache   (4'd0),
      .c0_ddr4_s_axi_awprot    (3'd0),
      .c0_ddr4_s_axi_awqos     (4'd0),
      .c0_ddr4_s_axi_awvalid   (SDRAM_awvalid),
      .c0_ddr4_s_axi_awready   (SDRAM_awready),

      .c0_ddr4_s_axi_wdata     (SDRAM_wdata),
      .c0_ddr4_s_axi_wstrb     (SDRAM_wstrb),
      .c0_ddr4_s_axi_wlast     (SDRAM_wlast),
      .c0_ddr4_s_axi_wvalid    (SDRAM_wvalid),
      .c0_ddr4_s_axi_wready    (SDRAM_wready),

      .c0_ddr4_s_axi_bready    (SDRAM_bready),
      .c0_ddr4_s_axi_bid       (),
      .c0_ddr4_s_axi_bresp     (SDRAM_bresp),
      .c0_ddr4_s_axi_bvalid    (SDRAM_bvalid),

      .c0_ddr4_s_axi_arid      (4'd0),
      .c0_ddr4_s_axi_araddr    (SDRAM_araddr),
      .c0_ddr4_s_axi_arlen     (SDRAM_arlen),
      .c0_ddr4_s_axi_arsize    (SDRAM_arsize),
      .c0_ddr4_s_axi_arburst   (SDRAM_arburst),
      .c0_ddr4_s_axi_arlock    (1'b0),
      .c0_ddr4_s_axi_arcache   (4'd0),
      .c0_ddr4_s_axi_arprot    (3'd0),
      .c0_ddr4_s_axi_arqos     (4'd0),
      .c0_ddr4_s_axi_arvalid   (SDRAM_arvalid),
      .c0_ddr4_s_axi_arready   (SDRAM_arready),

      .c0_ddr4_s_axi_rready    (SDRAM_rready),
      .c0_ddr4_s_axi_rid       (),
      .c0_ddr4_s_axi_rdata     (SDRAM_rdata),
      .c0_ddr4_s_axi_rresp     (SDRAM_rresp),
      .c0_ddr4_s_axi_rlast     (SDRAM_rlast),
      .c0_ddr4_s_axi_rvalid    (SDRAM_rvalid)
   );


   // ------------------
   // Clock synthesizer
   // -------------------

   clk_wiz_0 clk_wiz_inst(
      .clk_out1(clk_vga),
      .clk_out2(clk_mig_ref),
      .clk_out3(clk_mig_sysclk),
      .clk_out4(clk_camera),
      .clk_out5(clk_main),
      .clk_out6(clk_x2_main),
      .resetn(sys_resetn),
      .locked(),
      .clk_in1(sys_clock));

endmodule
