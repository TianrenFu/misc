from libc.stdlib cimport srand, rand, RAND_MAX
from libc.math cimport sqrt, fabs, pow as fpow, atan
from libcpp.vector cimport vector
from cython.operator cimport dereference as deref, preincrement as inc, address as addr

#region intitialize random
cdef extern from 'time.h':
    unsigned int time(unsigned int* timer)
srand(time(NULL))
#endregion

#region inline functions
cdef inline double randf():
    return <double> rand() / <double> RAND_MAX

cdef inline double randsf():
    return (randf() - 0.5) * 2.

cdef inline double sq(double x):
    return x * x

cdef inline double signf(double f):
    return 1. if f > 0. else -1.
#endregion

#region # cpdef double direction(double x, double y)
# cpdef double direction(double x, double y):
#     cdef double a
#     if x == 0:
#         if y < 0: return -90.
#         return 90.
#     a = atan(y / x) * 180. / PI
#     if x < 0:
#         return -a
#     return a
#endregion

#region cdef void clamp2f(double& x, double& y, double max_mode)
cdef void clamp2f(double& x, double& y, double max_mode):
    cdef double mode = sqrt(sq(x) + sq(y)), r
    if mode > max_mode:
        r = max_mode / mode
        addr(x)[0] = x * r
        addr(y)[0] = y * r
#endregion

#region cdef void normalize(double& x, double& y, double mode = 1.)
cdef void normalize(double& x, double& y, double mode = 1.):
    cdef double origin_mode = sqrt(sq(x) + sq(y)), r
    r = mode / origin_mode
    addr(x)[0] = x * r
    addr(y)[0] = y * r
#endregion

#region cdef struct Entity
cdef struct struct_entity:
    double m
    double x, y, vx, vy, ax, ay, dpx, dpy
ctypedef struct_entity Entity

cdef Entity new_entity(double m=1., double x=0., double y=0., double vx=0., double vy=0., double ax=0., double ay=0., double dpx=0., double dpy=0.):
    cdef Entity e
    e.m, e.x, e.y, e.vx, e.vy, e.ax, e.ay, e.dpx, e.dpy = m, x, y, vx, vy, ax, ay, dpx, dpy
    return e

cdef inline double distance(Entity ea, Entity eb):
    return sqrt(sq(ea.x - eb.x) + sq(ea.y - eb.y))

cdef inline double manhattan(Entity ea, Entity eb):
    return fabs(ea.x - eb.x) + fabs(ea.y - eb.y)
#endregion


#region cdef class Simulator
cdef class Simulator:
    """the core of simulator, stores entities"""
    cdef vector[Entity] entities
    cdef double dt  # time interval between two updates
    cdef double attraction_factor  # a += this * distance^-2
    cdef double repulsion_factor  # a -= this * distance^-2
    cdef double friction_factor  # a += this * velocity^2
    cdef double radius  # radius of entities
    cdef double max_speed

    def __init__(self, int num, double interval=1., double attraction=0.1, double repulsion=0., double friction=0.0001, double radius=10., double max_speed=1.):
        self.dt = interval
        self.attraction_factor = attraction
        self.repulsion_factor = repulsion
        self.friction_factor = friction
        self.radius = radius
        self.max_speed = max_speed
        self.entities.clear()
        for i in range(<int> num):
            self.entities.push_back(new_entity(1., randf()*1000, randf()*1000))

    def read(self):
        retdct = {}
        circles = []
        for n in self.entities:
            circles.append({'x': n.x, 'y': n.y})#, 'vx': n.vx, 'vy': n.vy})
        retdct.update({'circle': circles})
        return retdct

    def update(self):
        cdef int i, j
        cdef double d, da, dp, ddax, dday, r, r2, randx, randy
        cdef Entity* ei
        cdef Entity* ej
        cdef force_move_threshold = 0.95
        # distance matrix
        cdef int n = self.entities.size()
        cdef vector[vector[double]] dist = vector[vector[double]](n, vector[double](n, 0.))
        for i in range(<int> n):
            ei = addr(self.entities[i])
            dist[i][i] = 0.
            for j in range(<int> i + 1, <int> n):
                d = distance(deref(ei), self.entities[j])
                dist[i][j] = d
                dist[j][i] = d
        # acceleration loop
        for i in range(<int> n):
            ei = addr(self.entities[i])
            ei.ax, ei.ay = 0., 0.
            ei.dpx, ei.dpy = 0., 0.
            r2 = sq(ei.vx) + sq(ei.vy)
            r = sqrt(r2)
            for j in range(<int> n):
                if j == i: continue
                ej = addr(self.entities[j])
                d = dist[i][j]
                # attraction
                if d > 2. * self.radius:
                    da = self.attraction_factor / sq(d)
                    ei.ax += da / d * (ej.x - ei.x)
                    ei.ay += da / d * (ej.y - ei.y)
                # # repulsion
                # if self.repulsion_factor != 0.:
                #     da = -self.repulsion_factor / sq(d)
                #     ei.ax += da / d * (ej.x - ei.x)
                #     ei.ay += da / d * (ej.y - ei.y)
                # collision
                else:  # (d <= 2. * self.radius)
                    ei.ax += (ej.vx - ei.vx) * self.dt
                    ei.ay += (ej.vy - ei.vy) * self.dt
                    if d < 2. * self.radius * force_move_threshold:
                        if d == 0.:
                            randx, randy = randsf(), randsf()
                            while randx == 0. and randy == 0.:
                                randx, randy = randsf(), randsf()
                            normalize(randx, randy, self.radius * force_move_threshold)
                            ei.dpx += randx
                            ei.dpy += randy
                        else:
                            dp = self.radius * force_move_threshold - d / 2.
                            ei.dpx -= dp / d * (ej.x - ei.x)
                            ei.dpy -= dp / d * (ej.y - ei.y)
            # boarder
            if (ei.x < 0. and ei.vx < 0) or (ei.x > 1000. and ei.vx > 0):
                ei.ax -= 2. * ei.vx
            if (ei.y < 0. and ei.vy < 0) or (ei.y > 1000. and ei.vy > 0):
                ei.ay -= 2. * ei.vy
            # friction
            if r != 0:
                da = self.friction_factor * r2
                ei.ax -= da / r * ei.vx
                ei.ay -= da / r * ei.vy
        # velocity and position loop
        for i in range(<int> n):
            ei = addr(self.entities[i])
            ei.vx += ei.ax * self.dt
            ei.vy += ei.ay * self.dt
            clamp2f(ei.vx, ei.vy, self.max_speed)
            clamp2f(ei.dpx, ei.dpy, self.radius * force_move_threshold)
            ei.x += ei.vx * self.dt + ei.dpx
            ei.y += ei.vy * self.dt + ei.dpy
        # end

#endregion