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
    if (!device) return NO;
    if ([MTLFXSpatialScalerDescriptor respondsToSelector:@selector(supportsDevice:)]) {
        return [MTLFXSpatialScalerDescriptor supportsDevice:device];
    }
    return YES;
}
- (id)newSpatialScalerWithDevice:(id)device compiler:(id)compiler {
    (void)compiler;
    if ([self respondsToSelector:@selector(newSpatialScalerWithDevice:)]) {
        return [self newSpatialScalerWithDevice:device];
    }
    return nil;
}
@end

@implementation MTLFXTemporalScalerDescriptor (Metal4Compat)
+ (BOOL)supportsMetal4FX:(id<MTLDevice>)device {
    if (!device) return NO;
    if ([MTLFXTemporalScalerDescriptor respondsToSelector:@selector(supportsDevice:)]) {
        return [MTLFXTemporalScalerDescriptor supportsDevice:device];
    }
    return YES;
}
- (id)newTemporalScalerWithDevice:(id)device compiler:(id)compiler {
    (void)compiler;
    if ([self respondsToSelector:@selector(newTemporalScalerWithDevice:)]) {
        return [self newTemporalScalerWithDevice:device];
    }
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

static os_unfair_lock s_tex_lock = OS_UNFAIR_LOCK_INIT;
static os_unfair_lock s_samp_lock = OS_UNFAIR_LOCK_INIT;
static NSMapTable *s_rid_textures = nil;
static NSMapTable *s_rid_samplers = nil;

void mtl_register_texture(id<MTLTexture> tex) {
    if (!tex) return;
    uint64_t rid = tex.gpuResourceID._impl;
    if (!rid) return;
    @autoreleasepool {
        os_unfair_lock_lock(&s_tex_lock);
        if (!s_rid_textures) s_rid_textures = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality valueOptions:NSPointerFunctionsWeakMemory];
        [s_rid_textures setObject:tex forKey:(__bridge id)(void *)(uintptr_t)rid];
        os_unfair_lock_unlock(&s_tex_lock);
    }
}

void mtl_register_sampler(id<MTLSamplerState> samp) {
    if (!samp) return;
    uint64_t rid = samp.gpuResourceID._impl;
    if (!rid) return;
    @autoreleasepool {
        os_unfair_lock_lock(&s_samp_lock);
        if (!s_rid_samplers) s_rid_samplers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality valueOptions:NSPointerFunctionsWeakMemory];
        [s_rid_samplers setObject:samp forKey:(__bridge id)(void *)(uintptr_t)rid];
        os_unfair_lock_unlock(&s_samp_lock);
    }
}

id<MTLTexture> mtl_lookup_texture(uint64_t rid) {
    if (!rid) return nil;
    id<MTLTexture> tex = nil;
    @autoreleasepool {
        os_unfair_lock_lock(&s_tex_lock);
        tex = s_rid_textures ? [s_rid_textures objectForKey:(__bridge id)(void *)(uintptr_t)rid] : nil;
        os_unfair_lock_unlock(&s_tex_lock);
    }
    return tex;
}

id<MTLSamplerState> mtl_lookup_sampler(uint64_t rid) {
    if (!rid) return nil;
    id<MTLSamplerState> samp = nil;
    @autoreleasepool {
        os_unfair_lock_lock(&s_samp_lock);
        samp = s_rid_samplers ? [s_rid_samplers objectForKey:(__bridge id)(void *)(uintptr_t)rid] : nil;
        os_unfair_lock_unlock(&s_samp_lock);
    }
    return samp;
}

static __unsafe_unretained DmCompatArgumentTable *s_all_tables[64];
static int s_all_tables_count = 0;
static os_unfair_lock s_tables_lock = OS_UNFAIR_LOCK_INIT;

// Thread-local active tables: prevents nvn-present / DisplayLink from stomping dm-encode / replay tables
static __thread __unsafe_unretained DmCompatArgumentTable *s_active_vt = nil;
static __thread __unsafe_unretained DmCompatArgumentTable *s_active_ft = nil;
static __thread __unsafe_unretained DmCompatArgumentTable *s_active_ct = nil;

@implementation DmCompatArgumentTable {
    uint64_t _addresses[32];
    id<MTLBuffer> _buffers[32];
    NSUInteger _offsets[32];
    uint32_t _valid_mask;
    uint32_t _dirty_mask;
    id<MTLTexture> _textures[32];
    uint32_t _texture_valid_mask;
    uint32_t _texture_dirty_mask;
    id<MTLSamplerState> _samplers[32];
    uint32_t _sampler_valid_mask;
    uint32_t _sampler_dirty_mask;
    __unsafe_unretained id _encoder;
    MTLRenderStages _render_stages;
    BOOL _is_compute;
}

- (instancetype)init {
    if ((self = [super init])) {
        id<MTLBuffer> db = mtl_dummy_buf();
        id<MTLTexture> dt = mtl_dummy_tex(0, 0);
        id<MTLSamplerState> ds = mtl_dummy_samp();
        for (int i = 0; i < 32; i++) {
            _buffers[i] = db;
            _offsets[i] = 0;
            _textures[i] = dt;
            _samplers[i] = ds;
        }
        _valid_mask = 0xffffffffu;
        _texture_valid_mask = 0xffffffffu;
        _sampler_valid_mask = 0xffffffffu;
        _dirty_mask = 0xffffffffu;
        _texture_dirty_mask = 0xffffffffu;
        _sampler_dirty_mask = 0xffffffffu;
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

static char kCompatVtKey;
static char kCompatFtKey;
static char kCompatCtKey;

+ (void)ensureArgsForEncoder:(id)encoder {
    if (!encoder) return;
    if ([encoder respondsToSelector:@selector(setVertexTexture:atIndex:)]) {
        DmCompatArgumentTable *vt = objc_getAssociatedObject(encoder, &kCompatVtKey);
        DmCompatArgumentTable *ft = objc_getAssociatedObject(encoder, &kCompatFtKey);
        if (!vt) vt = s_active_vt;
        if (!ft) ft = s_active_ft;
        if (vt) {
            if (vt->_encoder == encoder && !vt->_dirty_mask && !vt->_texture_dirty_mask && !vt->_sampler_dirty_mask) {
                // fast path: already bound and clean
            } else {
                [vt applyDirtyToEncoder:encoder];
            }
        }
        if (ft) {
            if (ft->_encoder == encoder && !ft->_dirty_mask && !ft->_texture_dirty_mask && !ft->_sampler_dirty_mask) {
                // fast path: already bound and clean
            } else {
                [ft applyDirtyToEncoder:encoder];
            }
        }
    } else {
        DmCompatArgumentTable *ct = objc_getAssociatedObject(encoder, &kCompatCtKey);
        if (!ct) ct = s_active_ct;
        if (ct) {
            if (ct->_encoder == encoder && !ct->_dirty_mask && !ct->_texture_dirty_mask && !ct->_sampler_dirty_mask) {
                // fast path: already bound and clean
            } else {
                [ct applyDirtyToEncoder:encoder];
            }
        }
    }
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
    if (index >= 32) return;
    id enc = _encoder;
    if (!enc) return;
    if (!(_valid_mask & (1u << index))) return;
    id<MTLBuffer> buf = _buffers[index] ? _buffers[index] : mtl_dummy_buf();
    NSUInteger off = _offsets[index];
    if (!buf) buf = mtl_dummy_buf();
    if (buf) {
        if (off >= buf.length) off = 0;
        off &= ~3u;
    }
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
    _dirty_mask &= ~(1u << index);
}

- (void)applyTextureToIndex:(NSUInteger)index {
    if (index >= 32) return;
    id enc = _encoder;
    if (!enc) return;
    if (!(_texture_valid_mask & (1u << index))) return;
    id<MTLTexture> tex = _textures[index] ? _textures[index] : mtl_dummy_tex(0, 0);
    if (!tex) return;
    if (_is_compute) {
        if ([enc conformsToProtocol:@protocol(MTLComputeCommandEncoder)]) {
            [(id<MTLComputeCommandEncoder>)enc setTexture:tex atIndex:index];
        }
    } else {
        if ((_render_stages & MTLRenderStageVertex) && [enc respondsToSelector:@selector(setVertexTexture:atIndex:)]) {
            [(id<MTLRenderCommandEncoder>)enc setVertexTexture:tex atIndex:index];
        }
        if ((_render_stages & MTLRenderStageFragment) && [enc respondsToSelector:@selector(setFragmentTexture:atIndex:)]) {
            [(id<MTLRenderCommandEncoder>)enc setFragmentTexture:tex atIndex:index];
        }
    }
    _texture_dirty_mask &= ~(1u << index);
}

- (void)applySamplerToIndex:(NSUInteger)index {
    if (index >= 32) return;
    id enc = _encoder;
    if (!enc) return;
    if (!(_sampler_valid_mask & (1u << index))) return;
    id<MTLSamplerState> samp = _samplers[index] ? _samplers[index] : mtl_dummy_samp();
    if (!samp) return;
    if (_is_compute) {
        if ([enc respondsToSelector:@selector(setSamplerState:atIndex:)]) {
            [(id<MTLComputeCommandEncoder>)enc setSamplerState:samp atIndex:index];
        }
    } else {
        if ((_render_stages & MTLRenderStageVertex) && [enc respondsToSelector:@selector(setVertexSamplerState:atIndex:)]) {
            [(id<MTLRenderCommandEncoder>)enc setVertexSamplerState:samp atIndex:index];
        }
        if ((_render_stages & MTLRenderStageFragment) && [enc respondsToSelector:@selector(setFragmentSamplerState:atIndex:)]) {
            [(id<MTLRenderCommandEncoder>)enc setFragmentSamplerState:samp atIndex:index];
        }
    }
    _sampler_dirty_mask &= ~(1u << index);
}

- (void)applyAllToEncoder:(id)encoder {
    if (!encoder) return;
    _encoder = encoder;
    _dirty_mask = 0;
    _texture_dirty_mask = 0;
    _sampler_dirty_mask = 0;
    id<MTLBuffer> d = mtl_dummy_buf();
    for (NSUInteger i = 0; i < 32; i++) {
        if (_valid_mask & (1u << i)) {
            id<MTLBuffer> buf = _buffers[i] ? _buffers[i] : d;
            NSUInteger off = _offsets[i];
            if (!buf) buf = d;
            if (buf) {
                if (off >= buf.length) off = 0;
                off &= ~3u;
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
        if (_texture_valid_mask & (1u << i)) {
            id<MTLTexture> tex = _textures[i] ? _textures[i] : mtl_dummy_tex(0, 0);
            if (tex) {
                if (_is_compute) {
                    if ([encoder conformsToProtocol:@protocol(MTLComputeCommandEncoder)]) {
                        [(id<MTLComputeCommandEncoder>)encoder setTexture:tex atIndex:i];
                    }
                } else {
                    if ((_render_stages & MTLRenderStageVertex) && [encoder respondsToSelector:@selector(setVertexTexture:atIndex:)]) {
                        [(id<MTLRenderCommandEncoder>)encoder setVertexTexture:tex atIndex:i];
                    }
                    if ((_render_stages & MTLRenderStageFragment) && [encoder respondsToSelector:@selector(setFragmentTexture:atIndex:)]) {
                        [(id<MTLRenderCommandEncoder>)encoder setFragmentTexture:tex atIndex:i];
                    }
                }
            }
        }
        if (_sampler_valid_mask & (1u << i)) {
            id<MTLSamplerState> samp = _samplers[i] ? _samplers[i] : mtl_dummy_samp();
            if (samp) {
                if (_is_compute) {
                    if ([encoder respondsToSelector:@selector(setSamplerState:atIndex:)]) {
                        [(id<MTLComputeCommandEncoder>)encoder setSamplerState:samp atIndex:i];
                    }
                } else {
                    if ((_render_stages & MTLRenderStageVertex) && [encoder respondsToSelector:@selector(setVertexSamplerState:atIndex:)]) {
                        [(id<MTLRenderCommandEncoder>)encoder setVertexSamplerState:samp atIndex:i];
                    }
                    if ((_render_stages & MTLRenderStageFragment) && [encoder respondsToSelector:@selector(setFragmentSamplerState:atIndex:)]) {
                        [(id<MTLRenderCommandEncoder>)encoder setFragmentSamplerState:samp atIndex:i];
                    }
                }
            }
        }
    }
}

- (void)applyDirtyToEncoder:(id)encoder {
    if (!encoder) return;
    if (_encoder != encoder) {
        [self applyAllToEncoder:encoder];
        return;
    }
    if (_dirty_mask) {
        uint32_t mask = _dirty_mask;
        _dirty_mask = 0;
        id<MTLBuffer> d = mtl_dummy_buf();
        for (NSUInteger i = 0; i < 32; i++) {
            if (mask & (1u << i)) {
                if (_valid_mask & (1u << i)) {
                    id<MTLBuffer> buf = _buffers[i] ? _buffers[i] : d;
                    NSUInteger off = _offsets[i];
                    if (!buf) buf = d;
                    if (buf) {
                        if (off >= buf.length) off = 0;
                        off &= ~3u;
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
    }
    if (_texture_dirty_mask) {
        uint32_t mask = _texture_dirty_mask;
        _texture_dirty_mask = 0;
        for (NSUInteger i = 0; i < 32; i++) {
            if (mask & (1u << i)) {
                if (_texture_valid_mask & (1u << i)) {
                    id<MTLTexture> tex = _textures[i] ? _textures[i] : mtl_dummy_tex(0, 0);
                    if (tex) {
                        if (_is_compute) {
                            if ([encoder conformsToProtocol:@protocol(MTLComputeCommandEncoder)]) {
                                [(id<MTLComputeCommandEncoder>)encoder setTexture:tex atIndex:i];
                            }
                        } else {
                            if ((_render_stages & MTLRenderStageVertex) && [encoder respondsToSelector:@selector(setVertexTexture:atIndex:)]) {
                                [(id<MTLRenderCommandEncoder>)encoder setVertexTexture:tex atIndex:i];
                            }
                            if ((_render_stages & MTLRenderStageFragment) && [encoder respondsToSelector:@selector(setFragmentTexture:atIndex:)]) {
                                [(id<MTLRenderCommandEncoder>)encoder setFragmentTexture:tex atIndex:i];
                            }
                        }
                    }
                }
            }
        }
    }
    if (_sampler_dirty_mask) {
        uint32_t mask = _sampler_dirty_mask;
        _sampler_dirty_mask = 0;
        for (NSUInteger i = 0; i < 32; i++) {
            if (mask & (1u << i)) {
                if (_sampler_valid_mask & (1u << i)) {
                    id<MTLSamplerState> samp = _samplers[i] ? _samplers[i] : mtl_dummy_samp();
                    if (samp) {
                        if (_is_compute) {
                            if ([encoder respondsToSelector:@selector(setSamplerState:atIndex:)]) {
                                [(id<MTLComputeCommandEncoder>)encoder setSamplerState:samp atIndex:i];
                            }
                        } else {
                            if ((_render_stages & MTLRenderStageVertex) && [encoder respondsToSelector:@selector(setVertexSamplerState:atIndex:)]) {
                                [(id<MTLRenderCommandEncoder>)encoder setVertexSamplerState:samp atIndex:i];
                            }
                            if ((_render_stages & MTLRenderStageFragment) && [encoder respondsToSelector:@selector(setFragmentSamplerState:atIndex:)]) {
                                [(id<MTLRenderCommandEncoder>)encoder setFragmentSamplerState:samp atIndex:i];
                            }
                        }
                    }
                }
            }
        }
    }
}

- (void)setAddress:(uint64_t)address atIndex:(NSUInteger)index {
    if (index >= 32) return;
    _addresses[index] = address;
    _dirty_mask |= (1u << index);
    if (address) {
        void *b = NULL;
        uint64_t off = 0;
        if ((mtl_gpu_to_buf(address, 1, &b, &off) || mtl_addr(address, 1, &b, &off)) && b) {
            id<MTLBuffer> mbuf = (__bridge id<MTLBuffer>)b;
            if (off < mbuf.length) {
                _buffers[index] = mbuf;
                _offsets[index] = (NSUInteger)(off & ~3u);
                _valid_mask |= (1u << index);
            } else {
                id<MTLBuffer> d = mtl_dummy_buf();
                _buffers[index] = d;
                _offsets[index] = 0;
                _valid_mask |= (1u << index);
            }
        } else {
            id<MTLBuffer> d = mtl_dummy_buf();
            _buffers[index] = d;
            _offsets[index] = 0;
            _valid_mask |= (1u << index);
        }
    } else {
        _buffers[index] = mtl_dummy_buf();
        _offsets[index] = 0;
        _valid_mask |= (1u << index);
    }
    [self applyToIndex:index];
}

- (void)setTexture:(MTLResourceID)texture atIndex:(NSUInteger)index {
    if (index >= 32) return;
    id<MTLTexture> tex = nil;
    if (texture._impl) {
        tex = mtl_lookup_texture(texture._impl);
        if (!tex && texture._impl < 65536) {
            tex = mtl_lookup_texture_by_tid((uint32_t)texture._impl);
        }
    }
    if (!tex) tex = mtl_dummy_tex(0, 0);
    _textures[index] = tex;
    _texture_valid_mask |= (1u << index);
    _texture_dirty_mask |= (1u << index);
    [self applyTextureToIndex:index];
}

- (void)setSamplerState:(MTLResourceID)sampler atIndex:(NSUInteger)index {
    if (index >= 32) return;
    id<MTLSamplerState> samp = nil;
    if (sampler._impl) {
        samp = mtl_lookup_sampler(sampler._impl);
        if (!samp && sampler._impl < 65536) {
            samp = mtl_lookup_sampler_by_sid((uint32_t)sampler._impl);
        }
    }
    if (!samp) samp = mtl_dummy_samp();
    _samplers[index] = samp;
    _sampler_valid_mask |= (1u << index);
    _sampler_dirty_mask |= (1u << index);
    [self applySamplerToIndex:index];
}

- (void)bindToRenderEncoder:(id)encoder stages:(MTLRenderStages)stages {
    _encoder = encoder;
    _render_stages = stages;
    _is_compute = NO;
    if (stages & MTLRenderStageVertex) {
        s_active_vt = self;
        if (encoder) objc_setAssociatedObject(encoder, &kCompatVtKey, self, OBJC_ASSOCIATION_ASSIGN);
    }
    if (stages & MTLRenderStageFragment) {
        s_active_ft = self;
        if (encoder) objc_setAssociatedObject(encoder, &kCompatFtKey, self, OBJC_ASSOCIATION_ASSIGN);
    }
    [self applyAllToEncoder:encoder];
}

- (void)bindToComputeEncoder:(id)encoder {
    _encoder = encoder;
    _is_compute = YES;
    _render_stages = 0;
    s_active_ct = self;
    if (encoder) objc_setAssociatedObject(encoder, &kCompatCtKey, self, OBJC_ASSOCIATION_ASSIGN);
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
    (void)descriptor; (void)error;
    return [NSObject new];
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

@interface DmCbFenceTracker : NSObject {
@public
    id<MTLDevice> _dev;
    NSMutableArray<id<MTLFence>> *_fences;
    int _nextUpdateIdx;
    int _readyWaitIdx;
    BOOL _hasUpdate;
    void *_lastUpdatingEncoder;
    void *_lastWaitingEncoder;
}
- (instancetype)initWithDevice:(id<MTLDevice>)dev;
- (id<MTLFence>)allocUpdateFenceOnDevice:(id<MTLDevice>)dev;
- (id<MTLFence>)currentWaitFence;
@end

@implementation DmCbFenceTracker
- (instancetype)initWithDevice:(id<MTLDevice>)dev {
    if ((self = [super init])) {
        _dev = dev;
        _fences = [NSMutableArray arrayWithCapacity:32];
        for (int i = 0; i < 32; i++) {
            id<MTLFence> f = [dev newFence];
            if (f) [_fences addObject:f];
        }
        _nextUpdateIdx = 0;
        _readyWaitIdx = -1;
        _hasUpdate = NO;
        _lastUpdatingEncoder = NULL;
        _lastWaitingEncoder = NULL;
    }
    return self;
}

- (id<MTLFence>)allocUpdateFenceOnDevice:(id<MTLDevice>)dev {
    if (!_dev && dev) _dev = dev;
    if (_nextUpdateIdx >= (int)_fences.count) {
        id<MTLDevice> d = _dev ? _dev : dev;
        id<MTLFence> f = d ? [d newFence] : nil;
        if (f) [_fences addObject:f];
        else if (_fences.count > 0) return _fences[_fences.count - 1];
        else return nil;
    }
    int uIdx = _nextUpdateIdx++;
    _readyWaitIdx = uIdx;
    return _fences[uIdx];
}

- (id<MTLFence>)currentWaitFence {
    if (_readyWaitIdx >= 0 && _readyWaitIdx < (int)_fences.count) {
        return _fences[_readyWaitIdx];
    }
    return nil;
}
@end

static char kFenceKey;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
@implementation DmCompatComputeBlitEncoder {
    id<MTLCommandBuffer> _cb;
    id<MTLComputeCommandEncoder> _compute;
    id<MTLBlitCommandEncoder> _blit;
    id<MTLFence> _handoffFence;
    id<MTLFence> _pendingWaitFence;
    id<MTL4ArgumentTable> _argTable;
    id<MTLComputePipelineState> _pso;
    NSString *_label;
    BOOL _ended;
}

- (instancetype)initWithCommandBuffer:(id<MTLCommandBuffer>)cb {
    if ((self = [super init])) {
        _cb = cb;
        _compute = nil;
        _blit = nil;
        _handoffFence = nil;
        _pendingWaitFence = nil;
        _argTable = nil;
        _pso = nil;
        _label = nil;
        _ended = NO;
    }
    return self;
}

- (MTLDispatchType)dispatchType {
    return MTLDispatchTypeSerial;
}

- (id<MTLDevice>)device {
    return (id<MTLDevice>)_cb.device;
}

- (id<MTLCommandBuffer>)commandBuffer {
    return _cb;
}

- (NSString *)label {
    return _label;
}

- (void)setLabel:(NSString *)label {
    _label = [label copy];
    if (_compute) _compute.label = label;
    if (_blit) _blit.label = label;
}

- (void)ensureBlit {
    if (_ended) return;
    if (_blit) return;
    if (_compute) {
        if (!_handoffFence) _handoffFence = [_cb.device newFence];
        if (_handoffFence) [_compute updateFence:_handoffFence];
        [_compute endEncoding];
        _compute = nil;
    }
    _blit = [_cb blitCommandEncoder];
    if (_label) _blit.label = _label;
    if (_handoffFence) {
        [_blit waitForFence:_handoffFence];
    }
    if (_pendingWaitFence) {
        [_blit waitForFence:_pendingWaitFence];
        _pendingWaitFence = nil;
    }
}

- (void)ensureCompute {
    if (_ended) return;
    if (_compute) return;
    if (_blit) {
        if (!_handoffFence) _handoffFence = [_cb.device newFence];
        if (_handoffFence) [_blit updateFence:_handoffFence];
        [_blit endEncoding];
        _blit = nil;
    }
    _compute = [_cb computeCommandEncoder];
    if (_label) _compute.label = _label;
    if (_handoffFence) {
        [_compute waitForFence:_handoffFence];
    }
    if (_pendingWaitFence) {
        [_compute waitForFence:_pendingWaitFence];
        _pendingWaitFence = nil;
    }
    if (_pso) {
        [_compute setComputePipelineState:_pso];
    }
    if (_argTable) {
        DmCompatArgumentTable *t = unwrap_compat_table(_argTable);
        if (t) [t bindToComputeEncoder:_compute];
    }
}

- (void)setComputePipelineState:(id<MTLComputePipelineState>)state {
    _pso = state;
    if (_compute) {
        [_compute setComputePipelineState:state];
    }
}

- (void)setArgumentTable:(id<MTL4ArgumentTable>)table {
    _argTable = table;
    DmCompatArgumentTable *t = unwrap_compat_table(table);
    if (t) {
        [t bindToComputeEncoder:self];
    }
    if (_compute && t) {
        [t bindToComputeEncoder:_compute];
    }
}

- (void)setBuffer:(id<MTLBuffer>)buffer offset:(NSUInteger)offset atIndex:(NSUInteger)index {
    [self ensureCompute];
    [_compute setBuffer:buffer offset:offset atIndex:index];
}

- (void)setTexture:(id<MTLTexture>)texture atIndex:(NSUInteger)index {
    [self ensureCompute];
    [_compute setTexture:texture atIndex:index];
}

- (void)setSamplerState:(id<MTLSamplerState>)sampler atIndex:(NSUInteger)index {
    [self ensureCompute];
    [_compute setSamplerState:sampler atIndex:index];
}

- (void)dispatchThreadgroups:(MTLSize)threadgroupsPerGrid threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup {
    [self ensureCompute];
    [DmCompatArgumentTable ensureArgsForEncoder:_compute];
    [_compute dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
}

- (void)dispatchThreadgroupsWithIndirectBuffer:(id<MTLBuffer>)indirectBuffer indirectBufferOffset:(NSUInteger)indirectBufferOffset threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup {
    [self ensureCompute];
    [DmCompatArgumentTable ensureArgsForEncoder:_compute];
    [_compute dispatchThreadgroupsWithIndirectBuffer:indirectBuffer indirectBufferOffset:indirectBufferOffset threadsPerThreadgroup:threadsPerThreadgroup];
}

- (void)dispatchThreads:(MTLSize)threadsPerGrid threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup {
    [self ensureCompute];
    [DmCompatArgumentTable ensureArgsForEncoder:_compute];
    if ([_compute respondsToSelector:@selector(dispatchThreads:threadsPerThreadgroup:)]) {
        [_compute dispatchThreads:threadsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];
    }
}

- (void)dispatchThreadgroupsWithIndirectBuffer:(uint64_t)indirectBuffer threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup {
    if (!indirectBuffer) return;
    [self ensureCompute];
    [DmCompatArgumentTable ensureArgsForEncoder:_compute];
    void *ind_buf = NULL;
    uint64_t ind_off = 0;
    if ((mtl_gpu_to_buf(indirectBuffer, 12, &ind_buf, &ind_off) || mtl_addr(indirectBuffer, 12, &ind_buf, &ind_off)) && ind_buf) {
        id<MTLBuffer> mbuf = (__bridge id<MTLBuffer>)ind_buf;
        if (ind_off + 12 <= mbuf.length && (ind_off & 3) == 0) {
            [_compute dispatchThreadgroupsWithIndirectBuffer:mbuf indirectBufferOffset:ind_off threadsPerThreadgroup:threadsPerThreadgroup];
        }
    }
}

- (void)copyFromBuffer:(id<MTLBuffer>)sourceBuffer sourceOffset:(NSUInteger)sourceOffset toBuffer:(id<MTLBuffer>)destinationBuffer destinationOffset:(NSUInteger)destinationOffset size:(NSUInteger)size {
    [self ensureBlit];
    [_blit copyFromBuffer:sourceBuffer sourceOffset:sourceOffset toBuffer:destinationBuffer destinationOffset:destinationOffset size:size];
}

- (void)copyFromBuffer:(id<MTLBuffer>)sourceBuffer sourceOffset:(NSUInteger)sourceOffset sourceBytesPerRow:(NSUInteger)sourceBytesPerRow sourceBytesPerImage:(NSUInteger)sourceBytesPerImage sourceSize:(MTLSize)sourceSize toTexture:(id<MTLTexture>)destinationTexture destinationSlice:(NSUInteger)destinationSlice destinationLevel:(NSUInteger)destinationLevel destinationOrigin:(MTLOrigin)destinationOrigin {
    [self ensureBlit];
    [_blit copyFromBuffer:sourceBuffer sourceOffset:sourceOffset sourceBytesPerRow:sourceBytesPerRow sourceBytesPerImage:sourceBytesPerImage sourceSize:sourceSize toTexture:destinationTexture destinationSlice:destinationSlice destinationLevel:destinationLevel destinationOrigin:destinationOrigin];
}

- (void)copyFromBuffer:(id<MTLBuffer>)sourceBuffer sourceOffset:(NSUInteger)sourceOffset sourceBytesPerRow:(NSUInteger)sourceBytesPerRow sourceBytesPerImage:(NSUInteger)sourceBytesPerImage sourceSize:(MTLSize)sourceSize toTexture:(id<MTLTexture>)destinationTexture destinationSlice:(NSUInteger)destinationSlice destinationLevel:(NSUInteger)destinationLevel destinationOrigin:(MTLOrigin)destinationOrigin options:(NSUInteger)options {
    [self ensureBlit];
    [_blit copyFromBuffer:sourceBuffer sourceOffset:sourceOffset sourceBytesPerRow:sourceBytesPerRow sourceBytesPerImage:sourceBytesPerImage sourceSize:sourceSize toTexture:destinationTexture destinationSlice:destinationSlice destinationLevel:destinationLevel destinationOrigin:destinationOrigin options:(MTLBlitOption)options];
}

- (void)copyFromTexture:(id<MTLTexture>)sourceTexture sourceSlice:(NSUInteger)sourceSlice sourceLevel:(NSUInteger)sourceLevel sourceOrigin:(MTLOrigin)sourceOrigin sourceSize:(MTLSize)sourceSize toBuffer:(id<MTLBuffer>)destinationBuffer destinationOffset:(NSUInteger)destinationOffset destinationBytesPerRow:(NSUInteger)destinationBytesPerRow destinationBytesPerImage:(NSUInteger)destinationBytesPerImage {
    [self ensureBlit];
    [_blit copyFromTexture:sourceTexture sourceSlice:sourceSlice sourceLevel:sourceLevel sourceOrigin:sourceOrigin sourceSize:sourceSize toBuffer:destinationBuffer destinationOffset:destinationOffset destinationBytesPerRow:destinationBytesPerRow destinationBytesPerImage:destinationBytesPerImage];
}

- (void)copyFromTexture:(id<MTLTexture>)sourceTexture sourceSlice:(NSUInteger)sourceSlice sourceLevel:(NSUInteger)sourceLevel sourceOrigin:(MTLOrigin)sourceOrigin sourceSize:(MTLSize)sourceSize toBuffer:(id<MTLBuffer>)destinationBuffer destinationOffset:(NSUInteger)destinationOffset destinationBytesPerRow:(NSUInteger)destinationBytesPerRow destinationBytesPerImage:(NSUInteger)destinationBytesPerImage options:(NSUInteger)options {
    [self ensureBlit];
    [_blit copyFromTexture:sourceTexture sourceSlice:sourceSlice sourceLevel:sourceLevel sourceOrigin:sourceOrigin sourceSize:sourceSize toBuffer:destinationBuffer destinationOffset:destinationOffset destinationBytesPerRow:destinationBytesPerRow destinationBytesPerImage:destinationBytesPerImage options:(MTLBlitOption)options];
}

- (void)copyFromTexture:(id<MTLTexture>)sourceTexture sourceSlice:(NSUInteger)sourceSlice sourceLevel:(NSUInteger)sourceLevel sourceOrigin:(MTLOrigin)sourceOrigin sourceSize:(MTLSize)sourceSize toTexture:(id<MTLTexture>)destinationTexture destinationSlice:(NSUInteger)destinationSlice destinationLevel:(NSUInteger)destinationLevel destinationOrigin:(MTLOrigin)destinationOrigin {
    [self ensureBlit];
    [_blit copyFromTexture:sourceTexture sourceSlice:sourceSlice sourceLevel:sourceLevel sourceOrigin:sourceOrigin sourceSize:sourceSize toTexture:destinationTexture destinationSlice:destinationSlice destinationLevel:destinationLevel destinationOrigin:destinationOrigin];
}

- (void)fillBuffer:(id<MTLBuffer>)buffer range:(NSRange)range value:(uint8_t)value {
    [self ensureBlit];
    [_blit fillBuffer:buffer range:range value:value];
}

- (void)generateMipmapsForTexture:(id<MTLTexture>)texture {
    [self ensureBlit];
    [_blit generateMipmapsForTexture:texture];
}

- (void)barrierAfterStages:(NSUInteger)after beforeQueueStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis {
    (void)after; (void)before; (void)vis;
    if (_ended) return;
    DmCbFenceTracker *tracker = objc_getAssociatedObject(_cb, &kFenceKey);
    if (!tracker && [_cb respondsToSelector:@selector(device)]) {
        id dev = [_cb device];
        if (dev) {
            tracker = [[DmCbFenceTracker alloc] initWithDevice:dev];
            if (tracker) {
                objc_setAssociatedObject(_cb, &kFenceKey, tracker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    if (!tracker) return;
    if (tracker->_hasUpdate && tracker->_lastUpdatingEncoder == (__bridge void *)self) return;

    id dev = [_cb respondsToSelector:@selector(device)] ? [_cb device] : nil;
    id<MTLFence> f = [tracker allocUpdateFenceOnDevice:dev];
    if (f) {
        if (_compute) {
            [_compute updateFence:f];
        } else if (_blit) {
            [_blit updateFence:f];
        } else {
            return;
        }
        tracker->_hasUpdate = YES;
        tracker->_lastUpdatingEncoder = (__bridge void *)self;
        tracker->_lastWaitingEncoder = NULL;
    }
}

- (void)barrierAfterQueueStages:(NSUInteger)after beforeStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis {
    (void)after; (void)before; (void)vis;
    if (_ended) return;
    DmCbFenceTracker *tracker = objc_getAssociatedObject(_cb, &kFenceKey);
    if (!tracker || !tracker->_hasUpdate) return;
    if (tracker->_lastUpdatingEncoder == (__bridge void *)self) return;
    if (tracker->_lastWaitingEncoder == (__bridge void *)self) return;

    id<MTLFence> f = [tracker currentWaitFence];
    if (f) {
        if (_compute) {
            [_compute waitForFence:f];
        } else if (_blit) {
            [_blit waitForFence:f];
        } else {
            _pendingWaitFence = f;
        }
        tracker->_lastWaitingEncoder = (__bridge void *)self;
    }
}

- (void)barrierAfterEncoderStages:(NSUInteger)after beforeEncoderStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis {
    (void)vis;
    if (_compute && [_compute respondsToSelector:@selector(memoryBarrierWithScope:)]) {
        [_compute memoryBarrierWithScope:MTLBarrierScopeBuffers | MTLBarrierScopeTextures];
    }
}

- (void)writeTimestampWithGranularity:(NSUInteger)granularity intoHeap:(id)heap atIndex:(NSUInteger)index {
    (void)granularity; (void)heap; (void)index;
}

- (void)endEncoding {
    if (_ended) return;
    _ended = YES;
    if (_compute) {
        [_compute endEncoding];
        _compute = nil;
    }
    if (_blit) {
        [_blit endEncoding];
        _blit = nil;
    }
    [DmCompatArgumentTable notifyEncoderEnded:self];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    [self ensureCompute];
    return _compute;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) return YES;
    struct objc_method_description desc = protocol_getMethodDescription(@protocol(MTLComputeCommandEncoder), aSelector, YES, YES);
    if (desc.name != NULL) return YES;
    desc = protocol_getMethodDescription(@protocol(MTLComputeCommandEncoder), aSelector, NO, YES);
    if (desc.name != NULL) return YES;
    desc = protocol_getMethodDescription(@protocol(MTLBlitCommandEncoder), aSelector, YES, YES);
    if (desc.name != NULL) return YES;
    desc = protocol_getMethodDescription(@protocol(MTLBlitCommandEncoder), aSelector, NO, YES);
    if (desc.name != NULL) return YES;
    return NO;
}

@end
#pragma clang diagnostic pop

@implementation NSObject (MTL4CompatObject)
- (void)beginCommandBufferWithAllocator:(id)allocator { (void)allocator; }
- (void)endCommandBuffer {}

- (void)barrierAfterStages:(NSUInteger)after beforeQueueStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis {
    (void)after; (void)before; (void)vis;
    id cb = [self respondsToSelector:@selector(commandBuffer)] ? [(id)self commandBuffer] : nil;
    if (!cb) return;
    DmCbFenceTracker *tracker = objc_getAssociatedObject(cb, &kFenceKey);
    if (!tracker && [cb respondsToSelector:@selector(device)]) {
        id dev = [cb device];
        if (dev) {
            tracker = [[DmCbFenceTracker alloc] initWithDevice:dev];
            if (tracker) {
                objc_setAssociatedObject(cb, &kFenceKey, tracker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    if (!tracker) return;
    if (tracker->_hasUpdate && tracker->_lastUpdatingEncoder == (__bridge void *)self) return;
    
    id dev = [cb respondsToSelector:@selector(device)] ? [cb device] : nil;
    id<MTLFence> f = [tracker allocUpdateFenceOnDevice:dev];
    if (f) {
        if ([self respondsToSelector:@selector(updateFence:afterStages:)]) {
            [(id<MTLRenderCommandEncoder>)self updateFence:f afterStages:MTLRenderStageFragment];
        } else if ([self respondsToSelector:@selector(updateFence:)]) {
            [(id<MTLComputeCommandEncoder>)self updateFence:f];
        } else {
            return;
        }
        tracker->_hasUpdate = YES;
        tracker->_lastUpdatingEncoder = (__bridge void *)self;
        tracker->_lastWaitingEncoder = NULL;
    }
}
- (void)barrierAfterEncoderStages:(NSUInteger)after beforeEncoderStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis {
    (void)vis;
    if ([self respondsToSelector:@selector(memoryBarrierWithScope:afterStages:beforeStages:)]) {
        [(id<MTLRenderCommandEncoder>)self memoryBarrierWithScope:MTLBarrierScopeBuffers | MTLBarrierScopeTextures afterStages:MTLRenderStageFragment beforeStages:MTLRenderStageVertex];
    } else if ([self respondsToSelector:@selector(memoryBarrierWithScope:)]) {
        [(id<MTLComputeCommandEncoder>)self memoryBarrierWithScope:MTLBarrierScopeBuffers | MTLBarrierScopeTextures];
    }
}
- (void)barrierAfterQueueStages:(NSUInteger)after beforeStages:(NSUInteger)before visibilityOptions:(NSUInteger)vis {
    (void)after; (void)before; (void)vis;
    id cb = [self respondsToSelector:@selector(commandBuffer)] ? [(id)self commandBuffer] : nil;
    if (!cb) return;
    DmCbFenceTracker *tracker = objc_getAssociatedObject(cb, &kFenceKey);
    if (!tracker || !tracker->_hasUpdate || tracker->_readyWaitIdx < 0) return;
    if (tracker->_lastUpdatingEncoder == (__bridge void *)self) return;
    if (tracker->_lastWaitingEncoder == (__bridge void *)self) return;
    
    id<MTLFence> f = [tracker currentWaitFence];
    if (f) {
        if ([self respondsToSelector:@selector(waitForFence:beforeStages:)]) {
            [(id<MTLRenderCommandEncoder>)self waitForFence:f beforeStages:MTLRenderStageVertex | MTLRenderStageFragment];
        } else if ([self respondsToSelector:@selector(waitForFence:)]) {
            [(id<MTLComputeCommandEncoder>)self waitForFence:f];
        } else {
            return;
        }
        tracker->_lastWaitingEncoder = (__bridge void *)self;
    }
}
- (void)setArgumentTable:(id)table {
    DmCompatArgumentTable *t = unwrap_compat_table(table);
    if (t) [t bindToComputeEncoder:self];
}
- (void)setArgumentTable:(id)table atStages:(MTLRenderStages)stages {
    DmCompatArgumentTable *t = unwrap_compat_table(table);
    if (t) [t bindToRenderEncoder:self stages:stages];
}
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
        if (i + 1 == count && handlers.count > 0 && [b respondsToSelector:@selector(addCompletedHandler:)]) {
            dispatched = YES;
            [b addCompletedHandler:^(id<MTLCommandBuffer> cb) {
                @autoreleasepool {
                    MTL4CommitFeedbackImpl *f = [MTL4CommitFeedbackImpl new];
                    f.error = cb.error;
                    f.GPUStartTime = cb.GPUStartTime;
                    f.GPUEndTime = cb.GPUEndTime;
                    for (void (^h)(id<MTL4CommitFeedback>) in handlers) {
                        h(f);
                    }
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

- (void)signalEvent:(id)event value:(uint64_t)value {
    if (!event) return;
    if ([self respondsToSelector:@selector(commandBuffer)]) {
        @autoreleasepool {
            id<MTLCommandBuffer> cb = [(id<MTLCommandQueue>)self commandBuffer];
            if (cb) {
                [cb encodeSignalEvent:(id<MTLEvent>)event value:value];
                [cb commit];
                return;
            }
        }
    }
    if ([event respondsToSelector:@selector(setSignaledValue:)]) {
        ((id<MTLSharedEvent>)event).signaledValue = value;
    }
}
- (void)waitForEvent:(id)event value:(uint64_t)value {
    if (!event || ![self respondsToSelector:@selector(commandBuffer)]) return;
    @autoreleasepool {
        id<MTLCommandBuffer> cb = [(id<MTLCommandQueue>)self commandBuffer];
        if (cb) {
            [cb encodeWaitForEvent:(id<MTLEvent>)event value:value];
            [cb commit];
        }
    }
}
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
- (void)dispatchThreadgroupsWithIndirectBuffer:(uint64_t)indirectBuffer threadsPerThreadgroup:(MTLSize)threadsPerThreadgroup {
    if (!indirectBuffer) return;
    [DmCompatArgumentTable ensureArgsForEncoder:self];
    void *ind_buf = NULL;
    uint64_t ind_off = 0;
    if ((mtl_gpu_to_buf(indirectBuffer, 12, &ind_buf, &ind_off) || mtl_addr(indirectBuffer, 12, &ind_buf, &ind_off)) && ind_buf) {
        id<MTLBuffer> mbuf = (__bridge id<MTLBuffer>)ind_buf;
        if (ind_off + 12 <= mbuf.length && (ind_off & 3) == 0) {
            if ([self respondsToSelector:@selector(dispatchThreadgroupsWithIndirectBuffer:indirectBufferOffset:threadsPerThreadgroup:)]) {
                [(id<MTLComputeCommandEncoder>)self dispatchThreadgroupsWithIndirectBuffer:mbuf indirectBufferOffset:ind_off threadsPerThreadgroup:threadsPerThreadgroup];
            }
        }
    }
}
- (void)drawPrimitives:(MTLPrimitiveType)primitiveType indirectBuffer:(uint64_t)indirectBuffer {
    if (!indirectBuffer) return;
    [DmCompatArgumentTable ensureArgsForEncoder:self];
    void *ind_buf = NULL;
    uint64_t ind_off = 0;
    if ((mtl_gpu_to_buf(indirectBuffer, 16, &ind_buf, &ind_off) || mtl_addr(indirectBuffer, 16, &ind_buf, &ind_off)) && ind_buf) {
        id<MTLBuffer> mbuf = (__bridge id<MTLBuffer>)ind_buf;
        if (ind_off + 16 <= mbuf.length && (ind_off & 3) == 0) {
            if ([self respondsToSelector:@selector(drawPrimitives:indirectBuffer:indirectBufferOffset:)]) {
                [(id<MTLRenderCommandEncoder>)self drawPrimitives:primitiveType indirectBuffer:mbuf indirectBufferOffset:ind_off];
            }
        }
    }
}
- (void)drawIndexedPrimitives:(MTLPrimitiveType)primitiveType indexCount:(NSUInteger)indexCount indexType:(MTLIndexType)indexType indexBuffer:(uint64_t)indexBuffer indexBufferLength:(NSUInteger)indexBufferLength instanceCount:(NSUInteger)instanceCount baseVertex:(NSInteger)baseVertex baseInstance:(NSUInteger)baseInstance {
    if (!indexCount || !indexBuffer || !indexBufferLength || !instanceCount) return;
    [DmCompatArgumentTable ensureArgsForEncoder:self];
    void *buf = NULL;
    uint64_t off = 0;
    NSUInteger isz = (indexType == MTLIndexTypeUInt16 ? 2 : 4);
    NSUInteger min_len = indexCount * isz;
    if ((mtl_gpu_to_buf(indexBuffer, indexBufferLength, &buf, &off) || mtl_gpu_to_buf(indexBuffer, min_len, &buf, &off) || mtl_addr(indexBuffer, indexBufferLength, &buf, &off) || mtl_addr(indexBuffer, min_len, &buf, &off)) && buf) {
        id<MTLBuffer> mbuf = (__bridge id<MTLBuffer>)buf;
        if ((off % isz) == 0 && off + min_len <= mbuf.length) {
            if ([self respondsToSelector:@selector(drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:instanceCount:baseVertex:baseInstance:)]) {
                [(id<MTLRenderCommandEncoder>)self drawIndexedPrimitives:primitiveType indexCount:indexCount indexType:indexType indexBuffer:mbuf indexBufferOffset:off instanceCount:instanceCount baseVertex:baseVertex baseInstance:baseInstance];
            }
        }
    }
}
- (void)drawIndexedPrimitives:(MTLPrimitiveType)primitiveType indexType:(MTLIndexType)indexType indexBuffer:(uint64_t)indexBuffer indexBufferLength:(NSUInteger)indexBufferLength indirectBuffer:(uint64_t)indirectBuffer {
    if (!indexBuffer || !indexBufferLength || !indirectBuffer) return;
    [DmCompatArgumentTable ensureArgsForEncoder:self];
    void *ibuf = NULL, *ind_buf = NULL;
    uint64_t ioff = 0, ind_off = 0;
    NSUInteger isz = (indexType == MTLIndexTypeUInt16 ? 2 : 4);
    if ((mtl_gpu_to_buf(indexBuffer, indexBufferLength, &ibuf, &ioff) || mtl_gpu_to_buf(indexBuffer, 1, &ibuf, &ioff) || mtl_addr(indexBuffer, indexBufferLength, &ibuf, &ioff) || mtl_addr(indexBuffer, 1, &ibuf, &ioff)) && ibuf &&
        (mtl_gpu_to_buf(indirectBuffer, 20, &ind_buf, &ind_off) || mtl_addr(indirectBuffer, 20, &ind_buf, &ind_off)) && ind_buf) {
        id<MTLBuffer> mibuf = (__bridge id<MTLBuffer>)ibuf;
        id<MTLBuffer> mind_buf = (__bridge id<MTLBuffer>)ind_buf;
        if ((ioff % isz) == 0 && (ind_off & 3) == 0 && ind_off + 20 <= mind_buf.length) {
            if ([self respondsToSelector:@selector(drawIndexedPrimitives:indexType:indexBuffer:indexBufferOffset:indirectBuffer:indirectBufferOffset:)]) {
                [(id<MTLRenderCommandEncoder>)self drawIndexedPrimitives:primitiveType indexType:indexType indexBuffer:mibuf indexBufferOffset:ioff indirectBuffer:mind_buf indirectBufferOffset:ind_off];
            }
        }
    }
}
- (void)drawMeshThreadgroupsWithIndirectBuffer:(uint64_t)indirectBuffer threadsPerObjectThreadgroup:(MTLSize)threadsPerObject threadsPerMeshThreadgroup:(MTLSize)threadsPerMesh {
    if (!indirectBuffer) return;
    void *ind_buf = NULL;
    uint64_t ind_off = 0;
    if ((mtl_gpu_to_buf(indirectBuffer, 16, &ind_buf, &ind_off) || mtl_addr(indirectBuffer, 16, &ind_buf, &ind_off)) && ind_buf) {
        id<MTLBuffer> mbuf = (__bridge id<MTLBuffer>)ind_buf;
        if (ind_off + 16 <= mbuf.length && (ind_off & 3) == 0) {
            if ([self respondsToSelector:@selector(drawMeshThreadgroupsWithIndirectBuffer:indirectBufferOffset:threadsPerObjectThreadgroup:threadsPerMeshThreadgroup:)]) {
                [(id<MTLRenderCommandEncoder>)self drawMeshThreadgroupsWithIndirectBuffer:mbuf indirectBufferOffset:ind_off threadsPerObjectThreadgroup:threadsPerObject threadsPerMeshThreadgroup:threadsPerMesh];
            }
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
