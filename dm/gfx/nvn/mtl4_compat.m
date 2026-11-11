#import "mtl4_compat.h"
#include "nvn_mtl.h"

@implementation MTL4CommandQueueDescriptor
@end

@implementation MTL4CommandAllocatorDescriptor
@end

@implementation MTL4ArgumentTableDescriptor
@end

@implementation MTL4LibraryDescriptor
@end

@interface MTL4CommitFeedbackImpl : NSObject <MTL4CommitFeedback>
@property (nonatomic, strong) NSError *error;
@property (nonatomic) double GPUStartTime;
@property (nonatomic) double GPUEndTime;
@end

@implementation MTL4CommitFeedbackImpl
@end

@implementation MTL4CommitOptions {
@public
    NSMutableArray *_handlers;
}
- (instancetype)init {
    if ((self = [super init])) {
        _handlers = [NSMutableArray array];
    }
    return self;
}
- (void)addFeedbackHandler:(void (^)(id<MTL4CommitFeedback> feedback))handler {
    if (handler) {
        if (!_handlers) _handlers = [NSMutableArray array];
        [_handlers addObject:[handler copy]];
    }
}
@end

@implementation MTL4CounterHeapDescriptor
@end

@implementation MTL4LibraryFunctionDescriptor
@end

@implementation MTL4SpecializedFunctionDescriptor
@end

@implementation MTL4CompilerDescriptor
@end

@implementation MTL4PipelineDescriptor
@end

@implementation MTL4PipelineDataSetSerializerDescriptor
@end

@implementation MTL4Archive
@end

@implementation MTLSamplerDescriptor (Metal4Compat)
- (float)lodBias {
    return 0.0f;
}
- (void)setLodBias:(float)lodBias {
    (void)lodBias;
}
- (MTLSamplerReductionMode)reductionMode {
    return MTLSamplerReductionModeStandard;
}
- (void)setReductionMode:(MTLSamplerReductionMode)mode {
    (void)mode;
}
@end

@implementation CAMetalLayer (Metal4Compat)
- (id)residencySet {
    return nil;
}
@end

@implementation MTLFXSpatialScalerDescriptor (Metal4Compat)
+ (BOOL)supportsMetal4FX:(id<MTLDevice>)device {
    (void)device;
    return NO;
}
- (id)newSpatialScalerWithDevice:(id)device compiler:(id)compiler {
    (void)device; (void)compiler;
    return nil;
}
@end

@implementation MTLFXTemporalScalerDescriptor (Metal4Compat)
+ (BOOL)supportsMetal4FX:(id<MTLDevice>)device {
    (void)device;
    return NO;
}
- (id)newTemporalScalerWithDevice:(id)device compiler:(id)compiler {
    (void)device; (void)compiler;
    return nil;
}
@end

@implementation NSObject (MTL4DeviceExtensions)
- (id)newPipelineDataSetSerializerWithDescriptor:(id)descriptor {
    (void)descriptor;
    return [NSObject new];
}
static id<MTLCommandQueue> s_compat_queue;

- (id)newCommandBuffer {
    if ([self respondsToSelector:@selector(commandBuffer)]) {
        return [(id)self commandBuffer];
    }
    if (s_compat_queue) {
        return [s_compat_queue commandBuffer];
    }
    if ([self respondsToSelector:@selector(newCommandQueue)]) {
        id<MTLCommandQueue> q = [(id)self newCommandQueue];
        s_compat_queue = q;
        return [q commandBuffer];
    }
    return [NSObject new];
}

- (id)newCommandAllocator {
    return [NSObject new];
}

- (id)newMTL4CommandQueueWithDescriptor:(id)descriptor error:(NSError **)error {
    if ([self respondsToSelector:@selector(newCommandQueue)]) {
        id<MTLCommandQueue> q = [(id)self newCommandQueue];
        s_compat_queue = q;
        return q;
    }
    if ([self conformsToProtocol:@protocol(MTLDevice)]) {
        id<MTLDevice> dev = (id<MTLDevice>)self;
        id<MTLCommandQueue> q = [dev newCommandQueue];
        s_compat_queue = q;
        return q;
    }
    if (error) *error = [NSError errorWithDomain:@"MTL4" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Device does not support command queue"}];
    return nil;
}

- (id)newCommandAllocatorWithDescriptor:(id)descriptor error:(NSError **)error {
    return [NSObject new];
}

- (id)newArgumentTableWithDescriptor:(id)descriptor error:(NSError **)error {
    return [NSObject new];
}

- (id)newCompilerWithDescriptor:(id)descriptor error:(NSError **)error {
    if (error) *error = [NSError errorWithDomain:@"MTL4" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Metal 4 compiler not supported on iOS 18"}];
    return nil;
}

- (id)newCounterHeapWithDescriptor:(id)descriptor error:(NSError **)error {
    return [NSObject new];
}

- (id)newPipelineDataSetSerializerWithDescriptor:(id)descriptor error:(NSError **)error {
    return [NSObject new];
}

- (id)newArchiveWithURL:(id)url error:(NSError **)error {
    return nil;
}

- (uint64_t)queryTimestampFrequency {
    return 1000000000ULL;
}

- (NSUInteger)maximumConcurrentCompilationTaskCount {
    return 0;
}
@end

@implementation NSObject (MTL4CompatObject)
- (void)beginCommandBufferWithAllocator:(id)allocator { (void)allocator; }
- (void)endCommandBuffer {}
- (void)barrierAfterStages:(NSUInteger)after beforeQueueStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis {
    (void)after; (void)before; (void)vis;
}
- (void)barrierAfterEncoderStages:(NSUInteger)after beforeEncoderStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis {
    (void)after; (void)before; (void)vis;
}
- (void)barrierAfterQueueStages:(NSUInteger)after beforeStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis {
    (void)after; (void)before; (void)vis;
}
- (void)setArgumentTable:(id)table { (void)table; }
- (void)setArgumentTable:(id)table atStages:(MTLRenderStages)stages { (void)table; (void)stages; }
- (void)setAddress:(uint64_t)address atIndex:(NSUInteger)index { (void)address; (void)index; }
- (void)setTexture:(MTLResourceID)texture atIndex:(NSUInteger)index { (void)texture; (void)index; }
- (void)setSamplerState:(MTLResourceID)sampler atIndex:(NSUInteger)index { (void)sampler; (void)index; }
- (void)commit:(id const *)buffers count:(NSUInteger)count options:(id)options {
    NSArray *handlers = nil;
    if ([options isKindOfClass:[MTL4CommitOptions class]]) {
        MTL4CommitOptions *opt = (MTL4CommitOptions *)options;
        if (opt->_handlers.count > 0) {
            handlers = [opt->_handlers copy];
        }
    }
    BOOL dispatched = NO;
    for (NSUInteger i = 0; i < count; i++) {
        id b = buffers[i];
        if (handlers.count > 0 && [b respondsToSelector:@selector(addCompletedHandler:)]) {
            dispatched = YES;
            [b addCompletedHandler:^(id<MTLCommandBuffer> cb) {
                MTL4CommitFeedbackImpl *f = [MTL4CommitFeedbackImpl new];
                f.error = cb.error;
                f.GPUStartTime = cb.GPUStartTime;
                f.GPUEndTime = cb.GPUEndTime;
                for (void (^h)(id<MTL4CommitFeedback>) in handlers) {
                    h(f);
                }
            }];
        }
        if ([b respondsToSelector:@selector(commit)]) {
            [b commit];
        }
    }
    if (handlers.count > 0 && !dispatched) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MTL4CommitFeedbackImpl *f = [MTL4CommitFeedbackImpl new];
            for (void (^h)(id<MTL4CommitFeedback>) in handlers) {
                h(f);
            }
        });
    }
}
- (void)commit:(id const *)buffers count:(NSUInteger)count {
    for (NSUInteger i = 0; i < count; i++) {
        id b = buffers[i];
        if ([b respondsToSelector:@selector(commit)]) {
            [b commit];
        }
    }
}
- (void)waitForDrawable:(id)dr { (void)dr; }
- (void)signalDrawable:(id)dr { (void)dr; }
- (void)addResidencySet:(id)set { (void)set; }
- (void)waitForEvent:(id)event value:(uint64_t)value { (void)event; (void)value; }
- (void)updateTextureMappings:(id)texture heap:(id)heap operations:(const void *)operations count:(NSUInteger)count {
    (void)texture; (void)heap; (void)operations; (void)count;
}
- (double)GPUStartTime { return 0.0; }
- (double)GPUEndTime { return 0.0; }
- (NSUInteger)maxCompatiblePlacementSparsePageSize { return 0; }
- (void)setMaxCompatiblePlacementSparsePageSize:(NSUInteger)size { (void)size; }
- (NSUInteger)placementSparsePageSize { return 0; }
- (void)setPlacementSparsePageSize:(NSUInteger)size { (void)size; }
- (NSUInteger)reductionMode { return 0; }
- (void)setReductionMode:(NSUInteger)mode { (void)mode; }
- (id)computeFunctionDescriptor { return nil; }
- (void)setComputeFunctionDescriptor:(id)fd { (void)fd; }
- (id)meshFunctionDescriptor { return nil; }
- (void)setMeshFunctionDescriptor:(id)fd { (void)fd; }
- (id)vertexFunctionDescriptor { return nil; }
- (void)setVertexFunctionDescriptor:(id)fd { (void)fd; }
- (id)fragmentFunctionDescriptor { return nil; }
- (void)setFragmentFunctionDescriptor:(id)fd { (void)fd; }
- (id)objectFunctionDescriptor { return nil; }
- (void)setObjectFunctionDescriptor:(id)fd { (void)fd; }
- (NSUInteger)alphaToCoverageState { return 0; }
- (void)setAlphaToCoverageState:(NSUInteger)state { (void)state; }
- (NSUInteger)blendingState { return 0; }
- (void)setBlendingState:(NSUInteger)state { (void)state; }
- (NSUInteger)colorTextureUsage { return 0; }
- (void)setColorTextureUsage:(NSUInteger)u { (void)u; }
- (NSUInteger)depthTextureUsage { return 0; }
- (void)setDepthTextureUsage:(NSUInteger)u { (void)u; }
- (NSUInteger)motionTextureUsage { return 0; }
- (void)setMotionTextureUsage:(NSUInteger)u { (void)u; }
- (NSUInteger)outputTextureUsage { return 0; }
- (void)setOutputTextureUsage:(NSUInteger)u { (void)u; }
- (id)colorTexture { return nil; }
- (void)setColorTexture:(id)t { (void)t; }
- (id)depthTexture { return nil; }
- (void)setDepthTexture:(id)t { (void)t; }
- (id)motionTexture { return nil; }
- (void)setMotionTexture:(id)t { (void)t; }
- (id)outputTexture { return nil; }
- (void)setOutputTexture:(id)t { (void)t; }
- (id)exposureTexture { return nil; }
- (void)setExposureTexture:(id)t { (void)t; }
- (NSUInteger)inputContentWidth { return 0; }
- (void)setInputContentWidth:(NSUInteger)w { (void)w; }
- (NSUInteger)inputContentHeight { return 0; }
- (void)setInputContentHeight:(NSUInteger)h { (void)h; }
- (NSUInteger)colorContentOffsetX { return 0; }
- (void)setColorContentOffsetX:(NSUInteger)x { (void)x; }
- (NSUInteger)colorContentOffsetY { return 0; }
- (void)setColorContentOffsetY:(NSUInteger)y { (void)y; }
- (NSUInteger)depthContentOffsetX { return 0; }
- (void)setDepthContentOffsetX:(NSUInteger)x { (void)x; }
- (NSUInteger)depthContentOffsetY { return 0; }
- (void)setDepthContentOffsetY:(NSUInteger)y { (void)y; }
- (NSUInteger)motionContentOffsetX { return 0; }
- (void)setMotionContentOffsetX:(NSUInteger)x { (void)x; }
- (NSUInteger)motionContentOffsetY { return 0; }
- (void)setMotionContentOffsetY:(NSUInteger)y { (void)y; }
- (NSUInteger)outputOffsetX { return 0; }
- (void)setOutputOffsetX:(NSUInteger)x { (void)x; }
- (NSUInteger)outputOffsetY { return 0; }
- (void)setOutputOffsetY:(NSUInteger)y { (void)y; }
- (float)motionVectorScaleX { return 0.0f; }
- (void)setMotionVectorScaleX:(float)s { (void)s; }
- (float)motionVectorScaleY { return 0.0f; }
- (void)setMotionVectorScaleY:(float)s { (void)s; }
- (float)jitterOffsetX { return 0.0f; }
- (void)setJitterOffsetX:(float)o { (void)o; }
- (float)jitterOffsetY { return 0.0f; }
- (void)setJitterOffsetY:(float)o { (void)o; }
- (float)preExposure { return 0.0f; }
- (void)setPreExposure:(float)p { (void)p; }
- (BOOL)depthReversed { return NO; }
- (void)setDepthReversed:(BOOL)r { (void)r; }
- (void)setReset:(BOOL)r { (void)r; }
- (BOOL)serializeAsArchiveAndFlushToURL:(NSURL *)url error:(NSError **)error {
    (void)url; (void)error;
    return YES;
}
- (void)encodeToCommandBuffer:(id)commandBuffer { (void)commandBuffer; }
- (id)residencySet { return nil; }
- (NSUInteger)allocatedSize { return 0; }
- (void)reset {}
- (void)invalidateCounterRange:(NSRange)range { (void)range; }
- (NSData *)resolveCounterRange:(NSRange)range { (void)range; return nil; }
- (id)newRenderPipelineStateWithDescriptor:(id)descriptor error:(NSError **)error {
    if (error) *error = [NSError errorWithDomain:@"MTL4" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Archive not supported on iOS 18"}];
    return nil;
}
- (id)newComputePipelineStateWithDescriptor:(id)descriptor error:(NSError **)error {
    if (error) *error = [NSError errorWithDomain:@"MTL4" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Archive not supported on iOS 18"}];
    return nil;
}
- (void)copyFromBuffer:(id<MTLBuffer>)sourceBuffer sourceOffset:(NSUInteger)sourceOffset toBuffer:(id<MTLBuffer>)destinationBuffer destinationOffset:(NSUInteger)destinationOffset size:(NSUInteger)size {
    if ([sourceBuffer respondsToSelector:@selector(contents)] && sourceBuffer.contents &&
        [destinationBuffer respondsToSelector:@selector(contents)] && destinationBuffer.contents) {
        memcpy((uint8_t *)destinationBuffer.contents + destinationOffset, (const uint8_t *)sourceBuffer.contents + sourceOffset, size);
    }
}
- (void)copyFromBuffer:(id<MTLBuffer>)sourceBuffer sourceOffset:(NSUInteger)sourceOffset sourceBytesPerRow:(NSUInteger)sourceBytesPerRow sourceBytesPerImage:(NSUInteger)sourceBytesPerImage sourceSize:(MTLSize)sourceSize toTexture:(id<MTLTexture>)destinationTexture destinationSlice:(NSUInteger)destinationSlice destinationLevel:(NSUInteger)destinationLevel destinationOrigin:(MTLOrigin)destinationOrigin {
    if ([sourceBuffer respondsToSelector:@selector(contents)] && sourceBuffer.contents) {
        const uint8_t *src = (const uint8_t *)sourceBuffer.contents + sourceOffset;
        MTLRegion region = MTLRegionMake3D(destinationOrigin.x, destinationOrigin.y, destinationOrigin.z, sourceSize.width, sourceSize.height, sourceSize.depth);
        [destinationTexture replaceRegion:region mipmapLevel:destinationLevel slice:destinationSlice withBytes:src bytesPerRow:sourceBytesPerRow bytesPerImage:sourceBytesPerImage];
    }
}
- (void)copyFromBuffer:(id<MTLBuffer>)sourceBuffer sourceOffset:(NSUInteger)sourceOffset sourceBytesPerRow:(NSUInteger)sourceBytesPerRow sourceBytesPerImage:(NSUInteger)sourceBytesPerImage sourceSize:(MTLSize)sourceSize toTexture:(id<MTLTexture>)destinationTexture destinationSlice:(NSUInteger)destinationSlice destinationLevel:(NSUInteger)destinationLevel destinationOrigin:(MTLOrigin)destinationOrigin options:(NSUInteger)options {
    (void)options;
    [self copyFromBuffer:sourceBuffer sourceOffset:sourceOffset sourceBytesPerRow:sourceBytesPerRow sourceBytesPerImage:sourceBytesPerImage sourceSize:sourceSize toTexture:destinationTexture destinationSlice:destinationSlice destinationLevel:destinationLevel destinationOrigin:destinationOrigin];
}
- (void)copyFromTexture:(id<MTLTexture>)sourceTexture sourceSlice:(NSUInteger)sourceSlice sourceLevel:(NSUInteger)sourceLevel sourceOrigin:(MTLOrigin)sourceOrigin sourceSize:(MTLSize)sourceSize toBuffer:(id<MTLBuffer>)destinationBuffer destinationOffset:(NSUInteger)destinationOffset destinationBytesPerRow:(NSUInteger)destinationBytesPerRow destinationBytesPerImage:(NSUInteger)destinationBytesPerImage {
    if ([destinationBuffer respondsToSelector:@selector(contents)] && destinationBuffer.contents) {
        uint8_t *dst = (uint8_t *)destinationBuffer.contents + destinationOffset;
        MTLRegion region = MTLRegionMake3D(sourceOrigin.x, sourceOrigin.y, sourceOrigin.z, sourceSize.width, sourceSize.height, sourceSize.depth);
        [sourceTexture getBytes:dst bytesPerRow:destinationBytesPerRow bytesPerImage:destinationBytesPerImage fromRegion:region mipmapLevel:sourceLevel slice:sourceSlice];
    }
}
- (void)copyFromTexture:(id<MTLTexture>)sourceTexture sourceSlice:(NSUInteger)sourceSlice sourceLevel:(NSUInteger)sourceLevel sourceOrigin:(MTLOrigin)sourceOrigin sourceSize:(MTLSize)sourceSize toBuffer:(id<MTLBuffer>)destinationBuffer destinationOffset:(NSUInteger)destinationOffset destinationBytesPerRow:(NSUInteger)destinationBytesPerRow destinationBytesPerImage:(NSUInteger)destinationBytesPerImage options:(NSUInteger)options {
    (void)options;
    [self copyFromTexture:sourceTexture sourceSlice:sourceSlice sourceLevel:sourceLevel sourceOrigin:sourceOrigin sourceSize:sourceSize toBuffer:destinationBuffer destinationOffset:destinationOffset destinationBytesPerRow:destinationBytesPerRow destinationBytesPerImage:destinationBytesPerImage];
}
- (void)copyFromTexture:(id<MTLTexture>)sourceTexture sourceSlice:(NSUInteger)sourceSlice sourceLevel:(NSUInteger)sourceLevel sourceOrigin:(MTLOrigin)sourceOrigin sourceSize:(MTLSize)sourceSize toTexture:(id<MTLTexture>)destinationTexture destinationSlice:(NSUInteger)destinationSlice destinationLevel:(NSUInteger)destinationLevel destinationOrigin:(MTLOrigin)destinationOrigin {
    (void)sourceTexture; (void)sourceSlice; (void)sourceLevel; (void)sourceOrigin; (void)sourceSize;
    (void)destinationTexture; (void)destinationSlice; (void)destinationLevel; (void)destinationOrigin;
}
- (void)fillBuffer:(id<MTLBuffer>)buffer range:(NSRange)range value:(uint8_t)value {
    if ([buffer respondsToSelector:@selector(contents)] && buffer.contents) {
        memset((uint8_t *)buffer.contents + range.location, value, range.length);
    }
}
- (void)dispatchThreadgroupsWithIndirectBuffer:(uint64_t)indirectBuffer threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup {
    void *ind_buf = NULL;
    uint64_t ind_off = 0;
    if (mtl_addr(indirectBuffer, 12, &ind_buf, &ind_off)) {
        if ([self respondsToSelector:@selector(dispatchThreadgroupsWithIndirectBuffer:indirectBufferOffset:threadsPerThreadgroup:)]) {
            [(id<MTLComputeCommandEncoder>)self dispatchThreadgroupsWithIndirectBuffer:(__bridge id<MTLBuffer>)ind_buf indirectBufferOffset:ind_off threadsPerThreadgroup:threadsPerThreadgroup];
        }
    }
}
- (void)drawPrimitives:(MTLPrimitiveType)primitiveType indirectBuffer:(uint64_t)indirectBuffer {
    void *ind_buf = NULL;
    uint64_t ind_off = 0;
    if (mtl_addr(indirectBuffer, 16, &ind_buf, &ind_off)) {
        if ([self respondsToSelector:@selector(drawPrimitives:indirectBuffer:indirectBufferOffset:)]) {
            [(id<MTLRenderCommandEncoder>)self drawPrimitives:primitiveType indirectBuffer:(__bridge id<MTLBuffer>)ind_buf indirectBufferOffset:ind_off];
        }
    }
}
- (void)drawIndexedPrimitives:(MTLPrimitiveType)primitiveType indexCount:(NSUInteger)indexCount indexType:(MTLIndexType)indexType indexBuffer:(uint64_t)indexBuffer indexBufferLength:(NSUInteger)indexBufferLength instanceCount:(NSUInteger)instanceCount baseVertex:(NSInteger)baseVertex baseInstance:(NSUInteger)baseInstance {
    void *buf = NULL;
    uint64_t off = 0;
    if (mtl_addr(indexBuffer, indexBufferLength, &buf, &off)) {
        if ([self respondsToSelector:@selector(drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:baseVertex:baseInstance:)]) {
            [(id<MTLRenderCommandEncoder>)self drawIndexedPrimitives:primitiveType indexCount:indexCount indexType:indexType indexBuffer:(__bridge id<MTLBuffer>)buf indexBufferOffset:off instanceCount:instanceCount baseVertex:baseVertex baseInstance:baseInstance];
        }
    }
}
- (void)drawIndexedPrimitives:(MTLPrimitiveType)primitiveType indexType:(MTLIndexType)indexType indexBuffer:(uint64_t)indexBuffer indexBufferLength:(NSUInteger)indexBufferLength indirectBuffer:(uint64_t)indirectBuffer {
    void *ibuf = NULL, *ind_buf = NULL;
    uint64_t ioff = 0, ind_off = 0;
    if (mtl_addr(indexBuffer, indexBufferLength, &ibuf, &ioff) && mtl_addr(indirectBuffer, 20, &ind_buf, &ind_off)) {
        if ([self respondsToSelector:@selector(drawIndexedPrimitives:indexType:indexBuffer:indexBufferOffset:indirectBuffer:indirectBufferOffset:)]) {
            [(id<MTLRenderCommandEncoder>)self drawIndexedPrimitives:primitiveType indexType:indexType indexBuffer:(__bridge id<MTLBuffer>)ibuf indexBufferOffset:ioff indirectBuffer:(__bridge id<MTLBuffer>)ind_buf indirectBufferOffset:ind_off];
        }
    }
}
- (void)drawMeshThreadgroupsWithIndirectBuffer:(uint64_t)indirectBuffer threadsPerObjectThreadgroup:(MTLSize)threadsPerObject threadsPerMeshThreadgroup:(MTLSize)threadsPerMesh {
    void *ind_buf = NULL;
    uint64_t ind_off = 0;
    if (mtl_addr(indirectBuffer, 16, &ind_buf, &ind_off)) {
        if ([self respondsToSelector:@selector(drawMeshThreadgroupsWithIndirectBuffer:indirectBufferOffset:threadsPerObjectThreadgroup:threadsPerMeshThreadgroup:)]) {
            [(id<MTLRenderCommandEncoder>)self drawMeshThreadgroupsWithIndirectBuffer:(__bridge id<MTLBuffer>)ind_buf indirectBufferOffset:ind_off threadsPerObjectThreadgroup:threadsPerObject threadsPerMeshThreadgroup:threadsPerMesh];
        }
    }
}
- (void)setVertexAmplificationCount:(NSUInteger)count viewMappings:(const void *)viewMappings {
    (void)count; (void)viewMappings;
}
- (void)writeTimestampWithGranularity:(NSUInteger)granularity intoHeap:(id)heap atIndex:(NSUInteger)index {
    (void)granularity; (void)heap; (void)index;
}
- (void)writeTimestampWithGranularity:(NSUInteger)granularity afterStage:(MTLRenderStages)stage intoHeap:(id)heap atIndex:(NSUInteger)index {
    (void)granularity; (void)stage; (void)heap; (void)index;
}
@end
