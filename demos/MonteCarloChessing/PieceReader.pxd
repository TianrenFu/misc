# python 3.5 Anaconda 4.1

# import os
# import re
# from pprint import pprint


cdef class Piece:
    cpdef public str name, class_name, type, package, rarity, passive, promotion
    cpdef public int cost, tier, not_blocking
    cpdef public list action

    cpdef new_matrix(cls, size=?)

    cpdef duplicate_matrix(cls, model)


cdef class PieceReader:
    cpdef public list pieces
    cpdef public object files

    cpdef get_file_list(self, root)

    cpdef read_file(self, filename)

    cpdef link_promotions(self, pieces)

    cpdef read_actions(cls, piece, description)

    cpdef resolve_lable(sttc, ch)

    cpdef name_plus_tier(self, name, tier)

    cpdef is_piece_calculatable(self, piece)
