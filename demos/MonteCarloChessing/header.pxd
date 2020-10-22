# cython: python 3.5

from libcpp cimport bool
from libcpp.vector cimport vector
from libcpp.map cimport map
from libcpp.utility cimport pair
from libcpp.string cimport string
from libcpp.algorithm cimport sort

from cyrand cimport srand, random, randi as randint, randf as randfloat
from PieceReader cimport PieceReader, Piece as pyPiece
from Actions cimport *
from Pieces cimport *

cdef enum:  # const variables
    BOARD_SIZE = 8
    ACTION_MAP_SIZE = 15
    CENTRAL_POSITION = 7
    MAX_VALUE = 32768
    MAX_MOVE_NUMBER = 400

ctypedef vector[vector[int]] int2d

ctypedef void (*ActionFunction)(Board&, int, int, int, int)
ctypedef int (*TargetCheckFunction)(Board&, int, int, int, int)

ctypedef struct ActionAttribute:
    int to_empty
    int to_enemy
    int to_friend
    int blockable
    int additional_limit
    TargetCheckFunction limit

ctypedef struct Action:
    int handle
    ActionFunction cast
    ActionAttribute attr
    string description

ctypedef struct Move:
    int xfrom
    int yfrom
    int xto
    int yto
    int actno

ctypedef struct Piece:
    string name
    int2d map
    int cost
    int promotion
    int minion
    int champion
    int not_blocking
    int augmented
    int augmented_actno
    TargetCheckFunction augmented_check
    # int special
    int has_on_death
    ActionFunction on_death
    int has_on_kill
    ActionFunction on_kill

ctypedef struct Board:
    int2d pieces
    int2d ownerships  # 1/2 for each player, 0 for empty
    int2d costs
    int2d frozen
    int2d poison
    int2d thunder
    int current
    int moral[3]  # [1]/[2] for each player, [0] is dummy
    int king[3]  # [1]/[2] for each player, [0] is dummy
    # int last_dead_champion[3]


#### INLINE FUNCTIONS ####

cdef inline int iabs(int x):
    return -x if x < 0 else x

cdef inline int imin(int x, int y):
    return x if x < y else y

cdef inline int imax(int x, int y):
    return x if x > y else y

cdef inline int unit(int x):
    return 1 if x > 0 else (-1 if x < 0 else 0)

cdef inline int enemy_player(int player_no):
    return 3 - player_no

cdef inline int on_the_board(int x, int y):
    return x >= 0 and x < BOARD_SIZE and y >= 0 and y < BOARD_SIZE

# from Board.pxd
cdef inline void deepcopy_int2d(int2d& to_mat, int2d& from_mat):
    cdef int i
    if to_mat.size() != from_mat.size():
        to_mat.resize(from_mat.size())
    for i in range(from_mat.size()):
        to_mat[i] = from_mat[i]

cdef inline void deepcopy_board(Board& to_board, Board& from_board):
    to_board.current = from_board.current
    deepcopy_int2d(to_board.pieces, from_board.pieces)
    deepcopy_int2d(to_board.ownerships, from_board.ownerships)
    deepcopy_int2d(to_board.costs, from_board.costs)
    deepcopy_int2d(to_board.frozen, from_board.frozen)
    deepcopy_int2d(to_board.poison, from_board.poison)
    deepcopy_int2d(to_board.thunder, from_board.thunder)
    to_board.moral[1], to_board.moral[2] = from_board.moral[1], from_board.moral[2]
    to_board.king[1], to_board.king[2] = from_board.king[1], from_board.king[2]

cdef inline void reset_board(Board& board):
    board.current = 1
    board.pieces = int2d(BOARD_SIZE, vector[int](BOARD_SIZE, 0))
    board.ownerships = int2d(BOARD_SIZE, vector[int](BOARD_SIZE, 0))
    board.costs = int2d(BOARD_SIZE, vector[int](BOARD_SIZE, 0))
    board.frozen = int2d(BOARD_SIZE, vector[int](BOARD_SIZE, 0))
    board.poison = int2d(BOARD_SIZE, vector[int](BOARD_SIZE, 0))
    board.thunder = int2d(BOARD_SIZE, vector[int](BOARD_SIZE, 0))


