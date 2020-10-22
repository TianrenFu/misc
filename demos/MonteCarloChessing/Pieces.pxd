# cython: python 3.5
from cython.operator cimport dereference as deref, preincrement as inc, address as addr
from header cimport *

cdef vector[Piece] piece_list
cdef map[string, int] piece_index

cdef int index_of_King

# cpdef int random_piece(int be_minion=?, int be_champion=?)