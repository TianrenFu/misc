import sys

import Simulator
import SimPhysical
from PyQt5 import QtGui, QtCore, QtWidgets


class Monitor(QtWidgets.QWidget):
    """foobar"""
    def __init__(self, parent=None, *args, **kwargs):
        def add_keyword(name, default):
            if name in kwargs:
                return kwargs[name]
            return default
        self.w = add_keyword('width', 1000)
        self.h = add_keyword('height', 1000)
        self.ups = add_keyword('ups', 120)#60)
        self.fps = add_keyword('fps', 48)#30)
        self.buffer = QtGui.QImage(self.w, self.h, QtGui.QImage.Format_ARGB32)
        self.paint_methods = {'circle': self.draw_circle}
        # self.core = Simulator.Simulator(50)
        self.core = SimPhysical.Simulator(20, 1, attraction=5, friction=0.0001, radius=10, max_speed=3)
        self.entities = {}  # {group: [entity, ]}; entity(dict)= 'x': x, 'y': y;  i.e. self.entities = {'circle': [{'x': 250, 'y': 250}, {'x': 100, 'y': 300}]}
        super(Monitor, self).__init__(parent, *args)
        self.setSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Expanding)
        self.init_buffer()
        self.init_timers()

    def init_timers(self):
        def start_timer(frequency, timeout):
            interval = int(1. / float(frequency))
            timer = QtCore.QTimer(self)
            timer.timeout.connect(timeout)
            timer.start(interval)
            return timer
        self.framer = start_timer(self.fps, self.on_paint)
        self.updater = start_timer(self.ups, self.on_core_update)

    def init_buffer(self):
        self.buffer.fill(QtCore.Qt.transparent)

    def on_core_update(self):
        self.entities = self.core.update()

    def on_paint(self):
        self.init_buffer()
        p = QtGui.QPainter()
        p.begin(self.buffer)
        p.setRenderHint(QtGui.QPainter.Antialiasing, True)
        self.entities = self.core.read()
        for entity_type, type_list in self.entities.items():
            method = self.paint_methods[entity_type]
            p.setRenderHint(QtGui.QPainter.Antialiasing, True)
            method(p, type_list)
        p.end()
        self.update()

    def draw_circle(self, qpainter, circle_list):
        margin = 50.
        qpainter.setPen(QtGui.QPen(QtCore.Qt.red))
        # for circle in circle_list:
        color = QtGui.QColor()
        for i in range(len(circle_list)):
            circle = circle_list[i]
            color.setHslF(float(i) / float(len(circle_list)), 1., 0.5, 1.)
            qpainter.setBrush(QtGui.QBrush(color))
            x, y = circle['x'], circle['y']
            if x > -margin and x < self.w + margin and y > -margin and y < self.h + margin:
                qpainter.drawEllipse(QtCore.QPointF(x, y), 10, 10)

    def paintEvent(self, event):
        super(Monitor, self).paintEvent(event)
        width, height = self.width(), self.height()
        edge = min(width, height)
        p = QtGui.QPainter()
        p.begin(self)
        p.setRenderHint(QtGui.QPainter.Antialiasing, True)
        p.drawImage(QtCore.QRect((width - edge) / 2, (height - edge) / 2, edge, edge), self.buffer)
        p.end()

    def minimumSizeHint(self):
        return QtCore.QSize(self.w / 2, self.h / 2)



class MonitorApp(QtWidgets.QMainWindow):
    """warper of class Monitor"""
    def __init__(self, parent=None, *args, **kwargs):
        super(MonitorApp, self).__init__(parent, *args)
        self.main = Monitor(self, *args, **kwargs)
        self.setCentralWidget(self.main)



if __name__ == '__main__':
    app = QtWidgets.QApplication(sys.argv)
    w = MonitorApp()
    w.show()
    app.exec()


