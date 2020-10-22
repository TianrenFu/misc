# python 3.5 Anaconda 4.1
import os, csv, re
from pprint import pprint


class Piece_c:
    def __init__(self, name='Unnamed', type='Minion', package='Basic', rarity='Common', cost=0, tier=0, passive='', promotion=''):
        self.name = name
        self.type = type
        self.package = package
        self.rarity = rarity
        self.cost = cost
        self.tier = tier
        self.passive = passive
        self.promotion = promotion
        self.action = Piece_c.new_matrix()
        self.class_name = name.split('+')[0]

    @classmethod
    def new_matrix(cls, size=15):
        """initiate a 15*15 matrix of default value <int>0"""
        matrix = []
        for i in range(size):
            line = []
            for j in range(size):
                line.append(0)
            matrix.append(line)
        return matrix

    @classmethod
    def duplicate_matrix(cls, model):
        """deep copy a 2-dimensional matrix"""
        new = []
        for i in range(len(model)):
            line = []
            for j in range(len(model[i])):
                line.append(model[i][j])
            new.append(line)
        return new


class PieceReader_c:
    def __init__(self, folder='PieceLib'):
        self.files = self.get_file_list(root=folder)
        self.pieces = []
        for file in self.files:
            self.pieces.extend(self.read_file(file))
        self.link_promotions(self.pieces)

    def get_file_list(self, root):
        file_list = []
        for dirpath, dirnames, filenames in os.walk(root):
            for filename in filenames:
                if filename[0] == '#':
                    continue
                file_list.append(os.path.join(dirpath, filename))
        return file_list

    def read_file(self, filename):
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
            for tier in range(4):
                piece = Piece_c(name=self.name_plus_tier(name, tier), type=type, package=package, rarity=rarity, tier=tier)
                self.read_actions(piece, lines[tier + 2])
                if self.is_piece_calculatable(piece):
                    pieces.append(piece)
        return pieces

    def link_promotions(self, pieces):
        """give pieces with regular promotion an attribute 'promoted'"""
        pattern = re.compile(r"Promotes to (\S*?)\.")
        for piece in pieces:
            match = re.match(pattern, piece.passive)
            if match:
                promoted_type = match.groups()[0]
                for p in pieces:
                    if p.name == promoted_type:
                        piece.promoted = p.duplicate_matrix(p.action)
                        break
                else:
                        print('Can\'t find promoted type for ' + piece.name)
            elif 'Promotes to' in piece.passive:
                print('No regular promotion for ' + piece.name)

    @classmethod
    def read_actions(cls, piece, description):
        argu = description.split(',')
        piece.cost=int(argu[0])
        piece.passive=argu[1]
        for i in range(2, len(argu)):
            arguargu = argu[i].split(':')
            action_type, action = int(arguargu[0]), arguargu[1]
            for k in range(0, len(action), 2):
                x, y = cls.resolve_lable(action[k]), cls.resolve_lable(action[k + 1])
                piece.action[x][y] = action_type

    @staticmethod
    def resolve_lable(ch):
        return int(ch, base=16) - 1

    def name_plus_tier(self, name, tier):
        return name + '+' * tier

    # important sieve
    def is_piece_calculatable(self, piece):
        """to determine if a piece can be used in the calculation"""
        legal_action_types = (0, 1)
        black_list = ()
        white_list = ()
        if piece.class_name in black_list:
            return False
        if piece.class_name in white_list:
            return True
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

