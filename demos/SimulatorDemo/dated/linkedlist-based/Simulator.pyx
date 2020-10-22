from libc.stdlib cimport srand, rand, RAND_MAX
from libc.math cimport sqrt, fabs
from libcpp.list cimport list as clist
from cython.operator cimport dereference as deref, preincrement as inc

# intitialize random
cdef extern from 'time.h':
    unsigned int time(unsigned int* timer)
srand(time(NULL))

cdef inline float randf():
    return <float> rand() / <float> RAND_MAX

cdef inline float randsf():
    return (randf() - 0.5) * 2.

# inline functions
cdef inline float sq(float x):
    return x * x

#region cdef struct Entity
cdef struct struct_entity:
    float m
    float x, y, vx, vy, ax, ay
ctypedef struct_entity Entity

cdef Entity new_entity(float m, float x, float y):
    cdef Entity e
    e.m, e.x, e.y = m, x, y
    e.vx, e.vy, e.ax, e.ay = 0, 0, 0, 0
    return e

cdef inline float distance(Entity a, Entity b):
    return sqrt(sq(a.x - b.x) + sq(a.y - b.y))

cdef inline float manhattan(Entity a, Entity b):
    return fabs(a.x - b.x) + fabs(a.y - b.y)
#endregion

# main class
cdef class Simulator:
    """the core of simulator, stores entities"""
    cdef clist[Entity] entities
    cdef float dt

    def __init__(self, int num):
        self.dt = 1.
        self.entities.clear()
        for i in range(<int> num):
            self.entities.push_back(new_entity(1., randf()*500, randf()*500))

    def read(self):
        retdct = {}
        circles = []
        for n in self.entities:
            circles.append({'x': n.x, 'y': n.y})#, 'vx': n.vx, 'vy': n.vy})
        retdct.update({'circle': circles})
        return retdct

    def update(self):
        cdef clist[Entity].iterator it
        # velocity loop
        it = self.entities.begin()
        while it != self.entities.end():
            deref(it).vx, deref(it).vy = 0.2 * randsf(), 0.2 * randsf()
            inc(it)
        # position loop
        it = self.entities.begin()
        while it != self.entities.end():
            deref(it).x = deref(it).x + deref(it).vx * self.dt
            deref(it).y = deref(it).y + deref(it).vy * self.dt
            inc(it)

