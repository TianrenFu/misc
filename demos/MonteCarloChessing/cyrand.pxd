# cython: python 3.5

from libc.stdlib cimport srand as stdsrand, rand, RAND_MAX
from libc.time cimport time_t, time

cpdef srand()

cdef inline float random():
    return <float> rand() / <float> (RAND_MAX + 1)

cdef int randint(int)

cdef inline int randi(int irange):  # faster version for randint, works for range > 0, fragile
    return rand() % irange

cdef inline float randf(float frange):
    return <float> rand() / <float> (RAND_MAX + 1) * frange
