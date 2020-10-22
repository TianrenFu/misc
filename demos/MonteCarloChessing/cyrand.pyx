# cython: python 3.5
from cyrand cimport *

cpdef srand():
    # cdef unsigned int _current_time = time(<time_t *> 0)
    stdsrand(<int> time(<time_t *> 0))
srand()

cdef int randint(int irange):
    """return an integral in [0, range), or (range, 0] if range is negative"""
    if irange == 0:
        return 0
    elif irange < 0:
        return randint(-irange)
    cdef int rsd = RAND_MAX % irange
    cdef ri = rand()
    while RAND_MAX - ri <= rsd:
        ri = rand()
    return ri % irange


# test
print('RAND_MAX = %d' % (RAND_MAX,))