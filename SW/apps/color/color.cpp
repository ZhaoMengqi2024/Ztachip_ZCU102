//----------------------------------------------------------------------------
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
//------------------------------------------------------------------------------

#include <math.h>
#include <assert.h>
#include "../../base/types.h"
#include "../../base/tensor.h"
#include "../../base/graph.h"
#include "kernels/color.h"
#include "color.h"


// Do color space conversion and reshaping
// Change between RGB<->BGR<->MONO<->YUYV color space
// Reshape between interleave format and split format for color plane

GraphNodeColorAndReshape::GraphNodeColorAndReshape() {
   m_input=0;
   m_output=0;
   m_spu=0;
}

GraphNodeColorAndReshape::GraphNodeColorAndReshape(TENSOR *input,TENSOR *output,
                                                   TensorObjType _dstColorSpace,
                                                   TensorFormat _dstFormat,
                                                   int clip_x,int clip_y,
                                                   int clip_w,int clip_h,
                                                   int dst_x,int dst_y,
                                                   int dst_w,int dst_h) : GraphNode() {
   Create(input,output,_dstColorSpace,_dstFormat,clip_x,clip_y,clip_w,clip_h,dst_x,dst_y,dst_w,dst_h);
}

GraphNodeColorAndReshape::~GraphNodeColorAndReshape() {
   Cleanup();
}

ZtaStatus GraphNodeColorAndReshape::Create(TENSOR *input,TENSOR *output,
                                          TensorObjType _dstColorSpace,
                                          TensorFormat _dstFormat,
                                          int clip_x,int clip_y,
                                          int clip_w,int clip_h,
                                          int dst_x,int dst_y,
                                          int dst_w,int dst_h) {
   Cleanup();
   m_input=input;
   m_output=output;
   m_dstColorSpace=_dstColorSpace;
   m_dstFormat=_dstFormat;
   m_clip_x=clip_x;
   m_clip_y=clip_y;
   m_clip_w=clip_w;
   m_clip_h=clip_h;
   m_dst_x=dst_x;
   m_dst_y=dst_y;
   m_dst_w=dst_w;
   m_dst_h=dst_h;
   return ZtaStatusOk;
}

void GraphNodeColorAndReshape::Cleanup() {
   if(m_spu) {
      ztaFreeSharedMem(m_spu);
      m_spu=0;
   }
}

// Implement verify operation required by GraphNode base class

ZtaStatus GraphNodeColorAndReshape::Verify() {
   TensorObjType objType;

   m_srcColorSpace=m_input->GetObjType();
   if((*(m_input->GetDimension())).size() != 3)
      return ZtaStatusFail;
   m_src_w=(*(m_input->GetDimension()))[2];
   m_src_h=(*(m_input->GetDimension()))[1];
   m_nChannel=(*(m_input->GetDimension()))[0];
   if(m_srcColorSpace==TensorObjTypeYUYV) {
      if(m_nChannel != 1) {
         return ZtaStatusFail;
      }
      if(m_input->GetDataType() != TensorDataTypeUint16 && 
         m_input->GetDataType() != TensorDataTypeInt16) {
         return ZtaStatusFail;
      }
      if(m_dstColorSpace != TensorObjTypeRGB &&
         m_dstColorSpace != TensorObjTypeBGR) {
         return ZtaStatusFail;
      } 
      if(m_spu) 
         ztaFreeSharedMem(m_spu);
      m_spu=ztaBuildSpuBundle(1,SpuCallback,0,0,0);
   } else if(m_srcColorSpace==TensorObjTypeMonochromeSingleChannel) {
      // Monochrome with 1 channel
      if(m_nChannel != 1)
         return ZtaStatusFail;
      if(m_input->GetDataType() != TensorDataTypeUint8)
         return ZtaStatusFail;
      m_srcorder=kChannelColorMono;
      m_srcfmt=kChannelFmtSingle;
   } else if(m_srcColorSpace==TensorObjTypeRGB || m_srcColorSpace==TensorObjTypeBGR || m_srcColorSpace==TensorObjTypeMonochrome) {
      // Convert from RGB/BGR space
      if((*(m_input->GetDimension())).size() != 3)
         return ZtaStatusFail;
      if(m_input->GetDataType() != TensorDataTypeUint8)
         return ZtaStatusFail;
      if(m_nChannel != 3)
         return ZtaStatusFail;
      if(m_srcColorSpace==TensorObjTypeRGB)
         m_srcorder=kChannelColorRGB;
      else if(m_srcColorSpace==TensorObjTypeBGR)
         m_srcorder=kChannelColorBGR;
      else
         m_srcorder=kChannelColorMono;
      m_srcfmt=(m_input->GetFormat()==TensorFormatSplit)?kChannelFmtSplit:kChannelFmtInterleave;
   } else {
      assert(0);
      return ZtaStatusFail;
   }
   if(m_clip_w==0)
      m_clip_w=m_src_w;
   if(m_clip_h==0)
      m_clip_h=m_src_h;
   if(m_dst_w==0)
      m_dst_w=m_clip_w;
   if(m_dst_h==0)
      m_dst_h=m_clip_h;
   switch(m_dstColorSpace) {
      case TensorObjTypeRGB:
         m_dstorder=kChannelColorRGB;
         m_dstfmt=(m_dstFormat==TensorFormatSplit)?kChannelFmtSplit:kChannelFmtInterleave;
         objType=TensorObjTypeRGB;
         break;
      case TensorObjTypeBGR:
         m_dstorder=kChannelColorBGR;
         m_dstfmt=(m_dstFormat==TensorFormatSplit)?kChannelFmtSplit:kChannelFmtInterleave;
         objType=TensorObjTypeBGR;
         break;
      case TensorObjTypeYUYV:
         return ZtaStatusFail;
      case TensorObjTypeMonochrome:
         m_dstorder=kChannelColorMono;
         m_dstfmt=(m_dstFormat==TensorFormatSplit)?kChannelFmtSplit:kChannelFmtInterleave;
         objType=TensorObjTypeMonochrome;
         break;
      case TensorObjTypeMonochromeSingleChannel:
         m_dstorder=kChannelColorMono;
         m_dstfmt=kChannelFmtSingle;
         m_dstFormat=TensorFormatSplit;
         objType=TensorObjTypeMonochromeSingleChannel;
         break;
      default:
         assert(0);
   }
   if(m_dstColorSpace==TensorObjTypeMonochromeSingleChannel) {
      std::vector<int> dim={1,m_dst_h,m_dst_w};
      m_output->Create(TensorDataTypeUint8,m_dstFormat,objType,dim);
   } else {
      std::vector<int> dim={3,m_dst_h,m_dst_w};
      m_output->Create(TensorDataTypeUint8,m_dstFormat,objType,dim);
   }
   return ZtaStatusOk;
}

// Implement schedule function required by GraphNode base class

ZtaStatus GraphNodeColorAndReshape::Execute(int queue,int stepMode) {
   if(m_srcColorSpace==TensorObjTypeYUYV) {
      kernel_yuyv2rgb_exe(
         GetJobId(queue),
         (unsigned int)m_input->GetBuf(),
         (unsigned int)m_output->GetBuf(),
		 (unsigned int)ZTA_SHARED_MEM_VIRTUAL(m_spu),
         m_clip_w,
         m_clip_h,
         m_dstfmt,
         m_dstorder,
         m_src_w,
         m_src_h,
         m_clip_x,
         m_clip_y,
         m_dst_x,
         m_dst_y,
         m_dst_w,
         m_dst_h);
   } else {
      kernel_copy_exe(
          GetJobId(queue),
    	  (unsigned int)m_input->GetBuf(),
    	  (unsigned int)m_output->GetBuf(),
    	  m_clip_w,
    	  m_clip_h,
    	  m_srcfmt,
    	  m_srcorder,
    	  m_dstfmt,
    	  m_dstorder,
    	  m_src_w,
    	  m_src_h,
    	  m_clip_x,
    	  m_clip_y,
    	  m_dst_x,
    	  m_dst_y,
    	  m_dst_w,
    	  m_dst_h,
    	  0);
   }
   return ZtaStatusOk;
}

int16_t GraphNodeColorAndReshape::SpuCallback(int16_t input,void *pparm,uint32_t parm,uint32_t parm2)
{
   if(input < 0)
      return 0;
   else if(input > 255)
      return 255;
   else
      return input;
}
