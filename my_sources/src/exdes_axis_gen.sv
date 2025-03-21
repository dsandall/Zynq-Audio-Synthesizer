//-----------------------------------------------------------------------------
// (c) Copyright 2009 - 2023 Advanced Micro Devices, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Advanced Micro Devices, Inc. and is protected under U.S. and 
//  international copyright and other intellectual property
//  laws.
//  
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  AMD, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) AMD shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or AMD had been advised of the
//  possibility of the same.
//  
//  CRITICAL APPLICATIONS
//  AMD products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of AMD products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//  
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED ASx
//  PART OF THIS FILE AT ALL TIMES.


//tb
`timescale 1ns / 1ps (* DowngradeIPIdentifiedWarnings="yes" *)
module exdes_axis_gen (
    input clk,
    input resetn,

    input DataGen_Enable,
    input m_axis_audio_tready,
    output m_axis_audio_tvalid,
    output [2:0] m_axis_audio_tid,
    output [31:0] m_axis_audio_tdata
);

  logic signed [24 -1:0] DataGen_SampleValues[2* 1];
  logic [191:0] DataGen_ChannelStatus = {
    32'h01234567, 32'h89ABCDEF, 32'hAABBCCDD, 32'hEEFF0011, 32'h22334455, 32'h66778899
  };
  logic [31:0] DataGen_ChannelCounter;
  logic [31:0] DataGen_FrameCounter;
  logic [31:0] DataGen_AesOut;

  logic [3:0] cAES_BSYNC = 4'b0001;
  logic [3:0] cAES_SF1SYNC = 4'b0010;
  logic [3:0] cAES_SF2SYNC = 4'b0011;

  logic nAxis_TValid;
  logic nAxis_TReady;
  logic [2:0] nAxis_TID;
  logic [31:0] nAxis_TData;

  assign m_axis_audio_tvalid = nAxis_TValid;
  assign m_axis_audio_tid = nAxis_TID;
  assign m_axis_audio_tdata = nAxis_TData;
  assign nAxis_TReady = m_axis_audio_tready;

  always_ff @(posedge clk) begin
    //if reset is low, or DataGen is disabled,
    if (!resetn || !DataGen_Enable) begin
      nAxis_TValid <= 1'b0;
      DataGen_ChannelCounter = 0;
      DataGen_FrameCounter   = 0;
      foreach (DataGen_SampleValues[i]) begin
        DataGen_SampleValues[i] = 0;
      end
    end else begin
      // else continue operation
      if (!nAxis_TValid || (nAxis_TValid & nAxis_TReady)) begin
        nAxis_TValid <= 1'b1;

        nAxis_TID    <= DataGen_ChannelCounter;

        DataGen_AesOut[31] = 1'b0;
        DataGen_AesOut[30] = DataGen_ChannelStatus[DataGen_FrameCounter];
        DataGen_AesOut[29] = 1'b0;
        DataGen_AesOut[28] = 1'b0;
        DataGen_AesOut[27-:24] = DataGen_SampleValues[DataGen_ChannelCounter];
        nAxis_TData[31:4] <= DataGen_AesOut[31:4];

        if (DataGen_ChannelCounter[0] == 1'b0) begin
          if (DataGen_FrameCounter == 'd0) begin
            nAxis_TData[3:0] <= cAES_BSYNC;
          end else begin
            nAxis_TData[3:0] <= cAES_SF1SYNC;
          end
        end else begin
          nAxis_TData[3:0] <= cAES_SF2SYNC;
        end

        if (DataGen_ChannelCounter < (2 * 1) - 1) begin
          DataGen_ChannelCounter <= DataGen_ChannelCounter + 1'b1;
        end else begin
          DataGen_ChannelCounter <= 'd0;

          if (DataGen_FrameCounter < 'd191) begin
            DataGen_FrameCounter <= DataGen_FrameCounter + 1'b1;
          end else begin
            DataGen_FrameCounter <= 0;
          end

          foreach (DataGen_SampleValues[i]) begin
            if (DataGen_SampleValues[i] > -128) begin
              DataGen_SampleValues[i] = DataGen_SampleValues[i] - 1;
            end else begin
              DataGen_SampleValues[i] = 128;
            end
          end
        end
      end
    end
  end




endmodule
