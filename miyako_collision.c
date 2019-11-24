/*
--
Miyako v2.0 Extend Library "Miyako no Katana"
Copyright (C) 2008  Cyross Makoto

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
++
*/

/*
=miyako_no_katana
Authors:: Cyross Makoto
Version:: 2.0
Copyright:: 2007-2009 Cyross Makoto
License:: LGPL2.1
 */
#include "defines.h"

static VALUE mSDL = Qnil;
static VALUE mMiyako = Qnil;
static VALUE eMiyakoError = Qnil;
static VALUE cCollision = Qnil;
static VALUE cCircleCollision = Qnil;
static VALUE cCollisionEx = Qnil;
static VALUE cCollisions = Qnil;
static VALUE nZero = Qnil;
static VALUE nOne = Qnil;
static volatile ID id_update = Qnil;
static volatile ID id_kakko  = Qnil;
static volatile ID id_render = Qnil;
static volatile ID id_to_a   = Qnil;
static volatile int zero = Qnil;
static volatile int one = Qnil;

/*
:nodoc:
*/
static VALUE collision_get_position(VALUE pos, VALUE *x, VALUE *y)
{
  switch(TYPE(pos))
  {
  case T_ARRAY:
    if(RARRAY_LEN(pos) < 2)
      rb_raise(eMiyakoError, "pairs have illegal array!");
    *x = RSTRUCT_GET(pos, 0);
    *y = RSTRUCT_GET(pos, 1);
    break;
  case T_STRUCT:
    if(RSTRUCT_LEN(pos) < 2)
      rb_raise(eMiyakoError, "pairs have illegal struct!");
    *x = RSTRUCT_GET(pos, 0);
    *y = RSTRUCT_GET(pos, 1);
    break;
  default:
    *x = rb_funcall(pos, rb_intern("x"), 0);
    *y = rb_funcall(pos, rb_intern("y"), 0);
    break;
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collision_c_collision(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE prect1 = rb_iv_get(c1, "@rect");
  VALUE prect2 = rb_iv_get(c2, "@rect");
  VALUE x1, y1, x2, y2;
  double l1, l2, t1, t2, r1, r2, b1, b2;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  l1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(prect1, 0));
  t1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(prect1, 1));
  r1 = l1 + NUM2DBL(RSTRUCT_GET(prect1, 2)) - 1;
  b1 = t1 + NUM2DBL(RSTRUCT_GET(prect1, 3)) - 1;
  l2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(prect2, 0));
  t2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(prect2, 1));
  r2 = l2 + NUM2DBL(RSTRUCT_GET(prect2, 2)) - 1;
  b2 = t2 + NUM2DBL(RSTRUCT_GET(prect2, 3)) - 1;

  if(l2 <= r1 && r1 <= r2)
  {
    if(t2 <= b1 && b1 <= b2) return Qtrue;
    if(t2 <= t1 && t1 <= b2) return Qtrue;
    return Qfalse;
  }
  if(l2 <= l1 && l1 <= r2)
  {
    if(t2 <= b1 && b1 <= b2) return Qtrue;
    if(t2 <= t1 && t1 <= b2) return Qtrue;
    return Qfalse;
  }
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_meet(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE prect1 = rb_iv_get(c1, "@rect");
  VALUE prect2 = rb_iv_get(c2, "@rect");
  VALUE x1, y1, x2, y2;
  double l1, l2, t1, t2, r1, r2, b1, b2;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  l1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(prect1, 0));
  t1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(prect1, 1));
  r1 = l1 + NUM2DBL(RSTRUCT_GET(prect1, 2)) - 1;
  b1 = t1 + NUM2DBL(RSTRUCT_GET(prect1, 3)) - 1;
  l2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(prect2, 0));
  t2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(prect2, 1));
  r2 = l2 + NUM2DBL(RSTRUCT_GET(prect2, 2)) - 1;
  b2 = t2 + NUM2DBL(RSTRUCT_GET(prect2, 3)) - 1;

  if(r1 == l2 || b1 == t2 || l1 == r2 || t1 == b2) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_cover(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE prect1 = rb_iv_get(c1, "@rect");
  VALUE prect2 = rb_iv_get(c2, "@rect");
  double l1, l2, t1, t2, r1, r2, b1, b2;
  VALUE x1, y1, x2, y2;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  l1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(prect1, 0));
  t1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(prect1, 1));
  r1 = l1 + NUM2DBL(RSTRUCT_GET(prect1, 2)) - 1;
  b1 = t1 + NUM2DBL(RSTRUCT_GET(prect1, 3)) - 1;
  l2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(prect2, 0));
  t2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(prect2, 1));
  r2 = l2 + NUM2DBL(RSTRUCT_GET(prect2, 2)) - 1;
  b2 = t2 + NUM2DBL(RSTRUCT_GET(prect2, 3)) - 1;

  if(l1 >= l2 && r1 <= r2 && t1 >= t2 && b1 <= b2) return Qtrue;
  if(l1 <= l2 && r1 >= r2 && t1 <= t2 && b1 >= b2) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_covers(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE prect1 = rb_iv_get(c1, "@rect");
  VALUE prect2 = rb_iv_get(c2, "@rect");
  VALUE x1, y1, x2, y2;
  double l1, l2, t1, t2, r1, r2, b1, b2;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  l1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(prect1, 0));
  t1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(prect1, 1));
  r1 = l1 + NUM2DBL(RSTRUCT_GET(prect1, 2)) - 1;
  b1 = t1 + NUM2DBL(RSTRUCT_GET(prect1, 3)) - 1;
  l2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(prect2, 0));
  t2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(prect2, 1));
  r2 = l2 + NUM2DBL(RSTRUCT_GET(prect2, 2)) - 1;
  b2 = t2 + NUM2DBL(RSTRUCT_GET(prect2, 3)) - 1;

  if(l1 <= l2 && r1 >= r2 && t1 <= t2 && b1 >= b2) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_c_covered(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE prect1 = rb_iv_get(c1, "@rect");
  VALUE prect2 = rb_iv_get(c2, "@rect");
  VALUE x1, y1, x2, y2;
  double l1, l2, t1, t2, r1, r2, b1, b2;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  l1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(prect1, 0));
  t1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(prect1, 1));
  r1 = l1 + NUM2DBL(RSTRUCT_GET(prect1, 2)) - 1;
  b1 = t1 + NUM2DBL(RSTRUCT_GET(prect1, 3)) - 1;
  l2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(prect2, 0));
  t2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(prect2, 1));
  r2 = l2 + NUM2DBL(RSTRUCT_GET(prect2, 2)) - 1;
  b2 = t2 + NUM2DBL(RSTRUCT_GET(prect2, 3)) - 1;

  if(l1 >= l2 && r1 <= r2 && t1 >= t2 && b1 <= b2) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE collision_collision(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return collision_c_collision(cCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_meet(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return collision_c_meet(cCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_cover(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return collision_c_cover(cCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_covers(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return collision_c_covers(cCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_covered(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return collision_c_covered(cCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE circlecollision_c_collision(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE pcenter1 = rb_iv_get(c1, "@center");
  VALUE pcenter2 = rb_iv_get(c2, "@center");
  double r1 = NUM2DBL(rb_iv_get(c1, "@radius"));
  double r2 = NUM2DBL(rb_iv_get(c2, "@radius"));
  double r  = (r1 + r2) * (r1 + r2);
  VALUE x1, y1, x2, y2;
  double cx1, cy1, cx2, cy2, d;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  cx1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(pcenter1, 0));
  cy1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(pcenter1, 1));
  cx2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(pcenter2, 0));
  cy2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(pcenter2, 1));
  d   = (cx1-cx2) * (cx1-cx2) + (cy1-cy2) * (cy1-cy2);

  if(d <= r) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE circlecollision_c_meet(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE pcenter1 = rb_iv_get(c1, "@center");
  VALUE pcenter2 = rb_iv_get(c2, "@center");
  double r1 = NUM2DBL(rb_iv_get(c1, "@radius"));
  double r2 = NUM2DBL(rb_iv_get(c2, "@radius"));
  double r  = (r1 + r2) * (r1 + r2);
  VALUE x1, y1, x2, y2;
  double cx1, cy1, cx2, cy2, d;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  cx1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(pcenter1, 0));
  cy1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(pcenter1, 1));
  cx2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(pcenter2, 0));
  cy2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(pcenter2, 1));
  d   = (cx1-cx2) * (cx1-cx2) + (cy1-cy2) * (cy1-cy2);

  if(d == r) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE circlecollision_c_cover(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE pcenter1 = rb_iv_get(c1, "@center");
  VALUE pcenter2 = rb_iv_get(c2, "@center");
  double r1 = NUM2DBL(rb_iv_get(c1, "@radius"));
  double r2 = NUM2DBL(rb_iv_get(c2, "@radius"));
  double r = (r1 - r2) * (r1 - r2); // y = (x-a)^2 -> y = x^2 - 2ax + a^2
  VALUE x1, y1, x2, y2;
  double cx1, cy1, cx2, cy2, d;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  cx1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(pcenter1, 0));
  cy1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(pcenter1, 1));
  cx2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(pcenter2, 0));
  cy2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(pcenter2, 1));
  d   = (cx1-cx2) * (cx1-cx2) + (cy1-cy2) * (cy1-cy2);

  if(d <= r) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE circlecollision_c_covers(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE pcenter1 = rb_iv_get(c1, "@center");
  VALUE pcenter2 = rb_iv_get(c2, "@center");
  double r1 = NUM2DBL(rb_iv_get(c1, "@radius"));
  double r2 = NUM2DBL(rb_iv_get(c2, "@radius"));
  double r = (r1 - r2) * (r1 - r2); // y = (x-a)^2 -> y = x^2 - 2ax + a^2
  VALUE x1, y1, x2, y2;
  double cx1, cy1, cx2, cy2, d;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  cx1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(pcenter1, 0));
  cy1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(pcenter1, 1));
  cx2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(pcenter2, 0));
  cy2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(pcenter2, 1));
  d   = (cx1-cx2) * (cx1-cx2) + (cy1-cy2) * (cy1-cy2);

  if(r1 >= r2 && d <= r) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE circlecollision_c_covered(VALUE self, VALUE c1, VALUE pos1, VALUE c2, VALUE pos2)
{
  VALUE pcenter1 = rb_iv_get(c1, "@center");
  VALUE pcenter2 = rb_iv_get(c2, "@center");
  double r1 = NUM2DBL(rb_iv_get(c1, "@radius"));
  double r2 = NUM2DBL(rb_iv_get(c2, "@radius"));
  double r = (r1 - r2) * (r1 - r2); // y = (x-a)^2 -> y = x^2 - 2ax + a^2
  VALUE x1, y1, x2, y2;
  double cx1, cy1, cx2, cy2, d;
  collision_get_position(pos1, &x1, &y1);
  collision_get_position(pos2, &x2, &y2);
  cx1 = NUM2DBL(x1) + NUM2DBL(RSTRUCT_GET(pcenter1, 0));
  cy1 = NUM2DBL(y1) + NUM2DBL(RSTRUCT_GET(pcenter1, 1));
  cx2 = NUM2DBL(x2) + NUM2DBL(RSTRUCT_GET(pcenter2, 0));
  cy2 = NUM2DBL(y2) + NUM2DBL(RSTRUCT_GET(pcenter2, 1));
  d   = (cx1-cx2) * (cx1-cx2) + (cy1-cy2) * (cy1-cy2);

  if(r1 <= r2 && d <= r) return Qtrue;
  return Qfalse;
}

/*
:nodoc:
*/
static VALUE circlecollision_collision(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return circlecollision_c_collision(cCircleCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE circlecollision_meet(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return circlecollision_c_meet(cCircleCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE circlecollision_cover(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return circlecollision_c_cover(cCircleCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE circlecollision_covers(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return circlecollision_c_covers(cCircleCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE circlecollision_covered(VALUE self, VALUE pos1, VALUE c2, VALUE pos2)
{
  return circlecollision_c_covered(cCircleCollision, self, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_ex_c_collision(VALUE self, VALUE c1, VALUE c2)
{
  VALUE pos1 = rb_iv_get(c1, "@pos");
  VALUE pos2 = rb_iv_get(c2, "@pos");
  return collision_c_collision(cCollision, c1, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_ex_c_meet(VALUE self, VALUE c1, VALUE c2)
{
  VALUE pos1 = rb_iv_get(c1, "@pos");
  VALUE pos2 = rb_iv_get(c2, "@pos");
  return collision_c_meet(cCollision, c1, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_ex_c_cover(VALUE self, VALUE c1, VALUE c2)
{
  VALUE pos1 = rb_iv_get(c1, "@pos");
  VALUE pos2 = rb_iv_get(c2, "@pos");
  return collision_c_cover(cCollision, c1, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_ex_c_covers(VALUE self, VALUE c1, VALUE c2)
{
  VALUE pos1 = rb_iv_get(c1, "@pos");
  VALUE pos2 = rb_iv_get(c2, "@pos");
  return collision_c_covers(cCollision, c1, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_ex_c_covered(VALUE self, VALUE c1, VALUE c2)
{
  VALUE pos1 = rb_iv_get(c1, "@pos");
  VALUE pos2 = rb_iv_get(c2, "@pos");
  return collision_c_covered(cCollision, c1, pos1, c2, pos2);
}

/*
:nodoc:
*/
static VALUE collision_ex_collision(VALUE self, VALUE c2)
{
  return collision_ex_c_collision(cCollisionEx, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_ex_meet(VALUE self, VALUE c2)
{
  return collision_ex_c_meet(cCollisionEx, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_ex_cover(VALUE self, VALUE c2)
{
  return collision_ex_c_cover(cCollisionEx, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_ex_covers(VALUE self, VALUE c2)
{
  return collision_ex_c_covers(cCollisionEx, self, c2);
}

/*
:nodoc:
*/
static VALUE collision_ex_covered(VALUE self, VALUE c2)
{
  return collision_ex_c_covered(cCollisionEx, self, c2);
}

/*
:nodoc:
*/
static VALUE collisions_collision(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_collision(c, pos, *cc, *(cc+1)) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_meet(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_meet(c, pos, *cc, *(cc+1)) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_cover(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_cover(c, pos, *cc, *(cc+1)) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_covers(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_covers(c, pos, *cc, *(cc+1)) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_covered(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_covered(c, pos, *cc, *(cc+1)) == Qtrue){ return cs; }
  }
  return Qnil;
}

/*
:nodoc:
*/
static VALUE collisions_collision_all(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_collision(c, pos, *cc, *(cc+1)) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_meet_all(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_meet(c, pos, *cc, *(cc+1)) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_cover_all(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_cover(c, pos, *cc, *(cc+1)) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_covers_all(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_covers(c, pos, *cc, *(cc+1)) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

/*
:nodoc:
*/
static VALUE collisions_covered_all(VALUE self, VALUE c, VALUE pos)
{
  VALUE collisions = rb_iv_get(self, "@collisions");
  VALUE ret = rb_ary_new();
  int i=0;
  for(i=0; i<RARRAY_LEN(collisions); i++){
    VALUE cs = *(RARRAY_PTR(collisions) + i);
    VALUE *cc = RARRAY_PTR(cs);
    if(collision_covered(c, pos, *cc, *(cc+1)) == Qtrue){ rb_ary_push(ret, cs); }
  }
  if(RARRAY_LEN(ret) == 0){ return Qnil; }
  return ret;
}

void Init_miyako_collision()
{
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
  cCollision = rb_define_class_under(mMiyako, "Collision", rb_cObject);
  cCircleCollision = rb_define_class_under(mMiyako, "CircleCollision", rb_cObject);
  cCollisionEx = rb_define_class_under(mMiyako, "CollisionEx", cCollision);
  cCollisions = rb_define_class_under(mMiyako, "Collisions", rb_cObject);

  id_update = rb_intern("update");
  id_kakko  = rb_intern("[]");
  id_render = rb_intern("render");
  id_to_a   = rb_intern("to_a");

  zero = 0;
  nZero = INT2NUM(zero);
  one = 1;
  nOne = INT2NUM(one);

  rb_define_singleton_method(cCollision, "collision?", collision_c_collision, 4);
  rb_define_singleton_method(cCollision, "meet?", collision_c_meet, 4);
  rb_define_singleton_method(cCollision, "cover?", collision_c_cover, 4);
  rb_define_singleton_method(cCollision, "covers?", collision_c_covers, 4);
  rb_define_singleton_method(cCollision, "covered?", collision_c_covered, 4);
  rb_define_method(cCollision, "collision?", collision_collision, 3);
  rb_define_method(cCollision, "meet?", collision_meet, 3);
  rb_define_method(cCollision, "cover?", collision_cover, 3);
  rb_define_method(cCollision, "covers?", collision_covers, 3);
  rb_define_method(cCollision, "covered?", collision_covered, 3);

  rb_define_singleton_method(cCollisionEx, "collision?", collision_ex_c_collision, 2);
  rb_define_singleton_method(cCollisionEx, "meet?", collision_ex_c_meet, 2);
  rb_define_singleton_method(cCollisionEx, "cover?", collision_ex_c_cover, 2);
  rb_define_singleton_method(cCollisionEx, "covers?", collision_ex_c_covers, 2);
  rb_define_singleton_method(cCollisionEx, "covered?", collision_ex_c_covered, 2);
  rb_define_method(cCollisionEx, "collision?", collision_ex_collision, 1);
  rb_define_method(cCollisionEx, "meet?", collision_ex_meet, 1);
  rb_define_method(cCollisionEx, "cover?", collision_ex_cover, 1);
  rb_define_method(cCollisionEx, "covers?", collision_ex_covers, 1);
  rb_define_method(cCollisionEx, "covered?", collision_ex_covered, 1);

  rb_define_singleton_method(cCircleCollision, "collision?", circlecollision_c_collision, 4);
  rb_define_singleton_method(cCircleCollision, "meet?", circlecollision_c_meet, 4);
  rb_define_singleton_method(cCircleCollision, "cover?", circlecollision_c_cover, 4);
  rb_define_singleton_method(cCircleCollision, "covers?", circlecollision_c_covers, 4);
  rb_define_singleton_method(cCircleCollision, "covered?", circlecollision_c_covered, 4);
  rb_define_method(cCircleCollision, "collision?", circlecollision_collision, 3);
  rb_define_method(cCircleCollision, "meet?", circlecollision_meet, 3);
  rb_define_method(cCircleCollision, "cover?", circlecollision_cover, 3);
  rb_define_method(cCircleCollision, "covers?", circlecollision_covers, 3);
  rb_define_method(cCircleCollision, "covered?", circlecollision_covered, 3);

  rb_define_method(cCollisions, "collision?", collisions_collision, 2);
  rb_define_method(cCollisions, "meet?", collisions_meet, 2);
  rb_define_method(cCollisions, "cover?", collisions_cover, 2);
  rb_define_method(cCollisions, "covers?", collisions_covers, 2);
  rb_define_method(cCollisions, "covered?", collisions_covered, 2);
  rb_define_method(cCollisions, "collision_all?", collisions_collision_all, 2);
  rb_define_method(cCollisions, "meet_all?", collisions_meet_all, 2);
  rb_define_method(cCollisions, "cover_all?", collisions_cover_all, 2);
  rb_define_method(cCollisions, "covers_all?", collisions_covers_all, 2);
  rb_define_method(cCollisions, "covered_all?", collisions_covered_all, 2);
}
