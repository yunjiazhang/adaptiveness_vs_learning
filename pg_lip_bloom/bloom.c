/*
 *  Copyright (c) 2012-2019, Jyri J. Virkki
 *  All rights reserved.
 *
 *  This file is under BSD license. See LICENSE file.
 */

/*
 * Refer to bloom.h for documentation on the public interfaces.
 */
#include <setjmp.h>

#include "postgres.h"
#include <string.h>
#include "fmgr.h"
#include "utils/geo_decls.h"
#include <assert.h>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include "bloom.h"
#include "murmur2/murmurhash2.h"
#include <sys/mman.h>
#include <stdio.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <pthread.h>

#define MAKESTRING(n) STRING(n)
#define STRING(n) #n
#define NTHREADS 4
#define parallel_global_step 2

// struct bloom_probe_kit* parallel_probe_kit = NULL;
struct bloom* parallel_global_bloom = NULL; 
int parallel_global_len = -1;
const void * parallel_global_buffer = NULL;
int parallel_global_end_points[NTHREADS] = {0};
int parallel_global_returns[NTHREADS] = {-1};
// int parallel_global_step = 0;

struct bloom * create_shared_bloom_ptr(key_t key){
    int shmid; // = shmget(key, sizeof(struct bloom *), IPC_CREAT | 0666);
    struct bloom * mem;
    // shmid = shmget(key, sizeof(struct bloom *), IPC_CREAT | 0666);
    if ((shmid = shmget(key + BLOOM_PTR_SHARED_KEY_OFFSET, sizeof(struct bloom *), IPC_CREAT | IPC_EXCL | 0666)) < 0) {
        elog(NOTICE, "shared mem exist, trying to destroy the previous ones: %d", shmid);
        int temp_semid = shmget(key + BLOOM_PTR_SHARED_KEY_OFFSET, sizeof(struct bloom *), 0666);
        shmctl(temp_semid, 0, IPC_RMID);
        shmid = shmget(key + BLOOM_PTR_SHARED_KEY_OFFSET, sizeof(struct bloom *), IPC_CREAT | IPC_EXCL | 0666);
        if (shmid < 0) {
            elog(NOTICE, "bloom not created right, %d", shmid);
            perror("shmget");
            exit(1); 
        }
    }
    /*
     * Now we attach the segment to our data space.
     */
    mem = shmat(shmid, NULL, 0);
    if ((mem = shmat(shmid, NULL, 0)) == (char *) -1) {
        
        elog(NOTICE, "create error shmat, %d", shmid);
        perror("shmat");
        exit(1);
    }
    mem = memset(mem, 0, sizeof(struct bloom *));
    elog(NOTICE, "created at, %p", mem);
    return mem;
}

struct bloom * get_shared_bloom_ptr(key_t key){
    int shmid; // = shmget(key, sizeof(struct bloom *), IPC_CREAT | 0666);
    struct bloom * mem;
    // shmid = shmget(key, sizeof(struct bloom *), 0666);
    if ((shmid = shmget(key + BLOOM_PTR_SHARED_KEY_OFFSET, sizeof(struct bloom *), 0666)) < 0) {
        elog(NOTICE, "get_shared_bloom_ptr get err: shmget, %d", shmid);
        perror("shmget");
        exit(1);
    }
    /*
     * Now we attach the segment to our data space.
     */
    // mem = shmat(shmid, NULL, 0);
    if ((mem = shmat(shmid, NULL, 0)) == (char *) -1) {
        elog(NOTICE, "shmat, %d", shmid);
        perror("shmat");
        exit(1);
    }
    // mem->bf = get_bf_data_space(key, mem->bytes);
    // elog(NOTICE, "get at (k=%d, shmid=%d, %p) with add_count=%d", key, shmid, mem, mem->add_count);
    return mem;
}


unsigned char * create_bf_data_space(key_t key, int size){
    int shmid; // = shmget(key, sizeof(struct bloom *), IPC_CREAT | 0666);
    unsigned char * mem;
    // shmid = shmget(key, sizeof(struct bloom *), IPC_CREAT | 0666);
    if ((shmid = shmget(key + BLOOM_DATA_SHARED_KEY_OFFSET, size, IPC_CREAT | IPC_EXCL | 0666)) < 0) {
        elog(NOTICE, "shared mem exist, trying to destroy the previous ones: %d", shmid);
        int temp_semid = shmget(key + BLOOM_DATA_SHARED_KEY_OFFSET, size, 0666);
        shmctl(temp_semid, 0, IPC_RMID);
        shmid = shmget(key + BLOOM_DATA_SHARED_KEY_OFFSET, size, IPC_CREAT | IPC_EXCL | 0666);
        if (shmid < 0) {
            elog(NOTICE, "bloom not created right, %d", shmid);
            perror("shmget");
            exit(1); 
        }
    }
    /*
     * Now we attach the segment to our data space.
     */
    mem = shmat(shmid, NULL, 0);
    if ((mem = shmat(shmid, NULL, 0)) == (char *) -1) {
        elog(NOTICE, "create error shmat, %d", shmid);
        perror("shmat");
        exit(1);
    }
    mem = memset(mem, 0, size);
    elog(NOTICE, "created bf_data_space with, key=%d, shmid=%d, ptr=%p", key, shmid, mem);
    return mem;
}

unsigned char * get_bf_data_space(key_t key, int size){
    int shmid; // = shmget(key, sizeof(struct bloom *), IPC_CREAT | 0666);
    unsigned char * mem;
    // shmid = shmget(key, sizeof(struct bloom *), 0666);
    if ((shmid = shmget(key + BLOOM_DATA_SHARED_KEY_OFFSET, size, 0666)) < 0) {
        elog(NOTICE, "get_bf_data_space with, key=%d", key + BLOOM_DATA_SHARED_KEY_OFFSET);
        elog(NOTICE, "get_bf_data_space get err: shmget, %d", shmid);
        perror("shmget");
        exit(1);
    }
    /*
     * Now we attach the segment to our data space.
     */
    // mem = shmat(shmid, NULL, 0);
    if ((mem = shmat(shmid, NULL, 0)) == (char *) -1) {
        elog(NOTICE, "shmat, %d", shmid);
        perror("shmat");
        exit(1);
    }
    return mem;
}

inline static int test_bit_set_bit(unsigned char * buf,
                                   unsigned int x, int set_bit)
{
  unsigned int byte = x >> 3;
  unsigned char c = buf[byte];        // expensive memory access
  unsigned int mask = 1 << (x % 8);

  if (c & mask) {
    return 1;
  } else {
    if (set_bit) {
      buf[byte] = c | mask;
    }
    return 0;
  }
}


static int bloom_check_add(struct bloom * bloom,
                           const void * buffer, int len, int add)
{
  if (bloom->ready == 0) {
    printf("bloom at %p not initialized!\n", (void *)bloom);
    return -1;
  }

  int hits = 0;
  register unsigned int a = murmurhash2(buffer, len, 0x9747b28c);
  register unsigned int b = murmurhash2(buffer, len, a);
  register unsigned int x;
  register unsigned int i;

  for (i = 0; i < bloom->hashes; i++) {
    x = (a + i*b) % bloom->bits;
    if (test_bit_set_bit(bloom->bf, x, add)) {
      hits++;
    } else if (!add) {
      // Don't care about the presence of all the bits. Just our own.
      return 0;
    }
  }
  if (hits == bloom->hashes) {
    return 1;                // 1 == element already in (or collision)
  }
  return 0;
}

void * parallel_probe_func(void *i){
  // register int tid = *((int *) i);
  // int idx = tid * parallel_global_step;
  // elog(NOTICE, "Parallel checker: %d (from %d to %d) ", tid, idx, parallel_global_end_points[tid]);
  // elog(NOTICE, "Parallel checker %d: %p ", tid, parallel_global_bloom);
  // elog(NOTICE, "Parallel checker %d: %p ", tid, parallel_global_buffer);
  // elog(NOTICE, "Parallel checker %d: %d ", tid, parallel_global_len);
  // exit(1);
  
  // register unsigned int a = murmurhash2(parallel_global_buffer, 
  //                                       parallel_global_len, 
  //                                       0x9747b28c);
  // register unsigned int b = murmurhash2(parallel_global_buffer, 
  //                                       parallel_global_len, 
  //                                       a);
  // register unsigned int x;

  // for (; idx < parallel_global_end_points[tid]; idx++) {
  //   x = (a + idx*b) % parallel_global_bloom->bits;
  //   if (test_bit_set_bit(parallel_global_bloom->bf, x, 0)) {} 
  //   else {
  //     parallel_global_returns[tid] = 0;
  //     return NULL;
  //   }
  // }
  // parallel_global_returns[tid] = 1;

  // return NULL;
}

static int bloom_check_add_parallel(struct bloom * bloom,
                           const void * buffer, int len, int add)
{  
  // elog(NOTICE, "Starting thread %p", bloom);
  parallel_global_bloom = bloom;
  parallel_global_buffer = buffer;
  parallel_global_len = len;
  // int parallel_global_step = (1 + bloom -> hashes) / NTHREADS;
  // elog(NOTICE, "Start thread %d ", parallel_global_step);
  // exit(1);

  
  pthread_t threads[NTHREADS];
  int thread_args[NTHREADS];
  int rc;
  int i;
  
  /* spawn the threads */
  for (i=0; i<NTHREADS; ++i)
  {
      thread_args[i] = i;
      if (i == NTHREADS - 1) {
        parallel_global_end_points[i] = bloom -> hashes;
      }
      else {
        parallel_global_end_points[i] = i * parallel_global_step + parallel_global_step;
      }
      elog(NOTICE, "Start thread %d (%d to %d). ", i, thread_args[i] * parallel_global_step, parallel_global_end_points[i]);
      rc = pthread_create(&threads[i], NULL, parallel_probe_func, (void *) &thread_args[i]);
      // break;
  }

  /* wait for threads to finish */
  for (i=0; i<NTHREADS; ++i) {
      rc = pthread_join(threads[i], NULL);
      // if (parallel_global_returns[i] == 0) { return 0; }
  }
  exit(1);

  return 1;
}


int bloom_init(struct bloom * bloom, int entries, double error, key_t key)
{
  bloom->ready = 0;
  bloom->add_count = 0;
  bloom->key = key;
  bloom->probe_cnt = 0;
  bloom->prune_cnt = 0;
  bloom->total_probe_cnt = 0;

  if (entries < 1000 || error == 0) {
    return 1;
  }

  bloom->entries = entries;
  bloom->error = error;

  double num = log(bloom->error);
  double denom = 0.480453013918201; // ln(2)^2
  bloom->bpe = -(num / denom);
  // elog(NOTICE, "Before init");

  double dentries = (double)entries;
  bloom->bits = (int)(dentries * bloom->bpe);

  if (bloom->bits % 8) {
    bloom->bytes = (bloom->bits / 8) + 1;
  } else {
    bloom->bytes = bloom->bits / 8;
  }
  // elog(NOTICE, "Before init");

  bloom->hashes = (int)ceil(0.693147180559945 * bloom->bpe);  // ln(2)
  // elog(NOTICE, "Before init");

  // bloom->bf = (unsigned char *) create_bf_data_space(key, bloom->bytes * sizeof(unsigned char));

  // bloom->bf = (unsigned char *)create_shared_memory(bloom->bytes * sizeof(unsigned char));
  bloom->bf = (unsigned char *)calloc(bloom->bytes, sizeof(unsigned char));
  // use palloc rather than calloc 
  // bloom->bf = (unsigned char *)palloc(bloom->bytes * sizeof(unsigned char));
  // bloom->bf = (unsigned char *)malloc(bloom->bytes * sizeof(unsigned char));

  if (bloom->bf == NULL) {                                   // LCOV_EXCL_START
    return 1;
  }                                                          // LCOV_EXCL_STOP

  bloom->ready = 1;
  return 0;
}


int bloom_check(struct bloom * bloom, const void * buffer, int len)
{
  return bloom_check_add(bloom, buffer, len, 0);
  // return bloom_check_add_parallel(bloom, buffer, len, 0);
}


int bloom_add(struct bloom * bloom, const void * buffer, int len)
{
  bloom->add_count += 1;
  return bloom_check_add(bloom, buffer, len, 1);
  // return bloom_check_add_parallel(bloom, buffer, len, 1);

}


void bloom_print(struct bloom * bloom)
{
  printf("bloom at %p\n", (void *)bloom);
  printf(" ->entries = %d\n", bloom->entries);
  printf(" ->error = %f\n", bloom->error);
  printf(" ->bits = %d\n", bloom->bits);
  printf(" ->bits per elem = %f\n", bloom->bpe);
  printf(" ->bytes = %d\n", bloom->bytes);
  printf(" ->hash functions = %d\n", bloom->hashes);
}

struct bloom * bloom_bit_and(struct bloom * bloom1, struct bloom * bloom2)
{
  int i = 0;
  assert(bloom1->bytes == bloom2->bytes);
  for (i = 0; i < bloom1->bytes; i++){
    bloom1->bf[i] = bloom1->bf[i] & bloom2->bf[i];
  }
  return bloom1;
}

struct bloom * bloom_bit_or(struct bloom * bloom1, struct bloom * bloom2)
{
  int i = 0;
  assert(bloom1->bytes == bloom2->bytes);
  for (i = 0; i < bloom1->bytes; i++){
    bloom1->bf[i] = bloom1->bf[i] | bloom2->bf[i];
  }
  return bloom1;
}

int bloom_get_content_signature(struct bloom * bloom)
{
  int sig = 0;
  int i = 0;
  for(i=0; i<bloom->bytes;i++){
    sig += (int) bloom->bf[i];
  }
  return sig;
}



void bloom_free(struct bloom * bloom)
{
  if (bloom->ready) {
    free(bloom->bf);
  }
  bloom->ready = 0;
}


int bloom_reset(struct bloom * bloom)
{
  if (!bloom->ready) return 1;
  memset(bloom->bf, 0, bloom->bytes);
  return 0;
}


const char * bloom_version()
{
  return MAKESTRING(BLOOM_VERSION);
}


struct bloom * bloom_cpy(
  struct bloom * new_bloom, 
  unsigned char * new_bf_data, 
  struct bloom * shared_bloom,
  unsigned char * shared_bf_data){
    new_bloom -> entries = shared_bloom -> entries;
    new_bloom -> error = shared_bloom -> error;
    new_bloom -> bits = shared_bloom -> bits;
    new_bloom -> bytes = shared_bloom -> bytes;
    new_bloom -> hashes = shared_bloom -> hashes;
    new_bloom -> bpe = shared_bloom -> bpe;
    new_bloom -> ready = shared_bloom -> ready;
    new_bloom -> add_count = shared_bloom -> add_count;
    new_bloom -> key = shared_bloom -> key;

    // int i = 0;
    // for (i=0; i<MAX_BLOOM_SIZE; i++){
    //   new_bf_data[i] = shared_bf_data[i];
    //   if (new_bf_data[i] != shared_bf_data[i]) {
    //     exit(1);
    //   }
    // }
    // new_bloom -> bf = new_bf_data;
    return new_bloom;
}

struct bloom * bloom_mem_cpy(
  void * target, 
  void * source, int size){
    unsigned char * target_b = (unsigned char *) target;
    unsigned char * source_b = (unsigned char *) source;
    for (int i=0; i<size; i++){
      target_b[i] = source_b[i];
    }
    return (void *) target_b;

    // int i = 0;
    // for (i=0; i<MAX_BLOOM_SIZE; i++){
    //   new_bf_data[i] = shared_bf_data[i];
    //   if (new_bf_data[i] != shared_bf_data[i]) {
    //     exit(1);
    //   }
    // }
    // new_bloom -> bf = new_bf_data;
}
