# python 3.5 Anaconda 4.1
from PieceReader cimport *
import os, re

cdef class Piece:
    def __init__(self, name='Unnamed', type='', package='Basic', rarity='Common', cost=0, tier=0, passive='', promotion='', not_blocking=0):
        self.name = name
        self.type = type
        self.package = package
        self.rarity = rarity
        self.cost = cost
        self.tier = tier
        self.passive = passive
        self.promotion = promotion
        self.not_blocking = not_blocking
        self.action = self.new_matrix()
        self.class_name = name.split('+')[0]

    # @classmethod
    cpdef new_matrix(cls, size=15):
        """initiate a 15*15 matrix of default value <int>0"""
        matrix = []
        for i in range(size):
            line = []
            for j in range(size):
                line.append(0)
            matrix.append(line)
        return matrix

    # @classmethod
    cpdef duplicate_matrix(cls, model):
        """deep copy a 2-dimensional matrix"""
        new = []
        for i in range(len(model)):
            line = []
            for j in range(len(model[i])):
                line.append(model[i][j])
            new.append(line)
        return new


cdef class PieceReader:
    def __init__(self, folder='PieceLib'):
        self.files = self.get_file_list(root=folder)
        self.pieces = []
        for file in self.files:
            self.pieces.extend(self.read_file(file))
        self.link_promotions(self.pieces)

    cpdef get_file_list(self, root):
        file_list = []
        for dirpath, dirnames, filenames in os.walk(root):
            for filename in filenames:
                if filename[0] == '#':
                    continue
                file_list.append(os.path.join(dirpath, filename))
        return file_list

    cpdef read_file(self, filename):
        # read all lines in the file
        with open(filename) as file:
            print('Reading %s...' % (filename,))
            lines = file.readlines()
            for i in range(len(lines)):
                if lines[i][-1] == '\n':
                    lines[i] = lines[i][:-1]
            # read title
            argu = lines[0].split(',')
            name, type, package, rarity = argu
            # read actions
            pieces = []
            for tier in range(min(4, len(lines) - 2)):
                piece = Piece(name=self.name_plus_tier(name, tier), type=type, package=package, rarity=rarity, tier=tier)
                self.read_actions(piece, lines[tier + 2])
                if self.is_piece_calculatable(piece):
                    pieces.append(piece)
        return pieces

    cpdef link_promotions(self, pieces):
        """give pieces with regular promotion an attribute 'promoted'"""
        pattern = re.compile(r"Promotes to (\S*?)\.")
        for piece in pieces:
            match = re.match(pattern, piece.passive)
            if match:
                piece.promotion = match.groups()[0]
            elif 'Promotes to' in piece.passive:
                print('No regular promotion for ' + piece.name)

    # @classmethod
    cpdef read_actions(cls, piece, description):
        argu = description.split(',')
        piece.cost=int(argu[0])
        piece.passive=argu[1]
        for i in range(2, len(argu)):
            arguargu = argu[i].split(':')
            action_type, action = int(arguargu[0]), arguargu[1]
            for k in range(0, len(action), 2):
                x, y = cls.resolve_lable(action[k]), cls.resolve_lable(action[k + 1])
                piece.action[x][y] = action_type
            if 'Does not block movement.' in piece.passive:
                piece.not_blocking = 1

    # @staticmethod
    cpdef resolve_lable(sttc, ch):
        return int(ch, base=16)

    cpdef name_plus_tier(self, name, tier):
        return name + '+' * tier

    # important sieve
    cpdef is_piece_calculatable(self, piece):
        """to determine if a piece can be used in the calculation"""
        legal_action_types = (0, 1, 2, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 20, 21, 24, 30, 31, 37, 38, 40, 42)
        # black_list = ()
        # white_list = ()
        # if piece.class_name in black_list:
        #     return False
        # if piece.class_name in white_list:
        #     return True
        # for i in range(len(piece.action)):
        #     for j in range(len(piece.action[i])):
        #         if piece.action[i][j] not in legal_action_types:
        #             return False
        # return True
        black_list = ('Sylph', 'AirElemental')
        white_list = ('Ghost', 'Skeleton', 'Pikeman', 'Phantasm', 'MageTower', 'Medusa', 'FireElemental', 'Ghast',
                      'Greed', 'RoyalGuard', 'Reaver', 'Aquarius', 'Comet', 'Bat', 'Vampire')
        if piece.class_name in white_list:
            return True
        if piece.class_name in black_list:
            return False
        if piece.passive != '' and 'Promotes to' not in piece.passive:
            return False
        for i in range(len(piece.action)):
            for j in range(len(piece.action[i])):
                if piece.action[i][j] not in legal_action_types:
                    return False
        return True





# # test
# if __name__ == '__main__':
#     pr = PieceReader()
#     pieces = pr.pieces
#     print(len(pieces))
#     for p in pieces:
#         print(p.name)

