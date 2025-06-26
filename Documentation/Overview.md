# Abstract

The recent explosion in AI creates an almost limitless demand for computing power.
AI workload is especially challenging since it is demanding in both computing power
and memory bandwidth.

In addition, AI deployed at the edge also demands very low power.

It is generally agreed in the computing community that the way forward is that we
need a special architecture for this kind of workload. This is formally known as
Domain-Specific-Architecture (DSA).

ztachip is one such DSA particularly optimized for vision and AI workload.

## Challenges

DSA also presents many challenges including

1. DSA is designed for a special set of applications in exchange for higher efficiencies.
However, we would like the DSA domain to be as diverse as possible while still benefiting
from a more efficient hardware implementation.

2. DSA implies both a special hardware and software architecture for a particular domain of applications. 
How can we present DSA concepts without requiring users to have cross-disciplined knowledge? 
It will be difficult to find software engineers that are also knowledgeable in hardware design.

The most common DSA used today is the Systolic-Array (SA). 
SA maps very well to many important math operations required in AI, namely
matrix multiplication, dot product, convolution...

![systolic](images/systolic.bmp)

However, SA is also very difficult to program. Users of SA often rely on prebuilt 
libraries provided by hardware vendors. Training/research AI workload that requires custom algorithm
implementation is therefore not suitable for SA.

SA is also not flexible enough to adapt to a wider range of applications. For example,
most ASICs with SA still require a powerful CPU and GPU to perform other 
tasks such as vision preprocessing. For many edge AI applications involving vision, 
the vision preprocessing steps are often just as computing intensive as the AI steps.

## DSA with ztachip

ztachip is an opensourse DSA architecture. It is a novel architecture as far as we
know.

The primary objective for ztachip is to provide DSA that covers a wide range of
applications and not just for AI. DSA programming with ztachip should also be intuitive
and simple.

ztachip targets applications that can be expressed as a sequence of tensor operations.
Tensor operations include data operation and computing operation. Data operations involving
tensors may also involve complex operations such as tensor transpose, tensor dimension resize,
data remapping, etc...

![ztachip_example](images/ztachip_app_example.bmp)

The reason for the above constraints is that we would like data plane operations to be
decoupled from computing operations. Tensor data operations are used to moved
data between external memory and internal memory. And tensor computing operations are performed
strictly from internal memory only. This strategy provides many advantages to the hardware
design including

- Memory transfer to/from external memory is streaming with prefetching and without round trip delay

- Tensor data operations specify exactly the data required for later execution. This
eliminates the need for caching.

- Computing operations are presented as tensor operators. This is an intuitive way
to specify algorithm parallelism. Many hardware threads can then be mapped to a large number
of parallel tasks. For example with vector addition, each element-wise addition can be mapped to a thread. 

- Tensor computing involves only with internal memory, greatly simplifying 
the hardware design since there is no memory stall cycles to contend with.

## What are provided with ztachip

ztachip provides the following DSA components:

- Hardware stack with all the RTL source codes that can be ported to different
FPGA and ASIC.

- A compiler to implement the necessary Domain Specific Language (DSL) to
hide the complexities from users. This means software engineers don't have to know
about the hardware aspects and the same software can then be ported to different
hardware with different capacities with just a recompilation

- Software stack is provided that implements many vision and AI algorithms. Native support
for TensorFlow without retraining is also provided.   

![dsa_component](images/dsa_component.bmp)

## Results

The 2 metrics of interest are domain coverage and performance.

### Domain converage

For domain coverage, ztachip's DSL has been proven on a wide range of applications
including many vision preprocessing and AI tasks. 

- Image classification with TensorFlow's Mobinet AI model.

- Object detection with TensorFlow's SSD-Mobinet AI model.

- Edge detection using Canny algorithm  

- Color space (RGB/YUYV) conversion

- Equalizer for contrast enhancement

- Guassian convolution for image blurring

- Harris Corder Detection algorithm, commonly used by robotic SLAM also.

- Optical flow algorithm to detect motion

- Image resizing

### Performance and power consumption

Performance is also very promising. Using the popular Mobinet-SSD AI model as a reference point,
ztachip achieves a performance of 10fps at a 20GOPS of hardware computing resource.

Compared with Nvidia Jetson Nano, it has a performance of 40fps but with a computing hardware resource at 500GOPS.

Therefore ztachip has a 6x better computing resource utilization than Nvidia in this case, resulting in much lower
power consumption.

Memory requirements for ztachip are also much lower due to the efficient use of memory.

## Future developments

ztachip current implementation operates on vector data types (8 x 8/12/16-bit).

The logical next step is for native support of matrix data types (8 x 8 x 8/12/16-bit).

ALU (Arithmetic Logical Units) sub-system is extended from a 8 unit wide vector of ALU units to a 8x8 matrix of ALU units. This will provide an 8x improvement in computing density when bus width is limited to 8 data elements. An improvement of 32x from current implementation is possible when bus width is extended to 16 data elements.

To provide an intuitive programming syntax to support matrix data types.


