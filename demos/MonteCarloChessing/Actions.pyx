# cython: python 3.5
from cython.operator cimport dereference as deref, preincrement as inc, address as addr
from Actions cimport *

cdef int can_target(Board& board, int xfrom, int yfrom, int xto, int yto, int actno):
    cdef int pfrom, pto, ofrom, oto
    cdef int dx, dy, xt, yt, xunit, yunit
    cdef Action *action = addr(actions[actno])
    if board.frozen[xfrom][yfrom] != 0 and actno != 38:
        return 0
    pfrom = board.pieces[xfrom][yfrom]; pto = board.pieces[xto][yto]
    ofrom = board.ownerships[xfrom][yfrom]; oto = board.ownerships[xto][yto]
    if (action.attr.to_empty and pto == 0) or (action.attr.to_enemy and oto != ofrom) or (action.attr.to_friend and oto == ofrom):
        if action.attr.blockable:
            dx = xto - xfrom; dy = yto - yfrom
            if (dx != 0) and (dy != 0) and (iabs(dx) != iabs(dy)):
                return 0
            xunit = unit(dx); yunit = unit(dy)
            xt = xfrom + xunit; yt = yfrom + yunit
            while xt != xto and yt != yto:
                if board.pieces[xt][yt] != 0 and piece_list[board.pieces[xt][yt]].not_blocking == 0:
                    return 0
                xt += xunit; yt += yunit
        # if action.attr.additional_limit:
        #     return action.attr.limit(board, xfrom, yfrom, xto, yto)
        return 1  # can target that grid
    return 0  # cannot target that grid


#######################
#region BASIC ACTIONS
cdef void null_function(Board& board, int xfrom, int yfrom, int xto, int yto):
    pass

cdef void move_to(Board& board, int xfrom, int yfrom, int xto, int yto):
    cdef int pfrom = board.pieces[xfrom][yfrom]
    cdef int pto = board.pieces[xto][yto]
    cdef int ofrom = board.ownerships[xfrom][yfrom]
    cdef int oto = board.ownerships[xto][yto]
    if pto != 0:
        if piece_list[pfrom].has_on_kill: piece_list[pfrom].on_kill(board, xfrom, yfrom, xto, yto)  # on kill
        if piece_list[pto].has_on_death: piece_list[pto].on_death(board, xfrom, yfrom, xto, yto)  # on death
    # todo: on melee death
    board.moral[oto] -= board.costs[xto][yto]
    board.pieces[xfrom][yfrom], board.pieces[xto][yto] = 0, pfrom
    board.ownerships[xfrom][yfrom], board.ownerships[xto][yto] = 0, ofrom
    board.costs[xfrom][yfrom], board.costs[xto][yto] = 0, board.costs[xfrom][yfrom]
    board.frozen[xfrom][yfrom], board.frozen[xto][yto] = 0, board.frozen[xfrom][yfrom]
    board.poison[xfrom][yfrom], board.poison[xto][yto] = 0, board.poison[xfrom][yfrom]
    if (yto == 0 and ofrom == 1) or (yto == 7 and ofrom == 2):  # promotion
        if 0 < piece_list[pfrom].promotion and piece_list[pfrom].promotion < piece_list.size():
            # print('%s[%d] promotes to %s[%d] (%d, %d)!' % (piece_list[board.pieces[xto][yto]].name.decode(), board.pieces[xto][yto], piece_list[piece_list[pfrom].promotion].name.decode(), piece_list[pfrom].promotion, xto, yto))
            board.pieces[xto][yto] = piece_list[pfrom].promotion
            board.moral[ofrom] -= board.costs[xto][yto]
            board.costs[xto][yto] = piece_list[piece_list[pfrom].promotion].cost
            board.moral[ofrom] += board.costs[xto][yto]
            board.frozen[xto][yto] = 0
            board.poison[xto][yto] = 0

cdef void destroy(Board& board, int xfrom, int yfrom, int xto, int yto):
    cdef int pfrom = board.pieces[xfrom][yfrom]
    cdef int pto = board.pieces[xto][yto]
    if pto != 0:
        if piece_list[pfrom].has_on_kill: piece_list[pfrom].on_kill(board, xfrom, yfrom, xto, yto)  # on kill
        if piece_list[pto].has_on_death: piece_list[pto].on_death(board, xfrom, yfrom, xto, yto)  # on death
    board.moral[board.ownerships[xto][yto]] -= board.costs[xto][yto]
    board.pieces[xto][yto] = 0
    board.ownerships[xto][yto] = 0
    board.costs[xto][yto] = 0
    board.frozen[xto][yto] = 0
    board.poison[xto][yto] = 0

cdef void swap_with(Board& board, int xfrom, int yfrom, int xto, int yto):
    cdef int pfrom = board.pieces[xfrom][yfrom]
    cdef int pto = board.pieces[xto][yto]
    cdef int o = board.ownerships[xfrom][yfrom]
    board.pieces[xfrom][yfrom], board.pieces[xto][yto] = pto, pfrom
    board.costs[xfrom][yfrom], board.costs[xto][yto] = board.costs[xto][yto], board.costs[xfrom][yfrom]
    board.frozen[xfrom][yfrom], board.frozen[xto][yto] = board.frozen[xto][yto], board.frozen[xfrom][yfrom]
    board.poison[xfrom][yfrom], board.poison[xto][yto] = board.poison[xto][yto], board.poison[xfrom][yfrom]
    if (yto == 0 and o == 1) or (yto == 7 and o == 2):  # promotion of pfrom
        if 0 < piece_list[pfrom].promotion < piece_list.size():
            board.pieces[xto][yto] = piece_list[pfrom].promotion
            board.moral[o] -= board.costs[xto][yto]
            board.costs[xto][yto] = piece_list[piece_list[pfrom].promotion].cost
            board.moral[o] += board.costs[xto][yto]
            board.frozen[xto][yto] = 0
            board.poison[xto][yto] = 0
    if (yfrom == 0 and o == 1) or (yfrom == 7 and o == 2):  # promotion of pto
        if 0 < piece_list[pfrom].promotion and piece_list[pfrom].promotion < piece_list.size():
            board.pieces[xfrom][yfrom] = piece_list[pto].promotion
            board.moral[o] -= board.costs[xfrom][yfrom]
            board.costs[xfrom][yfrom] = piece_list[piece_list[pto].promotion].cost
            board.moral[o] += board.costs[xfrom][yfrom]
            board.frozen[xfrom][yfrom] = 0
            board.poison[xfrom][yfrom] = 0

cdef void frozen(Board& board, int xfrom, int yfrom, int xto, int yto):
    if board.frozen[xto][yto] < 6:
        board.frozen[xto][yto] = 6

cdef void petrify(Board& board, int xfrom, int yfrom, int xto, int yto):
    if board.frozen[xto][yto] < 10:
        board.frozen[xto][yto] = 10

cdef void poison(Board& board, int xfrom, int yfrom, int xto, int yto):
    if board.poison[xto][yto] == 0:
        board.poison[xto][yto] = 6

cdef void thunder(Board& board, int xfrom, int yfrom, int xto, int yto):
    if board.thunder[xto][yto] == 0:
        board.thunder[xto][yto] = 8

cdef void charm(Board& board, int xfrom, int yfrom, int xto, int yto):
    cdef int ofrom = board.ownerships[xfrom][yfrom]
    cdef int oto = board.ownerships[xto][yto]
    cdef int cto = board.costs[xto][yto]
    board.ownerships[xto][yto] = ofrom
    board.moral[ofrom] += cto
    board.moral[oto] -= cto
#endregion
#######################


#######################
#region INTEGRATED ACTIONS
cdef void move_attack_swap(Board& board, int xfrom, int yfrom, int xto, int yto):
    if board.ownerships[xfrom][yfrom] == board.ownerships[xto][yto]:
        swap_with(board, xfrom, yfrom, xto, yto)
    else:
        move_to(board, xfrom, yfrom, xto, yto)

cdef void pay1_destroy(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xfrom][yfrom]] -= 1
    destroy(board, xfrom, yfrom, xto, yto)

cdef void transform_into_ghost(Board& board, int xfrom, int yfrom, int xto, int yto):
    board.moral[board.ownerships[xfrom][yfrom]] -= 1
    destroy(board, xfrom, yfrom, xto, yto)
    board.pieces[xto][yto] = piece_index[b'ghost']
    board.ownerships[xto][yto] = board.ownerships[xfrom][yfrom]
    board.costs[xto][yto] = 3
    board.moral[board.ownerships[xfrom][yfrom]] += 3

cdef void frozen_strike(Board& board, int xfrom, int yfrom, int xto, int yto):
    cdef int pfrom = board.pieces[xfrom][yfrom]
    if board.frozen[xto][yto] < 6:
        board.frozen[xto][yto] = 6
    if piece_list[pfrom].has_on_death: piece_list[pfrom].on_death(board, xto, yto, xto, yto)  # to properly trigger Aquarius/Comet's on_death
    board.moral[board.ownerships[xfrom][yfrom]] -= board.costs[xfrom][yfrom]
    board.pieces[xfrom][yfrom] = 0
    board.ownerships[xfrom][yfrom] = 0
    board.costs[xfrom][yfrom] = 0
    board.frozen[xfrom][yfrom] = 0
    board.poison[xfrom][yfrom] = 0

cdef void teleport_king(Board& board, int xfrom, int yfrom, int xto, int yto):
    cdef int x, y
    cdef int ofrom = board.ownerships[xfrom][yfrom]
    cdef int pking = piece_index[b'King']
    for x in range(BOARD_SIZE):
        for y in range(BOARD_SIZE):
            if board.pieces[x][y] == pking and board.ownerships[x][y] == ofrom:
                move_to(board, x, y, xto, yto)
                break

cdef void tranform_into_bat(Board& board, int xfrom, int yfrom, int xto, int yto):
    cdef int ofrom = board.ownerships[xfrom][yfrom]
    cdef int pbat = piece_index[b'Bat'] + board.pieces[xfrom][yfrom] - piece_index[b'Vampire']
    board.pieces[xfrom][yfrom] = pbat
    board.moral[ofrom] -= board.costs[xfrom][yfrom]
    board.costs[xfrom][yfrom] = piece_list[pbat].cost
    board.moral[ofrom] += board.costs[xfrom][yfrom]
    board.frozen[xfrom][yfrom] = 0
    board.poison[xfrom][yfrom] = 0
    move_to(board, xfrom, yfrom, xto, yto)

#endregion
#######################


#######################
#region ADDITIONAL LIMIT
cdef int nullctf(Board& board, int xfrom, int yfrom, int xto, int yto):
    return 0

cdef int from_starting_position(Board& board, int xfrom, int yfrom, int xto, int yto):
    cdef ofrom = board.ownerships[xfrom][yfrom]
    if (ofrom == 1 and xfrom == 6) or (ofrom == 2 and xfrom == 1):
        return 1
    return 0

cdef int minion_only(Board& board, int xfrom, int yfrom, int xto, int yto):
    return piece_list[board.pieces[xto][yto]].minion
#endregion
#######################


cdef vector[Action] actions = vector[Action](50, [0, null_function, [0, 0, 0, 0, 0, nullctf], 'NULL'])
actions[1] = [1, move_to, [1, 1, 0, 1, 0, nullctf], 'Move or Attack.']
actions[2] = [2, move_to, [1, 0, 0, 1, 0, nullctf], 'Move only.']
actions[3] = [3, move_to, [0, 1, 0, 1, 0, nullctf], 'Attack only.']
actions[4] = [4, move_to, [1, 1, 0, 0, 0, nullctf], '(Unblockable) Move or Attack.']
actions[5] = [5, move_attack_swap, [1, 1, 1, 0, 0, nullctf], '(Unblockable) Move, Attack, or swap places with ally.']
actions[6] = [6, move_to, [1, 0, 0, 0, 0, nullctf], '(Unblockable) Teleport.']
actions[7] = [7, pay1_destroy, [0, 1, 0, 0, 0, nullctf], '[Pay 1]: (Magic) Destroy target.']
actions[9] = [9, charm, [0, 1, 0, 0, 1, minion_only], '(Magic) Charm enemy minion.']
actions[11] = [11, move_to, [1, 0, 0, 1, 1, from_starting_position], 'Move from starting position.']
actions[12] = [12, poison, [0, 1, 0, 0, 0, nullctf], '(Magic) Poison enemy unit, destroying them in 3 turns.']
actions[13] = [13, frozen, [0, 1, 0, 0, 0, nullctf], '(Magic) Freeze enemy unit, making them unable to Move or Attack for 3 turns.']
actions[14] = [14, petrify, [0, 1, 0, 1, 0, nullctf], '(Ranged) Petrify enemy unit, making them unable to Move or Attack for 5 turns.']
actions[20] = [20, transform_into_ghost, [0, 1, 0, 0, 0, nullctf], '[Pay 1]: (Magic) Transform enemy into ally Ghost.']
actions[21] = [21, move_to, [1, 0, 0, 0, 1, from_starting_position], '(Unblockable) Teleport from starting position.']
actions[24] = [24, move_to, [0, 1, 0, 0, 1, minion_only], '(Unblockable) Attack Minion.']
actions[30] = [30, teleport_king, [1, 0, 0, 0, 0, nullctf], '(Magic) Teleport ally King to this empty location.']
actions[31] = [31, swap_with, [1, 0, 1, 0, 0, nullctf], '(Unblockable) Teleport or swap places with ally.']
actions[37] = [37, frozen_strike, [0, 1, 0, 0, 0, nullctf], '(Magic) Destroy self at target location and Freeze enemy unit, making them unable to Move or Attack for 3 turns.']
actions[38] = [38, tranform_into_bat, [1, 0, 0, 0, 0, nullctf], '(Unstoppable) Transform into Bat and fly to location.']
actions[40] = [40, thunder, [1, 1, 1, 0, 0, nullctf], 'Mark location to be destroyed by Magic 4 turns after activating.']
actions[42] = [42, pay1_destroy, [0, 1, 0, 1, 0, nullctf], '[Pay 1]: (Ranged) Destroy target.']
