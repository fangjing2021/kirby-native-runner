// A file inside a game's shader library image, <DM_MSL_DIR>/b-<chain>.img (dm/tools/shader_lib.py). The image is one flat folder in the RomFS image's format, read in place: one descriptor for the
// whole library, a binary search by name, and a mapping of only the pages a shader's file lies on, since an iPhone without extended addressing has about 6 GB of address space to share with the game.
#pragma once
#include "../../host/romfs_image.h"
#include <sys/mman.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

// A file by name in the image's root, NULL when it has none. Read only: any thread
static const img_ent *msl_image_find(const romfs_img *m, const char *name) {
    size_t len = strlen(name);
    uint64_t lo = m->e[0].a, hi = lo + m->e[0].b;
    while (lo < hi) {
        uint64_t mid = lo + (hi - lo) / 2; const img_ent *x = &m->e[mid];
        int c = memcmp(m->names + x->name, name, x->nlen < len ? x->nlen : len);
        if (!c) c = x->nlen < len ? -1 : x->nlen > len;
        if (!c) return x->type ? x : NULL;
        if (c < 0) lo = mid + 1; else hi = mid;
    }
    return NULL;
}

// The file's bytes mapped read only: data and size are the file's, base and base_len what munmap takes. 0 on failure, with errno set (an empty file maps nothing: EINVAL)
// MAP_SHARED: nothing writes through a read-only mapping, an image never changes in place (shader_lib.py publishes a new one by rename), and on a file this size a private mapping costs about 80 µs against 0.9 µs (Skyward Sword HD's 127 MB image)
typedef struct { const void *data; size_t size; void *base; size_t base_len; } msl_map;

static inline void msl_image_unmap(msl_map *m) {
    if (!m || !m->base) return;
    if (m->base_len) munmap(m->base, m->base_len);
    else free(m->base);
    memset(m, 0, sizeof *m);
}

static int msl_image_map(const romfs_img *m, const img_ent *x, msl_map *out) {
    if (!x || !x->b || !m) { errno = EINVAL; return 0; }
    // Files <= 64 KB: read directly into heap via pread, avoiding VMA/mmap exhaustion on iOS
    if (x->b <= 65536) {
        void *buf = malloc((size_t)x->b);
        if (buf) {
            size_t done = 0;
            while (done < (size_t)x->b) {
                ssize_t r = pread(m->fd, (char *)buf + done, (size_t)x->b - done, (off_t)(x->a + done));
                if (r <= 0) {
                    if (r < 0 && (errno == EAGAIN || errno == EINTR)) continue;
                    free(buf);
                    return 0;
                }
                done += (size_t)r;
            }
            out->base = buf; out->base_len = 0; out->data = buf; out->size = (size_t)x->b;
            return 1;
        }
    }
    // Files > 64 KB: attempt mmap first
    uint64_t delta = x->a % (uint64_t)getpagesize();
    void *p = mmap(NULL, (size_t)(x->b + delta), PROT_READ, MAP_SHARED, m->fd, (off_t)(x->a - delta));
    if (p != MAP_FAILED) {
        out->base = p; out->base_len = (size_t)(x->b + delta); out->data = (const char *)p + delta; out->size = (size_t)x->b;
        return 1;
    }
    // Fallback on mmap failure (ENOMEM / address space exhaustion): malloc + pread
    void *buf = malloc((size_t)x->b);
    if (!buf) return 0;
    size_t done = 0;
    while (done < (size_t)x->b) {
        ssize_t r = pread(m->fd, (char *)buf + done, (size_t)x->b - done, (off_t)(x->a + done));
        if (r <= 0) {
            if (r < 0 && (errno == EAGAIN || errno == EINTR)) continue;
            free(buf);
            return 0;
        }
        done += (size_t)r;
    }
    out->base = buf; out->base_len = 0; out->data = buf; out->size = (size_t)x->b;
    return 1;
}
