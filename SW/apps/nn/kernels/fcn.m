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

#include <stdbool.h>
#include "../../../base/util.h"
#include "../../../base/ztalib.h"
#include "fcn.h"
#include "fcn.p.img"

extern void mycallback(int parm2);

typedef struct {
   uint32_t coef;
   uint32_t biasHi;
   uint32_t biasLo;   
   uint32_t bot;
   uint32_t top;
   int topcnt;
   int topdim;
   int botcnt;
   int botdim;
   int coeftopcnt;
   int coefbotcnt;
   int dx;
   int top_scale;
   int stream;
   int num_thread;
   int num_pcore;
} RequestFcn;

// Do fully connected layer...

static void innerProduct(void *_p,int pid) {
   RequestFcn *req=(RequestFcn *)_p;
   int index;
   int i,j;
   int npcore,nthread;
   int coeftopcnt;
   int dx2;
   int index2;
   int topfmt=UINT8;
   int botfmt=UINT8;
   int biasfmt=INT16;
   int weightfmt=UINT8;
   
   nthread=req->num_thread;
   coeftopcnt=req->coeftopcnt*IP_CHUNK_SIZE;
   dx2=req->dx*IP_CHUNK_SIZE;

   > DTYPE(INT16)PCORE(NUM_PCORE)[*][0:nthread-1].inner_product::init._out_scale <= INT16(req->top_scale);
   > EXE_LOCKSTEP(inner_product::init,NUM_PCORE,nthread);
   ztaTaskYield();
   for(i=(pid==0)?0:req->dx;i < req->topcnt;i += 2*req->dx) {
      index2=i*IP_CHUNK_SIZE;
      npcore=req->num_pcore;

      > DTYPE(biasfmt)PCORE(npcore)[:][0:nthread-1].inner_product::biasHi[:] <= DTYPE(biasfmt)MEM(req->biasHi,req->topcnt)[i:i+req->dx-1];
      > DTYPE(biasfmt)PCORE(npcore)[:][0:nthread-1].inner_product::biasLo[:] <= DTYPE(biasfmt)MEM(req->biasLo,req->topcnt)[i:i+req->dx-1];
      > EXE_LOCKSTEP(inner_product::start,npcore,nthread);
      ztaTaskYield();
   
      // Do innerproduct. This is a memory bound operation
         
      for(j=0,index=0;j < req->botcnt;j+=IP_CHUNK_SIZE,index++) {
         > FOR(I=0:req->num_pcore-1) FOR(J=0:nthread-1) FOR(K=0:IP_CHUNK_SIZE-1) FOR(L=0:VECTOR_WIDTH-1)    
         > REMAP(2) DTYPE(weightfmt)PCORE[I][J].inner_product::coef[K][L] <= DTYPE(weightfmt)MEM(req->coef,req->coefbotcnt,coeftopcnt)[index][index2:index2+dx2-1];
         > REMAP(1) DTYPE(botfmt) PCORE(npcore)[*].inner_product::bot[:] <= DTYPE(botfmt)MEM(req->bot,req->botcnt)[j:j+IP_CHUNK_SIZE-1];
         > EXE_LOCKSTEP(inner_product::exe,npcore,nthread);
         if((j+IP_CHUNK_SIZE) >= req->botcnt) {
            > EXE_LOCKSTEP(inner_product::activate_none,npcore,nthread);
            > DTYPE(topfmt)MEM(req->top,req->topcnt)[i:i+req->dx-1] <= REMAP(0) DTYPE(topfmt)PCORE(req->num_pcore)[:][0:nthread-1].inner_product::top[:];
         }
         ztaTaskYield();
      }
   }
}

typedef struct {
   int topcnt;
   int topdim;
   int botcnt;
   int botdim;
   int ksz;
   int stride;
   uint32_t top;
   uint32_t bot;
   int output_shift;
   uint32_t stream;
} RequestPool;

// Do pooling layer

static void pooling(void *_p,int pid) {
   RequestPool *req=(RequestPool *)_p;
   int i,j;
   int from,to;
   int np; 
   int fmt=UINT8;
   int botsz;
   int cnt,step,nt;

   np=NUM_PCORE;
   cnt=req->topcnt;
   botsz=req->botdim*req->botdim;
   step=NUM_THREAD_PER_CORE*VECTOR_WIDTH*np;
   
   if(pid==0) {
      from=0;
      to=cnt/2;
   } else {
      from=cnt/2;
      to=cnt;
   }
   > DTYPE(INT16)PCORE(np)[*][:].max_pool::init._out_scale <= INT16(req->output_shift);
   > EXE_LOCKSTEP(max_pool::init,np);
   ztaTaskYield();
 
   for(i=from;i < to;i+=step) {
      nt=NUM_THREAD_PER_CORE;

      for(j=0;j < botsz;j += POOL_BOT_SIZE) {
         >DTYPE(fmt) CONCURRENT FOR(I=0:np-1) FOR(J=0:nt-1) FOR(K=0:VECTOR_WIDTH-1) PCORE(np)[I].THREAD[J].max_pool::bot[:][K] <= 
         >DTYPE(fmt) MEM(req->bot,cnt,botsz)[i:i+VECTOR_WIDTH*np*nt-1][j:j+POOL_BOT_SIZE-1];
         >EXE_LOCKSTEP(max_pool::exe,np);
         ztaTaskYield();       
      }
      >EXE_LOCKSTEP(max_pool::finish,np);
      ztaTaskYield();
      
      // Output results...
        
      >DTYPE(fmt) MEM(req->top,cnt)[i:i+VECTOR_WIDTH*np*nt-1] <= REMAP(0) DTYPE(fmt) FOR(I=0:np-1) FOR(J=0:nt-1) PCORE(np)[I].THREAD[J].max_pool::top[:];
   }
}

// Do concantenation layer...
// Pretty straightforward, concatenate tensor data together

void kernel_concatenate_exe(
   unsigned int _req_id,
   int _cnt,
   unsigned int *_src,
   int *_copySize,
   unsigned int *_spu,
   unsigned int *_dest
) 
{
   int i,cnt,idx;
   uint32_t spu,src,dest;
   int copySize;
   int len,remain;
   int fmt=UINT8;

   ztaInitPcore(zta_pcore_img);

   cnt=_cnt;
   for(i=0;i < cnt;i++) {
      src=_src[i];
      copySize=_copySize[i];
      spu=_spu[i];
      dest=_dest[i];
      if(spu) {
         // Load stream processor code
         ztaInitStream(spu);
      }
      remain=copySize;
      idx=0;
      while(remain > 0) {
         len=remain;
         len=ROUND(len,VECTOR_WIDTH);
         if(len > CONCATENATE_BUFSZ)
            len=CONCATENATE_BUFSZ;
         >DTYPE(fmt)PCORE(NUM_PCORE)[0].concatenate::buf[0:len-1] <= DTYPE(fmt)MEM(src)[idx:idx+len-1];
         >BARRIER;
         if(spu) {
            >DTYPE(fmt)MEM(dest,copySize)[idx:idx+len-1] <= REMAP(0) DTYPE(fmt)PCORE(NUM_PCORE)[0].concatenate::buf[0:len-1];
         } else {
            >DTYPE(fmt)MEM(dest,copySize)[idx:idx+len-1] <= DTYPE(fmt)PCORE(NUM_PCORE)[0].concatenate::buf[0:len-1];
         }
         >BARRIER;
         idx += len;
         remain -= len;
      }
   }
   ztaJobDone(_req_id);
}

// Do logistic layer

void kernel_logistic_exe(
   unsigned int _req_id,
   int _copySize,
   unsigned int _src,
   unsigned int _dest,
   unsigned int _spu
) {
   int i,cnt,idx;
   uint32_t src,dest;
   int copySize;
   int len,remain;
   int fmt=UINT8;

   ztaInitPcore(zta_pcore_img);
   ztaInitStream(_spu);
   
   copySize=_copySize;
   src=_src;
   dest=_dest;

   remain=copySize;
   idx=0;
   while(remain > 0) {
      len=remain;
      len=ROUND(len,VECTOR_WIDTH);
      if(len > CONCATENATE_BUFSZ)
         len=CONCATENATE_BUFSZ;
      >REMAP(1) DTYPE(fmt)PCORE(NUM_PCORE)[0].concatenate::buf[0:len-1] <= DTYPE(fmt)MEM(src)[idx:idx+len-1];
      >BARRIER;
      >DTYPE(fmt)MEM(dest,copySize)[idx:idx+len-1] <= REMAP(0) DTYPE(fmt)PCORE(NUM_PCORE)[0].concatenate::buf[0:len-1];
      >BARRIER;
      idx += len;
      remain -= len;
   }
   ztaJobDone(_req_id);
}

// Process fully-connected layer request from host

void kernel_innerProduct_exe(
   unsigned int _req_id,
   unsigned int _coef,
   unsigned int _biasHi,
   unsigned int _biasLo,
   unsigned int _bot,
   unsigned int _top,
   int _topcnt,
   int _botcnt,
   int _coeftopcnt,
   int _coefbotcnt,
   unsigned int _stream,
   int _top_scale,
   int _num_pcore,
   int _num_thread
)
{
   RequestFcn req;

   ztaInitPcore(zta_pcore_img);
   ztaInitStream(_stream);

   req.coef=_coef;
   req.biasHi=_biasHi;
   req.biasLo=_biasLo;
   req.bot=_bot;
   req.top=_top;
   req.topcnt=_topcnt;
   req.botcnt=_botcnt;
   req.coeftopcnt=_coeftopcnt;
   req.coefbotcnt=_coefbotcnt;
   req.stream=_stream;
   req.top_scale=_top_scale;
   req.num_pcore=_num_pcore;
   req.num_thread=_num_thread;
   req.dx=req.num_pcore*req.num_thread*VECTOR_WIDTH;

   ztaDualHartExecute(innerProduct,&req);

   ztaJobDone(_req_id);
}

// Process pooling layer request from host

void kernel_Pooling_exe(
   unsigned int _req_id,
   unsigned int _bot,
   unsigned int _top,
   int _ksz,
   int _stride,
   int _topcnt,
   int _topdim,
   int _botcnt,
   int _botdim,
   unsigned int _stream,
   int _output_shift
)
{
   RequestPool req;

   ztaInitPcore(zta_pcore_img);
   ztaInitStream(_stream);

   req.bot=_bot;
   req.top=_top;
   req.ksz=_ksz;
   req.stride=_stride;
   req.topcnt=_topcnt;
   req.topdim=_topdim;
   req.botcnt=_botcnt;
   req.botdim=_botdim;
   req.stream=_stream;
   req.output_shift=_output_shift;

   ztaDualHartExecute(pooling,&req);

   ztaJobDone(_req_id);
}

