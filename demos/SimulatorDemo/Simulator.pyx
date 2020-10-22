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
cdef inline float randf():
    return <float> rand() / <float> RAND_MAX

cdef inline float randsf():
    return (randf() - 0.5) * 2.

cdef inline float sq(float x):
    return x * x
#endregion

#region # float 2d matrix
# cdef float** f2d_malloc(int m, int n):
#     cdef i
#     cdef float** mat = new (float*)[m]
#     for i in range(<int> m):
#         mat[i] = new float[n]
#     return mat
#
# cdef void f2d_free(float** mat, int m, int n):
#     cdef i
#     for i in range(<int> m):
#         delete[] mat[i]
#     delete[] mat
#endregion

#region # cpdef float direction(float x, float y)
# cpdef float direction(float x, float y):
#     cdef float a
#     if x == 0:
#         if y < 0: return -90.
#         return 90.
#     a = atan(y / x) * 180. / PI
#     if x < 0:
#         return -a
#     return a
#endregion

#region cpdef void clamp2f(float& x, float& y, float max_mode)
cpdef void clamp2f(float& x, float& y, float max_mode):
    cdef float mode = sqrt(sq(x) + sq(y)), r
    if mode > max_mode:
        r = max_mode / mode
        addr(x)[0] = x * r
        addr(y)[0] = y * r
#endregion

#region cdef struct Entity
cdef struct struct_entity:
    float m
    float x, y, vx, vy, ax, ay
ctypedef struct_entity Entity

cdef Entity new_entity(float m=1., float x=0., float y=0., float vx=0., float vy=0., float ax=0., float ay=0.):
    cdef Entity e
    e.m, e.x, e.y, e.vx, e.vy, e.ax, e.ay = m, x, y, vx, vy, ax, ay
    return e

cdef inline float distance(Entity ea, Entity eb):
    return sqrt(sq(ea.x - eb.x) + sq(ea.y - eb.y))

cdef inline float manhattan(Entity ea, Entity eb):
    return fabs(ea.x - eb.x) + fabs(ea.y - eb.y)
#endregion


#region cdef class Simulator
cdef class Simulator:
    """the core of simulator, stores entities"""
    cdef vector[Entity] entities
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
        cdef int i, j
        cdef float f, g, dax, day
        cdef Entity* ei
        cdef Entity* ej
        cdef float radacc = 0.0001, maxv = 0.1, affi = 0.0001, repul = 0.0005
        # distance matrix
        cdef int n = self.entities.size()
        # cdef vector[vector[float]]* p_dist = new vector[vector[float]](n, vector[float](n))
        # cdef vector[vector[float]] dist = deref(p_dist)
        cdef vector[vector[float]] dist = vector[vector[float]](n, vector[float](n, 0.))
        for i in range(<int> n):
            ei = addr(self.entities[i])
            dist[i][i] = 0.
            for j in range(<int> i + 1, <int> n):
                f = distance(deref(ei), self.entities[j])
                dist[i][j] = f
                dist[j][i] = f
        # acceleration loop
        for i in range(<int> n):
            ei = addr(self.entities[i])
            dax, day = 0, 0
            for j in range(<int> n):
                if j == i: continue
                ej = addr(self.entities[j])
                f = dist[i][j]
                if f == 0.: g = 0.
                else: g = affi / sq(f) + repul * fpow(f, 6)
                dax = dax + g * (ej.x - ei.x)
                day = day + g * (ej.y - ei.y)
            ei.ax = ei.ax + dax
            ei.ay = ei.ay + day
        # velocity and position loop
        for i in range(<int> n):
            ei = addr(self.entities[i])
            ei.vx = ei.vx + ei.ax * self.dt
            ei.vy = ei.vy + ei.ay * self.dt
            clamp2f(ei.vx, ei.vy, maxv)
            ei.x = ei.x + ei.vx * self.dt
            ei.y = ei.y + ei.vy * self.dt
        # end
        # del p_dist

#endregion