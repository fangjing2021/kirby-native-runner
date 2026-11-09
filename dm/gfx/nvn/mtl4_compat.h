#pragma once
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@class MTL4CommandQueueDescriptor;
@class MTL4CommandAllocatorDescriptor;
@class MTL4ArgumentTableDescriptor;
@class MTL4LibraryDescriptor;
@class MTL4CommitOptions;

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
@end

@protocol MTL4Compiler <NSObject>
- (id<MTLLibrary>)newLibraryWithDescriptor:(id)descriptor error:(NSError **)error;
@end

@interface MTL4CommandQueueDescriptor : NSObject
@property (nonatomic, strong) dispatch_queue_t feedbackQueue;
@end

@interface MTL4CommandAllocatorDescriptor : NSObject
@property (nonatomic, copy) NSString *label;
@end

@interface MTL4ArgumentTableDescriptor : NSObject
@end

@interface MTL4LibraryDescriptor : NSObject
@property (nonatomic, copy) NSString *source;
@end

@interface MTL4CommitOptions : NSObject
@end

typedef NS_OPTIONS(NSUInteger, MTL4VisibilityOptions) {
    MTL4VisibilityOptionNone = 0,
    MTL4VisibilityOptionDevice = 1 << 0,
    MTL4VisibilityOptionResourceAlias = 1 << 1,
};

typedef NS_ENUM(NSUInteger, MTL4TimestampGranularity) {
    MTL4TimestampGranularityRelaxed = 0,
};

#ifndef MTLGPUFamilyMetal4
#define MTLGPUFamilyMetal4 ((MTLGPUFamily)5001)
#endif

#ifndef MTL4CommandQueueErrorDomain
#define MTL4CommandQueueErrorDomain @"MTL4CommandQueueErrorDomain"
#define MTL4CommandQueueErrorTimeout 1
#define MTL4CommandQueueErrorAccessRevoked 2
#define MTL4CommandQueueErrorNotPermitted 3
#endif

@interface NSObject (MTL4DeviceExtensions)
- (id<MTL4CommandQueue>)newMTL4CommandQueueWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTL4CommandAllocator>)newCommandAllocatorWithDescriptor:(id)descriptor error:(NSError **)error;
- (id<MTL4ArgumentTable>)newArgumentTableWithDescriptor:(id)descriptor error:(NSError **)error;
@end
