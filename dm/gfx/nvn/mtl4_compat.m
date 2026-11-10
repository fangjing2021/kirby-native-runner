#import "mtl4_compat.h"

@implementation MTL4CommandQueueDescriptor
@end

@implementation MTL4CommandAllocatorDescriptor
@end

@implementation MTL4ArgumentTableDescriptor
@end

@implementation MTL4LibraryDescriptor
@end

@implementation MTL4CommitOptions
- (void)addFeedbackHandler:(void (^)(id<MTL4CommitFeedback> feedback))handler {
    (void)handler;
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
- (id)newCommandBuffer {
    if ([self respondsToSelector:@selector(commandBuffer)]) {
        return [(id)self commandBuffer];
    }
    return [NSObject new];
}

- (id)newCommandAllocator {
    return [NSObject new];
}

- (id)newMTL4CommandQueueWithDescriptor:(id)descriptor error:(NSError **)error {
    if ([self conformsToProtocol:@protocol(MTLDevice)]) {
        id<MTLDevice> dev = (id<MTLDevice>)self;
        return [dev newCommandQueue];
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
    (void)options;
    for (NSUInteger i = 0; i < count; i++) {
        id b = buffers[i];
        if ([b respondsToSelector:@selector(commit)]) {
            [b commit];
        }
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
- (BOOL)serializeAsArchiveAndFlushToURL:(NSURL *)url error:(NSError **)error {
    (void)url; (void)error;
    return YES;
}
- (void)encodeToCommandBuffer:(id)commandBuffer { (void)commandBuffer; }
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
@end
