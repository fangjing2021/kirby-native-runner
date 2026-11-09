#pragma once
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

typedef NSUInteger MTLStages;
typedef uint64_t MTLGPUAddress;

@class MTL4CommandQueueDescriptor;
@class MTL4CommandAllocatorDescriptor;
@class MTL4ArgumentTableDescriptor;
@class MTL4LibraryDescriptor;
@class MTL4CommitOptions;
@class MTL4CounterHeapDescriptor;
@class MTL4LibraryFunctionDescriptor;
@class MTL4SpecializedFunctionDescriptor;
@class MTL4CompilerDescriptor;
@class MTL4PipelineDescriptor;
@class MTL4PipelineDataSetSerializerDescriptor;
@class MTL4Archive;

@protocol MTL4CommandEncoder <NSObject>
- (void)endEncoding;
- (void)barrierAfterStages:(NSUInteger)after beforeQueueStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis;
- (void)barrierAfterQueueStages:(NSUInteger)after beforeStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis;
- (void)barrierAfterEncoderStages:(NSUInteger)after beforeEncoderStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis;
- (void)setLabel:(NSString *)label;
@end

@protocol MTL4ArgumentTable <NSObject>
- (void)setAddress:(uint64_t)address atIndex:(NSUInteger)index;
- (void)setTexture:(MTLResourceID)texture atIndex:(NSUInteger)index;
- (void)setSamplerState:(MTLResourceID)sampler atIndex:(NSUInteger)index;
@end

@protocol MTL4ComputeCommandEncoder <MTLComputeCommandEncoder, MTL4CommandEncoder>
- (void)setArgumentTable:(id<MTL4ArgumentTable>)table;
- (void)dispatchThreadgroupsWithIndirectBuffer:(uint64_t)indirectBuffer threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup;
- (void)writeTimestampWithGranularity:(NSUInteger)granularity intoHeap:(id)heap atIndex:(NSUInteger)index;
- (void)copyFromBuffer:(id<MTLBuffer>)sourceBuffer sourceOffset:(NSUInteger)sourceOffset toBuffer:(id<MTLBuffer>)destinationBuffer destinationOffset:(NSUInteger)destinationOffset size:(NSUInteger)size;
- (void)copyFromBuffer:(id<MTLBuffer>)sourceBuffer sourceOffset:(NSUInteger)sourceOffset sourceBytesPerRow:(NSUInteger)sourceBytesPerRow sourceBytesPerImage:(NSUInteger)sourceBytesPerImage sourceSize:(MTLSize)sourceSize toTexture:(id<MTLTexture>)destinationTexture destinationSlice:(NSUInteger)destinationSlice destinationLevel:(NSUInteger)destinationLevel destinationOrigin:(MTLOrigin)destinationOrigin;
- (void)copyFromBuffer:(id<MTLBuffer>)sourceBuffer sourceOffset:(NSUInteger)sourceOffset sourceBytesPerRow:(NSUInteger)sourceBytesPerRow sourceBytesPerImage:(NSUInteger)sourceBytesPerImage sourceSize:(MTLSize)sourceSize toTexture:(id<MTLTexture>)destinationTexture destinationSlice:(NSUInteger)destinationSlice destinationLevel:(NSUInteger)destinationLevel destinationOrigin:(MTLOrigin)destinationOrigin options:(NSUInteger)options;
- (void)copyFromTexture:(id<MTLTexture>)sourceTexture sourceSlice:(NSUInteger)sourceSlice sourceLevel:(NSUInteger)sourceLevel sourceOrigin:(MTLOrigin)sourceOrigin sourceSize:(MTLSize)sourceSize toBuffer:(id<MTLBuffer>)destinationBuffer destinationOffset:(NSUInteger)destinationOffset destinationBytesPerRow:(NSUInteger)destinationBytesPerRow destinationBytesPerImage:(NSUInteger)destinationBytesPerImage;
- (void)copyFromTexture:(id<MTLTexture>)sourceTexture sourceSlice:(NSUInteger)sourceSlice sourceLevel:(NSUInteger)sourceLevel sourceOrigin:(MTLOrigin)sourceOrigin sourceSize:(MTLSize)sourceSize toBuffer:(id<MTLBuffer>)destinationBuffer destinationOffset:(NSUInteger)destinationOffset destinationBytesPerRow:(NSUInteger)destinationBytesPerRow destinationBytesPerImage:(NSUInteger)destinationBytesPerImage options:(NSUInteger)options;
- (void)copyFromTexture:(id<MTLTexture>)sourceTexture sourceSlice:(NSUInteger)sourceSlice sourceLevel:(NSUInteger)sourceLevel sourceOrigin:(MTLOrigin)sourceOrigin sourceSize:(MTLSize)sourceSize toTexture:(id<MTLTexture>)destinationTexture destinationSlice:(NSUInteger)destinationSlice destinationLevel:(NSUInteger)destinationLevel destinationOrigin:(MTLOrigin)destinationOrigin;
- (void)fillBuffer:(id<MTLBuffer>)buffer range:(NSRange)range value:(uint8_t)value;
@end

@protocol MTL4RenderCommandEncoder <MTLRenderCommandEncoder, MTL4CommandEncoder>
- (void)setArgumentTable:(id<MTL4ArgumentTable>)table atStages:(MTLRenderStages)stages;
- (void)drawMeshThreadgroupsWithIndirectBuffer:(uint64_t)indirectBuffer threadsPerObjectThreadgroup:(MTLSize)threadsPerObject threadsPerMeshThreadgroup:(MTLSize)threadsPerMesh;
- (void)drawPrimitives:(MTLPrimitiveType)primitiveType indirectBuffer:(uint64_t)indirectBuffer;
- (void)drawIndexedPrimitives:(MTLPrimitiveType)primitiveType indexCount:(NSUInteger)indexCount indexType:(MTLIndexType)indexType indexBuffer:(uint64_t)indexBuffer indexBufferLength:(NSUInteger)indexBufferLength instanceCount:(NSUInteger)instanceCount baseVertex:(NSInteger)baseVertex baseInstance:(NSUInteger)baseInstance;
- (void)drawIndexedPrimitives:(MTLPrimitiveType)primitiveType indexType:(MTLIndexType)indexType indexBuffer:(uint64_t)indexBuffer indexBufferLength:(NSUInteger)indexBufferLength indirectBuffer:(uint64_t)indirectBuffer;
- (void)writeTimestampWithGranularity:(NSUInteger)granularity afterStage:(MTLRenderStages)stage intoHeap:(id)heap atIndex:(NSUInteger)index;
- (void)setColorStoreAction:(MTLStoreAction)storeAction atIndex:(NSUInteger)colorAttachmentIndex;
- (void)setDepthStoreAction:(MTLStoreAction)storeAction;
- (void)setStencilStoreAction:(MTLStoreAction)storeAction;
@end

@protocol MTL4CommandAllocator <NSObject>
@property (readonly) NSUInteger allocatedSize;
- (void)reset;
@end

@protocol MTL4CommandBuffer <MTLCommandBuffer>
- (void)beginCommandBufferWithAllocator:(id)allocator;
- (void)endCommandBuffer;
- (id<MTL4ComputeCommandEncoder>)computeCommandEncoder;
- (id<MTL4RenderCommandEncoder>)renderCommandEncoderWithDescriptor:(id)descriptor;
@end

@protocol MTL4CommandQueue <MTLCommandQueue>
- (id<MTL4CommandBuffer>)commandBuffer;
- (void)commit:(id const *)buffers count:(NSUInteger)count options:(id)options;
- (void)commit:(id const *)buffers count:(NSUInteger)count;
- (void)signalEvent:(id)event value:(uint64_t)value;
- (void)waitForDrawable:(id)drawable;
- (void)signalDrawable:(id)drawable;
@end

@protocol MTL4CommitFeedback <NSObject>
@property (readonly) NSError *error;
@end

@protocol MTL4Compiler <NSObject>
- (id<MTLLibrary>)newLibraryWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTLRenderPipelineState>)newRenderPipelineStateWithDescriptor:(id)descriptor compilerTaskOptions:(id)options error:(NSError **)error;
- (id<MTLComputePipelineState>)newComputePipelineStateWithDescriptor:(id)descriptor compilerTaskOptions:(id)options error:(NSError **)error;
- (id<MTLRenderPipelineState>)newRenderPipelineStateBySpecializationWithDescriptor:(id)descriptor pipeline:(id)pipeline error:(NSError **)error;
@end

@protocol MTL4CounterHeap <NSObject>
- (NSData *)resolveCounterRange:(NSRange)range;
@end

@protocol MTL4PipelineDataSetSerializer <NSObject>
@end

@protocol MTL4FXSpatialScaler <NSObject>
@end

@protocol MTL4FXTemporalScaler <NSObject>
@end

@interface MTL4CommandQueueDescriptor : NSObject
@property (nonatomic, strong) dispatch_queue_t feedbackQueue;
@end

@interface MTL4CommandAllocatorDescriptor : NSObject
@property (nonatomic, copy) NSString *label;
@end

@interface MTL4ArgumentTableDescriptor : NSObject
@property (nonatomic) NSUInteger maxBufferBindCount;
@property (nonatomic) NSUInteger maxTextureBindCount;
@property (nonatomic) NSUInteger maxSamplerBindCount;
@property (nonatomic) NSUInteger maxSamplerStateBindCount;
@end

@interface MTL4LibraryDescriptor : NSObject
@property (nonatomic, copy) NSString *source;
@end

@interface MTL4CommitOptions : NSObject
- (void)addFeedbackHandler:(void (^)(id<MTL4CommitFeedback> feedback))handler;
@end

@interface MTL4CounterHeapDescriptor : NSObject
@property (nonatomic) NSUInteger type;
@property (nonatomic) NSUInteger count;
@end

@interface MTL4LibraryFunctionDescriptor : NSObject
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) MTLFunctionConstantValues *constantValues;
@end

@interface MTL4SpecializedFunctionDescriptor : NSObject
@property (nonatomic, strong) id functionDescriptor;
@property (nonatomic, strong) MTLFunctionConstantValues *constantValues;
@end

@interface MTL4CompilerDescriptor : NSObject
@property (nonatomic, strong) id pipelineDataSetSerializer;
@end

@interface MTL4PipelineDescriptor : NSObject
@end

@interface MTL4PipelineDataSetSerializerDescriptor : NSObject
@property (nonatomic) NSUInteger configuration;
@end

@interface MTL4Archive : NSObject
@end

@compatibility_alias MTL4RenderPassDescriptor MTLRenderPassDescriptor;
@compatibility_alias MTL4RenderPipelineDescriptor MTLRenderPipelineDescriptor;
@compatibility_alias MTL4RenderPipelineColorAttachmentDescriptor MTLRenderPipelineColorAttachmentDescriptor;
@compatibility_alias MTL4ComputePipelineDescriptor MTLComputePipelineDescriptor;
@compatibility_alias MTL4MeshRenderPipelineDescriptor MTLMeshRenderPipelineDescriptor;
@compatibility_alias MTL4FunctionDescriptor MTLFunctionDescriptor;

typedef struct { uint64_t timestamp; } MTL4TimestampHeapEntry;
typedef struct { NSUInteger mode; } MTL4UpdateSparseTextureMappingOperation;
typedef NSUInteger MTL4CompilerTaskOptions;

typedef NS_OPTIONS(NSUInteger, MTL4VisibilityOptions) {
    MTL4VisibilityOptionNone = 0,
    MTL4VisibilityOptionDevice = 1 << 0,
    MTL4VisibilityOptionResourceAlias = 1 << 1,
};

typedef NS_ENUM(NSUInteger, MTL4TimestampGranularity) {
    MTL4TimestampGranularityRelaxed = 0,
};

#define MTL4AlphaToCoverageStateDisabled 0
#define MTL4AlphaToCoverageStateEnabled 1
#define MTL4BlendStateDisabled 0
#define MTL4BlendStateEnabled 1
#define MTL4BlendStateUnspecialized 2
#define MTL4CounterHeapTypeTimestamp 0
#define MTL4PipelineDataSetSerializerConfigurationCaptureBinaries 0

#ifndef MTLGPUFamilyMetal4
#define MTLGPUFamilyMetal4 ((MTLGPUFamily)5001)
#endif

#ifndef MTL4CommandQueueErrorDomain
#define MTL4CommandQueueErrorDomain @"MTL4CommandQueueErrorDomain"
#define MTL4CommandQueueErrorTimeout 1
#define MTL4CommandQueueErrorAccessRevoked 2
#define MTL4CommandQueueErrorNotPermitted 3
#endif

#ifndef MTLPixelFormatUnspecialized
#define MTLPixelFormatUnspecialized ((MTLPixelFormat)999)
#endif
#ifndef MTLColorWriteMaskUnspecialized
#define MTLColorWriteMaskUnspecialized ((MTLColorWriteMask)0xF)
#endif
#ifndef MTLBlendFactorUnspecialized
#define MTLBlendFactorUnspecialized ((MTLBlendFactor)999)
#endif
#ifndef MTLBlendOperationUnspecialized
#define MTLBlendOperationUnspecialized ((MTLBlendOperation)999)
#endif

@interface MTLSamplerDescriptor (Metal4Compat)
@property (nonatomic) float lodBias;
@end

@protocol MTL4DeviceProtocol <MTLDevice>
@optional
- (id)newCommandBuffer;
- (id<MTL4CommandQueue>)newMTL4CommandQueueWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTL4CommandAllocator>)newCommandAllocatorWithDescriptor:(id)descriptor error:(NSError **)error;
- (id)newCommandAllocator;
- (id<MTL4ArgumentTable>)newArgumentTableWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTL4Compiler>)newCompilerWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTL4CounterHeap>)newCounterHeapWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTL4PipelineDataSetSerializer>)newPipelineDataSetSerializerWithDescriptor:(id)descriptor error:(NSError **)error;
- (id)newArchiveWithURL:(id)url error:(NSError **)error;
@end

#define MTLDevice MTL4DeviceProtocol

@interface NSObject (MTL4DeviceExtensions)
- (id)newCommandBuffer;
- (id<MTL4CommandQueue>)newMTL4CommandQueueWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTL4CommandAllocator>)newCommandAllocatorWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTL4ArgumentTable>)newArgumentTableWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTL4Compiler>)newCompilerWithDescriptor:(id)descriptor error:(NSError **)error;
@end
