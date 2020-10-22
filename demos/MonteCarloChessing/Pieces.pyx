# cython: python 3.5
from cython.operator cimport dereference as deref, preincrement as inc, address as addr
from Pieces cimport *

cdef vector[Piece] piece_list
build_piece_list(piece_list)
# todo: add special pieces

link_effects(piece_list)

cdef map[string, int] piece_index
build_piece_index(piece_index, piece_list)


cdef int index_of_King = piece_index[b'King']

# cpdef int random_piece(int be_minion=0, int be_champion=0):
#     if be_minion and be_champion:
#         return 0
#     cdef int num = randint(piece_list.size())
#     cdef Piece* p = addr(piece_list[num])
#     while (p.name == b'') or (be_minion and not p.minion) or (be_champion and not p.champion):
#         num = randint(piece_list.size())
#         p = addr(piece_list[num])
#     return num

cdef Piece import_piece(object py_piece):
    cdef Piece piece
    piece.name = py_piece.name.encode()
    piece.cost = py_piece.cost
    piece.promotion = 0
    piece.minion = 1 if py_piece.type == 'Minion' else 0
    piece.champion = 1 if py_piece.type == 'Champion' else 0
    piece.not_blocking = py_piece.not_blocking
    piece.map = py_piece.action  # auto conversion from [[int,],] to int2d
    piece.augmented = 0; piece.augmented_actno = 0; piece.augmented_check=null_augmented
    piece.has_on_death = 0; piece.on_death = null_effect
    piece.has_on_kill = 0; piece.on_kill = null_effect
    return piece



#region cdef void build_piece_list(vector[Piece]& piece_vec, str folder)
cdef void build_piece_list(vector[Piece]& piece_vec, str folder='PieceLib'):
    cdef PieceReader reader = PieceReader(folder)
    cdef int i, j
    cdef str pr, s
    piece_vec.clear()
    piece_vec.push_back(import_piece(pyPiece()))
    for i in range(len(reader.pieces)):
        piece_vec.push_back(import_piece(reader.pieces[i]))
        if reader.pieces[i].promotion != '':
            pr = reader.pieces[i].promotion
            for j in range(len(reader.pieces)):
                if reader.pieces[j].name == pr:
                    piece_vec[i + 1].promotion = j + 1
                    break
    for i in range(1, piece_vec.size()):
        s = '[#%d] %s' % (i, piece_vec[i].name.decode())
        if 0 < piece_vec[i].promotion < piece_vec.size():
            s += ' (promotes to [#%d] %s)' % (piece_vec[i].promotion, piece_vec[piece_vec[i].promotion].name.decode())
        print(s)
#endregion


cdef void build_piece_index(map[string, int]& index_map, vector[Piece]& piece_vec):
    cdef string name
    for i in range(piece_vec.size()):
        name = piece_vec[i].name
        if name != b'':
            index_map[name] = i

cdef void apped_special_pieces(vector[Piece]& piece_vec):
    cdef list special_pieces = [
        'Sapling,,,Common;1:(Status-Immune),',
        'Tree,,,Common;4:(Status-Immune),',
    ]


#######################
#region EFFECTS
cdef void null_effect(Board& board, int xfrom, int yfrom, int xto, int yto):
    pass

cdef void King_on_death(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xto][yto]] -= 25
    board.king[board.ownerships[xto][yto]] -= 1

cdef void Aquarius_on_death(Board& board, int xfrom, int yfrom, int xto, int yto):  # ofrom is enemy to Aquarius' owner
    cdef int dx, dy, nx, ny, nnx, nny
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            if dx == 0 and dy == 0: continue
            nx = xto + dx; ny = yto + dy
            if on_the_board(nx, ny):
                if board.pieces[nx][ny] and board.ownerships[nx][ny] == board.ownerships[xfrom][yfrom]:
                    if board.frozen[nx][ny] < 2:
                        board.frozen[nx][ny] = 2
                    nnx = nx + dx; nny = ny + dy
                    if on_the_board(nnx, nny):
                        if board.pieces[nnx][nny] == 0:
                            move_to(board, nx, ny, nnx, nny)

cdef void Comet_on_death(Board& board, int xfrom, int yfrom, int xto, int yto):  # ofrom is enemy to Comet's owner
    cdef int x, y, actno
    cdef int ocomet = enemy_player(board.ownerships[xfrom][yfrom])
    cdef int pcomet = board.pieces[xfrom][yfrom] if (xfrom == xto and yfrom == yto) else board.pieces[xto][yto]  # only way to reveal pcomet
    for x in range(BOARD_SIZE):
        for y in range(BOARD_SIZE):
            if ocomet == 1:
                actno = piece_list[pcomet].map[x - xto + CENTRAL_POSITION][y - yto + CENTRAL_POSITION]
            else:
                actno = piece_list[pcomet].map[xto - x + CENTRAL_POSITION][yto - y + CENTRAL_POSITION]
            if actno == 36 and board.ownerships[x][y] != ocomet and piece_list[board.pieces[x][y]].minion:
                if board.frozen[x][y] < 6:
                    board.frozen[x][y] = 6


#region from/to_lose_X_moral & steal_X_moral
cdef void to_lose_2_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xto][yto]] -= 2

cdef void to_lose_3_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xto][yto]] -= 3

cdef void to_lose_4_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xto][yto]] -= 4

cdef void to_lose_5_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xto][yto]] -= 5

cdef void to_lose_8_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xto][yto]] -= 8

cdef void to_lose_12_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xto][yto]] -= 12

cdef void to_lose_16_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xto][yto]] -= 16

cdef void from_lose_4_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xfrom][yfrom]] -= 4

cdef void steal_2_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xfrom][yfrom]] += 2
    board.moral[board.ownerships[xto][yto]] -= 2

cdef void steal_3_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xfrom][yfrom]] += 3
    board.moral[board.ownerships[xto][yto]] -= 3

cdef void steal_4_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xfrom][yfrom]] += 4
    board.moral[board.ownerships[xto][yto]] -= 4

cdef void steal_5_moral(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xfrom][yfrom]] += 5
    board.moral[board.ownerships[xto][yto]] -= 5
#endregion

#endregion
#######################


#######################
#region AUGMENTED CHECK FUNCTIONS
cdef int null_augmented(Board& board, int xfrom, int yfrom, int xto, int yto):
    return 0

cdef int RoyalGuard_augmented(Board& board, int xfrom, int yfrom, int xto, int yto):
    if board.pieces[xto][yto]:
        return 0
    cdef int ofrom = board.ownerships[xfrom][yfrom]
    cdef int dx, dy, nx, ny
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            nx, ny = xto + dx, yto + dy
            if nx < 0 or nx >= BOARD_SIZE or ny < 0 or ny >= BOARD_SIZE:
                continue
            if board.pieces[nx][ny] == index_of_King and board.ownerships[nx][ny] == ofrom:
                return 1
    return 0

cdef int Comet_augmented(Board& board, int xfrom, int yfrom, int xto, int yto):
    return board.ownerships[xfrom][yfrom] != board.ownerships[xto][yto] and piece_list[board.pieces[xto][yto]].champion

#endregion
#######################

cdef void link_effects(vector[Piece]& piece_vec):
    cdef int i
    cdef str name
    for i in range(piece_vec.size()):
        name = piece_vec[i].name.decode()
        if name == 'King': piece_vec[i].has_on_death = 1; piece_list[i].on_death = King_on_death
        elif name == 'Greed': piece_vec[i].has_on_death = 1; piece_list[i].on_death = to_lose_4_moral
        elif name == 'Greed+': piece_vec[i].has_on_death = 1; piece_list[i].on_death = to_lose_8_moral
        elif name == 'Greed++': piece_vec[i].has_on_death = 1; piece_list[i].on_death = to_lose_12_moral
        elif name == 'Greed+++': piece_vec[i].has_on_death = 1; piece_list[i].on_death = to_lose_16_moral
        elif name == 'Militia': piece_vec[i].has_on_death = 1; piece_list[i].on_death = to_lose_2_moral
        elif name == 'Militia+': piece_vec[i].has_on_death = 1; piece_list[i].on_death = to_lose_3_moral
        elif name == 'Militia++': piece_vec[i].has_on_death = 1; piece_list[i].on_death = to_lose_4_moral
        elif name == 'Militia+++': piece_vec[i].has_on_death = 1; piece_list[i].on_death = to_lose_5_moral
        elif name == 'Vampire': piece_vec[i].has_on_kill = 1; piece_list[i].on_kill = steal_2_moral
        elif name == 'Vampire+': piece_vec[i].has_on_kill = 1; piece_list[i].on_kill = steal_3_moral
        elif name == 'Vampire++': piece_vec[i].has_on_kill = 1; piece_list[i].on_kill = steal_4_moral
        elif name == 'Vampire+++': piece_vec[i].has_on_kill = 1; piece_list[i].on_kill = steal_5_moral

        elif 'Reaver' in name: piece_vec[i].has_on_kill = 1; piece_list[i].on_kill = from_lose_4_moral
        elif 'RoyalGuard' in name: piece_vec[i].augmented = 1; piece_vec[i].augmented_actno = 6; piece_vec[i].augmented_check = RoyalGuard_augmented
        elif 'Aquarius' in name: piece_vec[i].has_on_death = 1; piece_list[i].on_death = Aquarius_on_death
        elif 'Comet' in name:
            piece_vec[i].augmented = 1; piece_vec[i].augmented_actno = 37; piece_vec[i].augmented_check = Comet_augmented
            piece_vec[i].has_on_death = 1; piece_list[i].on_death = Comet_on_death