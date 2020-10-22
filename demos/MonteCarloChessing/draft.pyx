# cython: python 3.5
from cython.operator cimport dereference as deref, preincrement as inc, address as addr

from header cimport *
from pprint import pprint


# cdef vector[Piece] piece_list
# build_piece_list(piece_list)
# piece_list[1] = ['lion', [[0, 0, 0, 0, 0], [0, 1, 1, 1, 0], [0, 1, 0, 1, 0], [0, 1, 1, 1, 0], [0, 0, 0, 0, 0]], 0, 0]
# piece_list[2] = ['giraffe', [[0, 0, 0, 0, 0], [0, 0, 1, 0, 0], [0, 1, 0, 1, 0], [0, 0, 1, 0, 0], [0, 0, 0, 0, 0]], 0, 0]
# piece_list[3] = ['elephant', [[0, 0, 0, 0, 0], [0, 1, 0, 1, 0], [0, 0, 0, 0, 0], [0, 1, 0, 1, 0], [0, 0, 0, 0, 0]], 0, 0]

# test
srand()


#region cdef float evaluate_board(Board& board, int player)
cdef float evaluate_board(Board& board, int player):
    cdef float e = <float> find_possible_move_count(board, enemy_player(player))
    return <float> find_possible_move_count(board, player) / e if e != 0. else MAX_VALUE
#endregion


#region cdef void find_possible_moves(Board& board, vector[Move]& vec, int player)
cdef void find_possible_moves(Board& board, vector[Move]& vec, int player):
    cdef int xfrom, yfrom, xto, yto, actno, pfrom
    cdef Piece* piece
    vec.clear()
    for xfrom in range(BOARD_SIZE):
        for yfrom in range(BOARD_SIZE):
            if board.ownerships[xfrom][yfrom] != player:
                continue  # only current player can move pieces
            pfrom = board.pieces[xfrom][yfrom]
            if pfrom:
                piece = addr(piece_list[pfrom])
                if piece.augmented and piece.augmented_actno:
                    for xto in range(BOARD_SIZE):
                        for yto in range(BOARD_SIZE):
                            if player == 1:
                                actno = piece.map[xto - xfrom + CENTRAL_POSITION][yto - yfrom + CENTRAL_POSITION]
                            else:
                                actno = piece.map[xfrom - xto + CENTRAL_POSITION][yfrom - yto + CENTRAL_POSITION]
                            if actno and can_target(board, xfrom, yfrom, xto, yto, actno):
                                vec.push_back(Move(xfrom, yfrom, xto, yto, actno))
                            elif piece.augmented_check(board, xfrom, yfrom, xto, yto):
                                vec.push_back(Move(xfrom, yfrom, xto, yto, piece.augmented_actno))
                else:
                    for xto in range(BOARD_SIZE):
                        for yto in range(BOARD_SIZE):
                            if player == 1:
                                actno = piece.map[xto - xfrom + CENTRAL_POSITION][yto - yfrom + CENTRAL_POSITION]
                            else:
                                actno = piece.map[xfrom - xto + CENTRAL_POSITION][yfrom - yto + CENTRAL_POSITION]
                            if actno:
                                if can_target(board, xfrom, yfrom, xto, yto, actno):
                                    vec.push_back(Move(xfrom, yfrom, xto, yto, actno))
#endregion


#region cdef int find_possible_move_count(Board& board, int player)
cdef int find_possible_move_count(Board& board, int player):
    cdef vector[Move] move_vec
    find_possible_moves(board, move_vec, player)
    return move_vec.size()
    # cdef int count = 0
    # cdef int xfrom, yfrom, xto, yto, actno, pfrom
    # cdef Piece* piece
    # for xfrom in range(BOARD_SIZE):
    #     for yfrom in range(BOARD_SIZE):
    #         if board.ownerships[xfrom][yfrom] != player:
    #             continue  # only current player can move pieces
    #         pfrom = board.pieces[xfrom][yfrom]
    #         if pfrom:
    #             piece = addr(piece_list[pfrom])
    #             for xto in range(BOARD_SIZE):
    #                 for yto in range(BOARD_SIZE):
    #                     if player == 1:
    #                         actno = piece.map[xto - xfrom + CENTRAL_POSITION][yto - yfrom + CENTRAL_POSITION]
    #                     else:
    #                         actno = piece.map[xfrom - xto + CENTRAL_POSITION][yfrom - yto + CENTRAL_POSITION]
    #                     if actno:
    #                         if can_target(board, xfrom, yfrom, xto, yto, actno):
    #                             count += 1
    # return count
#endregion


#region cdef float find_best_move(Board& board, Move& move, int player)
cdef float find_best_move(Board& board, Move& move, int player):
    cdef int i, best
    cdef Move m
    cdef Board after
    cdef vector[Move] move_vec
    cdef float this_value, highest_value
    find_possible_moves(board, move_vec, player)
    if move_vec.size() < 1:
        return 1. / <float> MAX_VALUE
    best, highest_value = 0, 1. / <float> MAX_VALUE
    for i in range(move_vec.size()):
        m = move_vec[i]
        deepcopy_board(after, board)
        actions[m.actno].cast(after, m.xfrom, m.yfrom, m.xto, m.yto)
        this_value = evaluate_board(after, player)
        if this_value > highest_value:
            highest_value = this_value
            best = i
    m = move_vec[best]
    move.xfrom = m.xfrom; move.yfrom = m.yfrom
    move.xto = m.xto; move.yto = m.yto
    move.actno = m.actno
    # for xfrom in range(BOARD_SIZE):
    #     for yfrom in range(BOARD_SIZE):
    #         if board.ownerships[xfrom][yfrom] != player:
    #             continue  # only current player can move pieces
    #         pfrom = board.pieces[xfrom][yfrom]
    #         if pfrom:
    #             piece = addr(piece_list[pfrom])
    #             for xto in range(BOARD_SIZE):
    #                 for yto in range(BOARD_SIZE):
    #                     if player == 1:
    #                         actno = piece.map[xto - xfrom + CENTRAL_POSITION][yto - yfrom + CENTRAL_POSITION]
    #                     else:
    #                         actno = piece.map[xfrom - xto + CENTRAL_POSITION][yfrom - yto + CENTRAL_POSITION]
    #                     if actno:
    #                         if can_target(board, xfrom, yfrom, xto, yto, actno):
    #                             deepcopy_board(after, board)
    #                             actions[actno].cast(after, xfrom, yfrom, xto, yto)
    #                             this_value = evaluate_board(after, player)
    #                             if this_value > highest_value:
    #                                 highest_value = this_value
    #                                 move.xfrom = xfrom; move.yfrom = yfrom
    #                                 move.xto = xto; move.yto = yto
    #                                 move.actno = actno
    return highest_value if highest_value < MAX_VALUE else MAX_VALUE
#endregion


#region cdef float evaluate_move(Board& board, Move& move, int player)
cdef float evaluate_move(Board& board, Move& move, int player):
    cdef Board after
    cdef Move response
    deepcopy_board(after, board)
    actions[move.actno].cast(after, move.xfrom, move.yfrom, move.xto, move.yto)
    return 1. / find_best_move(after, response, enemy_player(player))
#endregion


#region cdef float find_good_moves(Board& board, , int player)
cdef void find_good_moves(Board& board, vector[pair[int, float]]& answer, vector[Move]& possible_moves, int player, int candidates=3):
    cdef Board after
    cdef Move move
    cdef int i
    cdef vector[pair[int, float]] temp
    answer.clear()
    for i in range(possible_moves.size()):
        move = possible_moves[i]
        deepcopy_board(after, board)
        actions[move.actno].cast(after, move.xfrom, move.yfrom, move.xto, move.yto)
        temp.push_back(pair[int, float](i, evaluate_board(board, player)))
    sort(temp.begin(), temp.end(), cmp_freq_pair_rev)
    for i in range(candidates):
        if i >= temp.size(): break
        move = possible_moves[temp[i].first]
        deepcopy_board(after, board)
        actions[move.actno].cast(after, move.xfrom, move.yfrom, move.xto, move.yto)
        answer.push_back(pair[int, float](temp[i].first, 1. / find_best_move(after, move, enemy_player(player))))

cdef bool cmp_freq_pair_rev(pair[int, float] p1, pair[int, float] p2):
    return p1.second > p2.second
#endregion


#region cdef int random_with_frequency(vector[pair[int, float]]& frequency_vec)
cdef int random_with_frequency(vector[pair[int, float]]& frequency_vec):
    cdef int i, vecsize
    cdef vector[float] s
    cdef float r
    vecsize = frequency_vec.size()
    if vecsize <= 1:
        return 0
    s.push_back(frequency_vec[0].second)
    for i in range(1, vecsize):
        s.push_back(s[i - 1] + frequency_vec[i - 1].second)
    r = randfloat(frequency_vec[vecsize - 1].second)
    i = 0
    while i < vecsize:
        if s[i] > r:
            return frequency_vec[i].first
        i += 1
    return frequency_vec[vecsize - 1].first
#endregion


#region cdef void build_board(Board& board, vector[Piece]&, str, str, str, str)
cdef void build_board(Board& board, vector[Piece]& piece_list, str player1_setup, str player2_setup):
    reset_board(board)
    cdef int x, y, line_no, i, pno
    cdef string pname
    cdef lstsz = piece_list.size()
    board.moral[1] = 0
    lines = player1_setup.split(';'); line_no = len(lines)
    setup = []
    for y in range(line_no):
        setup.append(lines[line_no - 1 - y].split(',')[0:BOARD_SIZE])
    for y in range(line_no):
        for x in range(<int> len(setup[y])):
            pname = setup[y][x].encode()
            pno = 0
            for i in range(lstsz):
                if piece_list[i].name == pname:
                    pno = i
                    break
            board.pieces[BOARD_SIZE - 1 - y][x] = pno
            if pno != 0:
                board.ownerships[BOARD_SIZE - 1 - y][x] = 1
                board.costs[BOARD_SIZE - 1 - y][x] = piece_list[pno].cost
                board.moral[1] += piece_list[pno].cost
    board.moral[2] = 0
    lines = player2_setup.split(';'); line_no = len(lines)
    setup = []
    for y in range(line_no):
        setup.append(lines[line_no - 1 - y].split(',')[0:BOARD_SIZE])
    for y in range(line_no):
        for x in range(<int> len(setup[y])):
            pname = setup[y][x].encode()
            pno = 0
            for i in range(lstsz):
                if piece_list[i].name == pname:
                    pno = i
                    break
            board.pieces[y][BOARD_SIZE - 1 - x] = pno
            if pno != 0:
                board.ownerships[y][BOARD_SIZE - 1 - x] = 2
                board.costs[y][BOARD_SIZE - 1 - x] = piece_list[pno].cost
                board.moral[2] += piece_list[pno].cost
    board.king[1], board.king[2] = 0, 0
    for x in range(BOARD_SIZE):
        for y in range(BOARD_SIZE):
            if board.pieces[x][y] == index_of_King:
                if 1 <= board.ownerships[x][y] <= 2:
                    board.king[board.ownerships[x][y]] += 1
#endregion


#region cdef void turn_pass(Board& board)
cdef void turn_pass(Board& board):
    cdef int x, y, pxy
    # todo: lure
    board.current = enemy_player(board.current)
    # todo: sumurai, sapling
    for x in range(BOARD_SIZE):
        for y in range(BOARD_SIZE):
            if board.poison[x][y] == 1 or board.thunder[x][y] == 1:
                pxy = board.pieces[x][y]
                if pxy:
                    if piece_list[pxy].has_on_death: piece_list[pxy].on_death(board, x, y, x, y)  # on death
                    board.moral[board.ownerships[x][y]] -= board.costs[x][y]
                    board.pieces[x][y] = 0
                    board.ownerships[x][y] = 0
                    board.costs[x][y] = 0
            if board.frozen[x][y] > 0: board.frozen[x][y] -= 1
            if board.poison[x][y] > 0: board.poison[x][y] -= 1
            if board.thunder[x][y] > 0: board.thunder[x][y] -= 1
    if board.king[board.current] <= 0:
            board.moral[board.current] -= 3
#endregion


#region cdef int simulate_once_with_frequency(Board& initial_board)
cdef int simulate_once_with_frequency(Board& initial_board):
    cdef Board test_board
    deepcopy_board(test_board, initial_board)
    test_board.current = randint(2) + 1

    cdef vector[Move] possible_moves
    cdef vector[pair[int, float]] frequency
    cdef Move move
    cdef int i, randno
    cdef int loser, winner, move_number

    for move_number in range(MAX_MOVE_NUMBER):
        if move_number >= 100:
            test_board.moral[test_board.current] -= 1
        if test_board.moral[test_board.current] <= 0:
            loser = test_board.current
            break
        find_possible_moves(test_board, possible_moves, test_board.current)
        if possible_moves.size() < 1:
            loser = test_board.current
            break
        find_good_moves(test_board, frequency, possible_moves, test_board.current)
        # for i in range(possible_moves.size()):
        #     frequency.push_back(evaluate_move(test_board, possible_moves[i], test_board.current))
        randno = random_with_frequency(frequency)
        # print('#%d in %d candidates.' % (randno + 1, possible_moves.size()))
        move = possible_moves[randno]
        # print('Player %d: <%s> (%d, %d) -\"%s\"-> (%d, %d)' % (test_board.current, piece_list[test_board.pieces[move.xfrom][move.yfrom]].name.decode(), move.xfrom, move.yfrom, actions[move.actno].description.decode(), move.xto, move.yto))
        actions[move.actno].cast(test_board, move.xfrom, move.yfrom, move.xto, move.yto)
        # pprint(test_board.pieces, width=45)
        # print('moral = [%d]:[%d]\n' % (test_board.moral[1], test_board.moral[2]))
        turn_pass(test_board)
    else:
        loser = randint(2) + 1

    winner = enemy_player(loser)
    return winner
#endregion


#region cdef int simulate_once(Board& initial_board)
cdef int simulate_once(Board& initial_board):
    cdef Board test_board
    deepcopy_board(test_board, initial_board)
    # test_board.pieces = [[2, 2, 2], [0, 0, 0], [3, 3, 3]]
    # test_board.ownerships = [[1, 1, 1], [0, 0, 0], [2, 2, 2]]
    test_board.current = randint(2) + 1

    cdef vector[Move] possible_moves
    cdef Move move
    cdef int loser, winner, move_number

    for move_number in range(MAX_MOVE_NUMBER):
        if move_number >= 100:
            test_board.moral[test_board.current] -= 1
        if test_board.moral[test_board.current] <= 0:
            loser = test_board.current
            break
        find_possible_moves(test_board, possible_moves, test_board.current)
        if possible_moves.size() < 1:
            # print('Player %d passes.' % (test_board.current,))
            loser = test_board.current
            break
        move = possible_moves[randint(possible_moves.size())]
        # print('Player %d: (%d, %d) --%d--> (%d, %d)' % (test_board.current, move.xfrom, move.yfrom, move.actno, move.xto, move.yto))
        actions[move.actno].cast(test_board, move.xfrom, move.yfrom, move.xto, move.yto)
        # pprint(test_board.pieces, width=30)
        turn_pass(test_board)
    else:
        loser = randint(2) + 1

    winner = enemy_player(loser)
    return winner
#endregion


#region cpdef void simulate(str player1_setup, str player2_setup, int number_of_games, int with_frequency=0)
cpdef float simulate(str player1_setup, str player2_setup, int number_of_games, int with_frequency=0, int to_display=1):
    cdef int i, p1_wins = 0
    cdef float p1_rate
    cdef Board initial
    build_board(initial, piece_list, player1_setup, player2_setup)
    if to_display: print('\nmoral = [%d]:[%d]' % (initial.moral[1], initial.moral[2]))
    if to_display: pprint(initial.pieces, width=45)
    if with_frequency == 0:
        for i in range(number_of_games):
            if to_display and i % 1000 == 0:
                print('%d%% completed...' % (i * 100 / number_of_games,))
            if simulate_once(initial) == 1:
                p1_wins += 1
    else:
        for i in range(number_of_games):
            if to_display: print('%d%% completed...' % (i * 100 / number_of_games,))
            if simulate_once_with_frequency(initial) == 1:
                p1_wins += 1
    if to_display: print('100% completed...')
    p1_rate = <float> p1_wins / <float> number_of_games
    if to_display: print('Player 1 has a Win%% of [%.1f%%] (wins %d times out of %d games).' % (p1_rate * 100., p1_wins, number_of_games))
    return p1_rate
#endregion

#region FOOBAR
cpdef int random_piece(int be_minion=0, int be_champion=0):
    if be_minion and be_champion:
        return 0
    cdef int num = randint(piece_list.size())
    cdef Piece* p = addr(piece_list[num])
    while (p.name == b'Unnamed') or (not p.minion and not p.champion)\
            or (be_minion and not p.minion) or (be_champion and not p.champion):
        num = randint(piece_list.size())
        p = addr(piece_list[num])
    return num

cpdef dict to_piece(int num):
    cdef Piece p = piece_list.at(num)
    return {'name': p.name, 'cost': p.cost}

cpdef str to_piece_cost(int num):
    return piece_list.at(num).name.decode()

cpdef int to_piece_no(str name):
    cdef bname = name.encode()
    if piece_index.count(bname) == 0:
        return 0
    return piece_index[bname]
#endregion

