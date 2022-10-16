#include "postgres.h"
#include <string.h>
#include "fmgr.h"
#include "utils/geo_decls.h"
#include "bloom.h"
#include "funcapi.h"
#include <assert.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/syscall.h>


int DYNAMIC = 1;
int DYNMIAC_DETECT_FREQ = 1000;
struct bloom* bl_ptrs[MAX_BLOOM_FILTERS] = { NULL };
int bloom_disabled_flag[MAX_BLOOM_FILTERS] = { -1 };
int bloom_cnters[MAX_BLOOM_FILTERS];
int n_bloom_used = 0;
int shared_mem_location = 0;


PG_MODULE_MAGIC;

// PG_FUNCTION_INFO_V1(_PG_init);
void
_PG_init(void)
{
    return;
}

// PG_FUNCTION_INFO_V1(pg_lip_bloom_make_shared);
// Datum
void pg_lip_bloom_make_shared()
{
    int i;
    struct bloom * new_shared_blm;
    struct bloom * local_blm;
    unsigned char * new_shared_blm_bf_data;
    for (i = 0; i < n_bloom_used; i++){
        local_blm = bl_ptrs[i];
        new_shared_blm = create_shared_bloom_ptr(i);
        memcpy(new_shared_blm, local_blm, sizeof(struct bloom));

        new_shared_blm_bf_data = create_bf_data_space(i, local_blm->bytes);
        memcpy(new_shared_blm_bf_data, local_blm->bf, local_blm->bytes);
        
        elog(NOTICE, "Bloom #%d made shared with signature: %d. (bytes=%d)", i, 
                bloom_get_content_signature(local_blm), local_blm->bytes);
    }
    // PG_RETURN_INT32(0);
}

void pg_lip_bloom_make_local(int idx){
    // elog(NOTICE, "Making local: %d", idx);
    struct bloom * new_bloom = (struct bloom*) malloc(sizeof(struct bloom));
    // unsigned char * new_bf_data = (unsigned char *)calloc(MAX_BLOOM_SIZE, sizeof(unsigned char));
    // elog(NOTICE, "Making local: %d", idx);
    
    struct bloom * shared_bloom = get_shared_bloom_ptr(idx);
    unsigned char * shared_bf_data = get_bf_data_space(idx, shared_bloom->bytes);
    // elog(NOTICE, "Making local: %d", idx);
    
    // memcpy(new_bloom, shared_bloom, sizeof(struct bloom));
    // memcpy(new_bf_data, shared_bf_data, MAX_BLOOM_SIZE);
    
    new_bloom = bloom_cpy(
            new_bloom, 
            NULL, 
            shared_bloom,
            shared_bf_data);
    // elog(NOTICE, "Making local: %d", idx);
    
    // new_bloom -> bf = new_bf_data;
    bl_ptrs[idx] = new_bloom;
    bl_ptrs[idx] -> bf = shared_bf_data;
    
    bl_ptrs[idx] -> probe_cnt = 0;
    bl_ptrs[idx] -> prune_cnt = 0;
    if (DYNAMIC == 1){
        bloom_disabled_flag[idx] = -1;
    }
    else{
        bloom_disabled_flag[idx] = 1;
    }
    // elog(NOTICE, "Making local: %d", idx);
    // elog(NOTICE, "[PID: %d] Make local bloom: (idx=%d, count=%d)", getpid(), idx, new_bloom->add_count);
    // elog(NOTICE, "[PID: %d] Make local bloom: (ptr=%p, bytes=%d, shared_bytes=%d)", getpid(), shared_bf_data, new_bloom->bytes, shared_bloom->bytes);
    // elog(NOTICE, "[PID: %d] Make local bloom: (idx=%d, count=%d)", getpid(), idx, new_bloom->add_count);
    elog(NOTICE, "[PID: %d] Make local bloom: (idx=%d, count=%d, sig=%d)", getpid(), idx, new_bloom->add_count, bloom_get_content_signature(new_bloom));
    // exit(1);
}

PG_FUNCTION_INFO_V1(pg_lip_bloom_set_dynamic);
Datum
pg_lip_bloom_set_dynamic(PG_FUNCTION_ARGS)
{
    int set_dynmiac = PG_GETARG_INT32(0);
    DYNAMIC = set_dynmiac;
    PG_RETURN_INT32(0);
}

PG_FUNCTION_INFO_V1(pg_lip_bloom_init);
Datum
pg_lip_bloom_init(PG_FUNCTION_ARGS)
{
    int n_bloom = PG_GETARG_INT32(0);
    if (n_bloom <= 0){
        n_bloom_used = MAX_BLOOM_FILTERS;
    } else {
        n_bloom_used = n_bloom;
    }
    struct bloom * new_bloom;
    int i;
    for (i = 0; i < MAX_BLOOM_FILTERS; i++){
        if (i < n_bloom_used ){
            new_bloom = (struct bloom*) malloc(sizeof(struct bloom));
            // new_bloom = create_shared_memory(sizeof(struct bloom));
            // new_bloom = create_shared_bloom_ptr(i);
            bloom_init(new_bloom, MAX_BLOOM_SIZE, 0.00001, i);
            bl_ptrs[i] = new_bloom;
            bloom_cnters[i] = 0;
            if (DYNAMIC == 1){
                bloom_disabled_flag[i] = -1;
            }
            else{
                bloom_disabled_flag[i] = 1;
            }
            elog(NOTICE, "Bloom #%d initilized at: %p", i, new_bloom);
        } else {
            bl_ptrs[i] = NULL;
            bloom_cnters[i] = 0;
            bloom_disabled_flag[i] = -1;
        }
    }

    pg_lip_bloom_make_shared();
    for (i = 0; i < n_bloom_used; i++){
        pg_lip_bloom_make_local(i);
    }
    PG_RETURN_INT32(0);
}

// the non parallel version of building
// PG_FUNCTION_INFO_V1(pg_lip_bloom_add);
// Datum
// pg_lip_bloom_add(PG_FUNCTION_ARGS)
// {
//     int bl_idx = PG_GETARG_INT32(0);
//     int32 val = PG_GETARG_INT32(1);
//     struct bloom *bloom_ptr;
//     bloom_ptr = bl_ptrs[bl_idx];
    
//     // elog(NOTICE, "Bloom adding at: %p", bloom_ptr);
//     int ret = bloom_add(bloom_ptr, &val, sizeof(int32));
//     bloom_cnters[bl_idx] += 1;
//     PG_RETURN_INT32(ret);
// }

// the parallel version of building
PG_FUNCTION_INFO_V1(pg_lip_bloom_add);
Datum
pg_lip_bloom_add(PG_FUNCTION_ARGS)
{
    int bl_idx = PG_GETARG_INT32(0);
    int32 val = PG_GETARG_INT32(1);
    struct bloom *bloom_ptr;
    
    if ( bl_ptrs[bl_idx] == NULL ){
        pg_lip_bloom_make_local(bl_idx);
    }

    bloom_ptr = bl_ptrs[bl_idx];    
    
    // elog(NOTICE, "Bloom adding at: %p", bloom_ptr);
    int ret = bloom_add(bloom_ptr, &val, sizeof(int32));
    // elog(NOTICE, "[PID: %d] Current bloom: (sig=%d)", getpid(), bloom_get_content_signature(bloom_ptr));
    bloom_cnters[bl_idx] += 1;
    PG_RETURN_INT32(ret);
}

PG_FUNCTION_INFO_V1(pg_lip_bloom_probe);
Datum
pg_lip_bloom_probe(PG_FUNCTION_ARGS)
{
    int bl_idx = PG_GETARG_INT32(0);
    int32 val = PG_GETARG_INT32(1);
    bool ret;

    // if (bloom_disabled_flag[bl_idx]==0) {
    //     PG_RETURN_BOOL(true); 
    // }
    if (bl_ptrs[bl_idx] == NULL) {
        pg_lip_bloom_make_local(bl_idx);
    }

    if (bloom_disabled_flag[bl_idx]==-1) {
        struct bloom *bloom_ptr  = bl_ptrs[bl_idx];
        bloom_ptr -> probe_cnt += 1;
        ret = bloom_check(bloom_ptr, &val, sizeof(int32));
        if (ret == false){
            bloom_ptr -> prune_cnt += 1;
        }
        if (bloom_ptr -> probe_cnt >= DYNMIAC_DETECT_FREQ){
            if (bloom_ptr -> prune_cnt < DYNMIAC_DETECT_FREQ / 10){
                bloom_disabled_flag[bl_idx] = 0;
                bloom_ptr -> stale_timer = DYNMIAC_DETECT_FREQ * 10;
                // elog(NOTICE, "Bloom filter #%d is disabled. Pruned: [%.2f] percent ", bl_idx, 100 * ((float)(bloom_ptr->prune_cnt) / bloom_ptr -> probe_cnt));
            }
            else {
                bloom_disabled_flag[bl_idx] = 1;
                bloom_ptr -> stale_timer = DYNMIAC_DETECT_FREQ * 10;
                // elog(NOTICE, "Bloom filter #%d is enabled. Pruned: [%.2f] percent ", bl_idx, 100 * ((float)(bloom_ptr->prune_cnt) / bloom_ptr -> probe_cnt));
            }
        }
    }
    else if (bloom_disabled_flag[bl_idx]==1) {
        ret = bloom_check(bl_ptrs[bl_idx], &val, sizeof(int32));
        if (DYNAMIC == 2){
            bl_ptrs[bl_idx] -> stale_timer -= 1;
            if( bl_ptrs[bl_idx] -> stale_timer <= 0){
                bloom_disabled_flag[bl_idx] = -1;
            }
        }
        else if (DYNAMIC == 0) {
            bl_ptrs[bl_idx] -> probe_cnt += 1;
            if (ret == false){
                bl_ptrs[bl_idx] -> prune_cnt += 1;
            }
        }
    }
    else if (bloom_disabled_flag[bl_idx]==0) {
        if (DYNAMIC == 2 ){
            bl_ptrs[bl_idx] -> stale_timer -= 1;
            if( bl_ptrs[bl_idx] -> stale_timer <= 0){
                bloom_disabled_flag[bl_idx] = -1;
            }
        }
        ret = true;
    }

    PG_RETURN_BOOL(ret);
}

PG_FUNCTION_INFO_V1(pg_lip_bloom_info);
Datum
pg_lip_bloom_info(PG_FUNCTION_ARGS)
{
    elog(NOTICE, "Current DYNAMIC setting: %d]", DYNAMIC) ;
    int i;
    for (i = 0; i < n_bloom_used; i++){
        elog(NOTICE, "Bloom #%d at %p with %d elements added. [SIG: %d] [Filtered: %.4f]",   i, 
                                                                                    bl_ptrs[i], 
                                                                                    bloom_cnters[i], 
                                                                                    bloom_get_content_signature(bl_ptrs[i]),
                                                                                    ((float)(bl_ptrs[i]->prune_cnt) / (float)(bl_ptrs[i] -> probe_cnt)));
        pg_lip_bloom_make_local(i);
        
        elog(NOTICE, "Bloom #%d at %p with %d elements added. [SIG: %d] [Filtered: %.4f]",   i, 
                                                                                    bl_ptrs[i], 
                                                                                    bloom_cnters[i], 
                                                                                    bloom_get_content_signature(bl_ptrs[i]),
                                                                                    ((float)(bl_ptrs[i]->prune_cnt) / (float)(bl_ptrs[i] -> probe_cnt)));
        // elog(NOTICE, "%d, %d", (bl_ptrs[i]->prune_cnt), (bl_ptrs[i]->probe_cnt));
    }
    PG_RETURN_INT32(0);
}

PG_FUNCTION_INFO_V1(pg_lip_bloom_free);
Datum
pg_lip_bloom_free(PG_FUNCTION_ARGS)
{
    int i;
    for (i = 0; i < n_bloom_used; i++){
        elog(NOTICE, "Releasing spaces of bloom filters %p, %p.", bl_ptrs[i], bl_ptrs[i]->bf);
        bloom_free(bl_ptrs[i]);
        elog(NOTICE, "Bloom #%d freed.", i);
    }
    PG_RETURN_INT32(0);
}

PG_FUNCTION_INFO_V1(pg_lip_bloom_bit_and);
Datum
pg_lip_bloom_bit_and(PG_FUNCTION_ARGS)
{
    int bl_idx_target = PG_GETARG_INT32(0);
    int bl_idx1 = PG_GETARG_INT32(1);
    int bl_idx2 = PG_GETARG_INT32(2);
    pg_lip_bloom_make_local(bl_idx1);
    pg_lip_bloom_make_local(bl_idx2);
    bl_ptrs[bl_idx_target] = bloom_bit_and(bl_ptrs[bl_idx1], bl_ptrs[bl_idx2]);
    // pg_lip_bloom_make_shared();
    PG_RETURN_INT32(0);
}

PG_FUNCTION_INFO_V1(pg_lip_bloom_func_call_overhead_test);
Datum
pg_lip_bloom_func_call_overhead_test(PG_FUNCTION_ARGS)
{
    PG_RETURN_BOOL(true); 
}


// PG_FUNCTION_INFO_V1(pg_lip_bloom_config_dynamic);
// Datum
// pg_lip_bloom_config_dynamic(PG_FUNCTION_ARGS)
// {
//     int d = PG_GETARG_INT32(0);
//     DYNAMIC = d;
//     PG_RETURN_INT32(0);
// }
