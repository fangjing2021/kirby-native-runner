#import "mtl4_compat.h"
#include "nvn_mtl.h"
#import <objc/runtime.h>
#import <os/lock.h>

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

@interface DmRecTableIvarHolder : NSObject { @public id real; } @end
@implementation DmRecTableIvarHolder @end

static inline DmCompatArgumentTable *unwrap_compat_table(id obj) {
    if (!obj) return nil;
    if ([obj isKindOfClass:[DmCompatArgumentTable class]]) return (DmCompatArgumentTable *)obj;
    const char *cname = object_getClassName(obj);
    if (cname && strcmp(cname, "DmRecTable") == 0) {
        id real = ((DmRecTableIvarHolder *)obj)->real;
        if ([real isKindOfClass:[DmCompatArgumentTable class]]) return (DmCompatArgumentTable *)real;
    }
    return nil;
}

static __unsafe_unretained DmCompatArgumentTable *s_all_tables[64];
static int s_all_tables_count = 0;
static os_unfair_lock s_tables_lock = OS_UNFAIR_LOCK_INIT;

static __unsafe_unretained DmCompatArgumentTable *s_active_vt = nil;
static __unsafe_unretained DmCompatArgumentTable *s_active_ft = nil;
static __unsafe_unretained DmCompatArgumentTable *s_active_ct = nil;

@implementation DmCompatArgumentTable {
    uint64_t _addresses[32];
    id<MTLBuffer> _buffers[32];
    NSUInteger _offsets[32];
    uint32_t _valid_mask;
    __unsafe_unretained id _encoder;
    MTLRenderStages _render_stages;
    BOOL _is_compute;
}

- (instancetype)init {
    if ((self = [super init])) {
        os_unfair_lock_lock(&s_tables_lock);
        if (s_all_tables_count < 64) {
            s_all_tables[s_all_tables_count++] = self;
        }
        os_unfair_lock_unlock(&s_tables_lock);
    }
    return self;
}

- (void)dealloc {
    os_unfair_lock_lock(&s_tables_lock);
    for (int i = 0; i < s_all_tables_count; i++) {
        if (s_all_tables[i] == self) {
            s_all_tables[i] = s_all_tables[--s_all_tables_count];
            break;
        }
    }
    os_unfair_lock_unlock(&s_tables_lock);
}

+ (void)notifyEncoderEnded:(id)encoder {
    if (!encoder) return;
    os_unfair_lock_lock(&s_tables_lock);
    for (int i = 0; i < s_all_tables_count; i++) {
        DmCompatArgumentTable *t = s_all_tables[i];
        if (t && t->_encoder == encoder) {
            t->_encoder = nil;
        }
    }
    if (s_active_vt && s_active_vt->_encoder == nil) s_active_vt = nil;
    if (s_active_ft && s_active_ft->_encoder == nil) s_active_ft = nil;
    if (s_active_ct && s_active_ct->_encoder == nil) s_active_ct = nil;
    os_unfair_lock_unlock(&s_tables_lock);
}

- (void)applyToIndex:(NSUInteger)index {
    if (index >= 32 || !(_valid_mask & (1u << index))) return;
    id enc = _encoder;
    if (!enc) return;
    id<MTLBuffer> buf = _buffers[index];
    NSUInteger off = _offsets[index];
    if (!buf) return;
    if (_is_compute) {
        if ([enc respondsToSelector:@selector(setBuffer:offset:atIndex:)]) {
            [(id<MTLComputeCommandEncoder>)enc setBuffer:buf offset:off atIndex:index];
        }
    } else {
        if ((_render_stages & MTLRenderStageVertex) && [enc respondsToSelector:@selector(setVertexBuffer:offset:atIndex:)]) {
            [(id<MTLRenderCommandEncoder>)enc setVertexBuffer:buf offset:off atIndex:index];
        }
        if ((_render_stages & MTLRenderStageFragment) && [enc respondsToSelector:@selector(setFragmentBuffer:offset:atIndex:)]) {
            [(id<MTLRenderCommandEncoder>)enc setFragmentBuffer:buf offset:off atIndex:index];
        }
    }
}

- (void)applyAllToEncoder:(id)encoder {
    if (!encoder) return;
    for (NSUInteger i = 0; i < 32; i++) {
        if (_valid_mask & (1u << i)) {
            id<MTLBuffer> buf = _buffers[i];
            NSUInteger off = _offsets[i];
            if (buf) {
                if (_is_compute) {
                    if ([encoder respondsToSelector:@selector(setBuffer:offset:atIndex:)]) {
                        [(id<MTLComputeCommandEncoder>)encoder setBuffer:buf offset:off atIndex:i];
                    }
                } else {
                    if ((_render_stages & MTLRenderStageVertex) && [encoder respondsToSelector:@selector(setVertexBuffer:offset:atIndex:)]) {
                        [(id<MTLRenderCommandEncoder>)encoder setVertexBuffer:buf offset:off atIndex:i];
                    }
                    if ((_render_stages & MTLRenderStageFragment) && [encoder respondsToSelector:@selector(setFragmentBuffer:offset:atIndex:)]) {
                        [(id<MTLRenderCommandEncoder>)encoder setFragmentBuffer:buf offset:off atIndex:i];
                    }
                }
            }
        }
    }
}

- (void)setAddress:(uint64_t)address atIndex:(NSUInteger)index {
    if (index >= 32) return;
    _addresses[index] = address;
    if (address) {
        void *b = NULL;
        uint64_t off = 0;
        if (mtl_addr(address, 1, &b, &off) && b) {
            _buffers[index] = (__bridge id<MTLBuffer>)b;
            _offsets[index] = (NSUInteger)off;
            _valid_mask |= (1u << index);
        } else {
            _buffers[index] = nil;
            _offsets[index] = 0;
            _valid_mask &= ~(1u << index);
        }
    } else {
        _buffers[index] = nil;
        _offsets[index] = 0;
        _valid_mask &= ~(1u << index);
    }
    [self applyToIndex:index];
}

- (void)setTexture:(MTLResourceID)texture atIndex:(NSUInteger)index { (void)texture; (void)index; }
- (void)setSamplerState:(MTLResourceID)sampler atIndex:(NSUInteger)index { (void)sampler; (void)index; }

- (void)bindToRenderEncoder:(id)encoder stages:(MTLRenderStages)stages {
    _encoder = encoder;
    _render_stages = stages;
    _is_compute = NO;
    if (stages & MTLRenderStageVertex) s_active_vt = self;
    if (stages & MTLRenderStageFragment) s_active_ft = self;
    [self applyAllToEncoder:encoder];
}

- (void)bindToComputeEncoder:(id)encoder {
    _encoder = encoder;
    _is_compute = YES;
    _render_stages = 0;
    s_active_ct = self;
    [self applyAllToEncoder:encoder];
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
    (void)descriptor; (void)error;
    return [DmCompatArgumentTable new];
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
- (void)setArgumentTable:(id)table {
    DmCompatArgumentTable *t = unwrap_compat_table(table);
    if (t) [t bindToComputeEncoder:self];
}
- (void)setArgumentTable:(id)table atStages:(MTLRenderStages)stages {
    DmCompatArgumentTable *t = unwrap_compat_table(table);
    if (t) [t bindToRenderEncoder:self stages:stages];
}
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

- (void)signalEvent:(id)event value:(uint64_t)value {
    if ([event respondsToSelector:@selector(setSignaledValue:)]) {
        ((id<MTLSharedEvent>)event).signaledValue = value;
    }
}
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
    if ([destinationTexture respondsToSelector:@selector(storageMode)] && destinationTexture.storageMode != MTLStorageModeShared) {
        return;
    }
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
    if ([sourceTexture respondsToSelector:@selector(storageMode)] && sourceTexture.storageMode != MTLStorageModeShared) {
        return;
    }
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
    if (([sourceTexture respondsToSelector:@selector(storageMode)] && sourceTexture.storageMode != MTLStorageModeShared) ||
        ([destinationTexture respondsToSelector:@selector(storageMode)] && destinationTexture.storageMode != MTLStorageModeShared)) {
        return;
    }
    if ([sourceTexture respondsToSelector:@selector(getBytes:bytesPerRow:bytesPerImage:fromRegion:mipmapLevel:slice:)] &&
        [destinationTexture respondsToSelector:@selector(replaceRegion:mipmapLevel:slice:withBytes:bytesPerRow:bytesPerImage:)]) {
        NSUInteger bpp = 4;
        NSUInteger bytesPerRow = sourceSize.width * bpp;
        NSUInteger bytesPerImage = bytesPerRow * sourceSize.height;
        NSUInteger depth = sourceSize.depth > 0 ? sourceSize.depth : 1;
        void *tmp = malloc(bytesPerImage * depth);
        if (tmp) {
            MTLRegion sreg = MTLRegionMake3D(sourceOrigin.x, sourceOrigin.y, sourceOrigin.z, sourceSize.width, sourceSize.height, depth);
            [sourceTexture getBytes:tmp bytesPerRow:bytesPerRow bytesPerImage:bytesPerImage fromRegion:sreg mipmapLevel:sourceLevel slice:sourceSlice];
            MTLRegion dreg = MTLRegionMake3D(destinationOrigin.x, destinationOrigin.y, destinationOrigin.z, sourceSize.width, sourceSize.height, depth);
            [destinationTexture replaceRegion:dreg mipmapLevel:destinationLevel slice:destinationSlice withBytes:tmp bytesPerRow:bytesPerRow bytesPerImage:bytesPerImage];
            free(tmp);
        }
    }
}
- (void)fillBuffer:(id<MTLBuffer>)buffer range:(NSRange)range value:(uint8_t)value {
    if ([buffer respondsToSelector:@selector(contents)] && buffer.contents) {
        memset((uint8_t *)buffer.contents + range.location, value, range.length);
    }
}
- (void)dispatchThreadgroupsWithIndirectBuffer:(uint64_t)indirectBuffer threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup {
    if (s_active_ct) [s_active_ct applyAllToEncoder:self];
    void *ind_buf = NULL;
    uint64_t ind_off = 0;
    if (mtl_addr(indirectBuffer, 12, &ind_buf, &ind_off)) {
        if ([self respondsToSelector:@selector(dispatchThreadgroupsWithIndirectBuffer:indirectBufferOffset:threadsPerThreadgroup:)]) {
            [(id<MTLComputeCommandEncoder>)self dispatchThreadgroupsWithIndirectBuffer:(__bridge id<MTLBuffer>)ind_buf indirectBufferOffset:ind_off threadsPerThreadgroup:threadsPerThreadgroup];
        }
    }
}
- (void)drawPrimitives:(MTLPrimitiveType)primitiveType indirectBuffer:(uint64_t)indirectBuffer {
    if (s_active_vt) [s_active_vt applyAllToEncoder:self];
    if (s_active_ft) [s_active_ft applyAllToEncoder:self];
    void *ind_buf = NULL;
    uint64_t ind_off = 0;
    if (mtl_addr(indirectBuffer, 16, &ind_buf, &ind_off)) {
        if ([self respondsToSelector:@selector(drawPrimitives:indirectBuffer:indirectBufferOffset:)]) {
            [(id<MTLRenderCommandEncoder>)self drawPrimitives:primitiveType indirectBuffer:(__bridge id<MTLBuffer>)ind_buf indirectBufferOffset:ind_off];
        }
    }
}
- (void)drawIndexedPrimitives:(MTLPrimitiveType)primitiveType indexCount:(NSUInteger)indexCount indexType:(MTLIndexType)indexType indexBuffer:(uint64_t)indexBuffer indexBufferLength:(NSUInteger)indexBufferLength instanceCount:(NSUInteger)instanceCount baseVertex:(NSInteger)baseVertex baseInstance:(NSUInteger)baseInstance {
    if (s_active_vt) [s_active_vt applyAllToEncoder:self];
    if (s_active_ft) [s_active_ft applyAllToEncoder:self];
    void *buf = NULL;
    uint64_t off = 0;
    if (mtl_addr(indexBuffer, indexBufferLength, &buf, &off)) {
        if ([self respondsToSelector:@selector(drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:baseVertex:baseInstance:)]) {
            [(id<MTLRenderCommandEncoder>)self drawIndexedPrimitives:primitiveType indexCount:indexCount indexType:indexType indexBuffer:(__bridge id<MTLBuffer>)buf indexBufferOffset:off instanceCount:instanceCount baseVertex:baseVertex baseInstance:baseInstance];
        }
    }
}
- (void)drawIndexedPrimitives:(MTLPrimitiveType)primitiveType indexType:(MTLIndexType)indexType indexBuffer:(uint64_t)indexBuffer indexBufferLength:(NSUInteger)indexBufferLength indirectBuffer:(uint64_t)indirectBuffer {
    if (s_active_vt) [s_active_vt applyAllToEncoder:self];
    if (s_active_ft) [s_active_ft applyAllToEncoder:self];
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

@interface MTL4DummySafetyTarget : NSObject
+ (instancetype)sharedTarget;
@end

@implementation MTL4DummySafetyTarget
+ (instancetype)sharedTarget {
    static MTL4DummySafetyTarget *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [MTL4DummySafetyTarget new]; });
    return s;
}

static id dummy_safety_method(id self, SEL _cmd) {
    (void)self; (void)_cmd;
    return nil;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    class_addMethod([self class], sel, (IMP)dummy_safety_method, "@@:");
    return YES;
}
@end

static id (*orig_forwardingTargetForSelector)(id self, SEL _cmd, SEL sel);
static id safe_forwardingTargetForSelector(id self, SEL _cmd, SEL sel) {
    if (orig_forwardingTargetForSelector) {
        id target = orig_forwardingTargetForSelector(self, _cmd, sel);
        if (target) return target;
    }
    const char *name = object_getClassName(self);
    if (name && (strncmp(name, "AGX", 3) == 0 || strncmp(name, "_MTL", 4) == 0 || strncmp(name, "IOGPU", 5) == 0)) {
        NSLog(@"[mtl4_compat] Handled unrecognized selector -[%s %s] safely", name, sel_getName(sel));
        return [MTL4DummySafetyTarget sharedTarget];
    }
    return nil;
}

static void (*orig_addResidencySet)(id self, SEL _cmd, id set);
static void safe_addResidencySet(id self, SEL _cmd, id set) {
    if (!set) return;
    if (orig_addResidencySet) {
        orig_addResidencySet(self, _cmd, set);
    }
}

static void (*orig_endEncoding)(id self, SEL _cmd);
static void safe_endEncoding(id self, SEL _cmd) {
    [DmCompatArgumentTable notifyEncoderEnded:self];
    if (orig_endEncoding) {
        orig_endEncoding(self, _cmd);
    }
}

__attribute__((constructor))
static void hook_metal_compat(void) {
    Class cls = NSClassFromString(@"_MTLCommandQueue");
    if (cls) {
        Method m = class_getInstanceMethod(cls, @selector(addResidencySet:));
        if (m) {
            orig_addResidencySet = (void (*)(id, SEL, id))method_getImplementation(m);
            method_setImplementation(m, (IMP)safe_addResidencySet);
        }
    }
    Class encCls = NSClassFromString(@"_MTLCommandEncoder");
    if (encCls) {
        Method em = class_getInstanceMethod(encCls, @selector(endEncoding));
        if (em) {
            orig_endEncoding = (void (*)(id, SEL))method_getImplementation(em);
            method_setImplementation(em, (IMP)safe_endEncoding);
        }
    }
    Method fm = class_getInstanceMethod([NSObject class], @selector(forwardingTargetForSelector:));
    if (fm) {
        orig_forwardingTargetForSelector = (id (*)(id, SEL, SEL))method_getImplementation(fm);
        method_setImplementation(fm, (IMP)safe_forwardingTargetForSelector);
    }
}
