# cython: python 3.5
from header cimport *

cdef vector[Action] actions

cdef int can_target(Board& board, int xfrom, int yfrom, int xto, int yto, int actno)

cdef void null_function(Board& board, int xfrom, int yfrom, int xto, int yto)

cdef void move_to(Board& board, int xfrom, int yfrom, int xto, int yto)

cdef void destroy(Board& board, int xfrom, int yfrom, int xto, int yto)