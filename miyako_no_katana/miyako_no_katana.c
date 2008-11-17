/*
--
Miyako v1.5 Extend Library "Miyako no Katana"
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
=拡張ライブラリmiyako_no_katana
Authors:: サイロス誠
Version:: 1.5pre2
Copyright:: 2007-2008 Cyross Makoto
License:: LGPL2.1
 */
#include <stdlib.h>
#include <math.h>
#include "ruby.h"

#define GET_SHIFT(MASK) ((MASK>>24)&24)|((MASK>>16)&16)|((MASK>>8)&8)
#define GET_VAR(VAR, SHIFT) (VAR>>SHIFT)&0xff
#define COLOR_R 0
#define COLOR_G 1
#define COLOR_B 2
#define COLOR_A 3

VALUE mSDL;
VALUE mMiyako;
VALUE mScreen;
VALUE eMiyakoError;
VALUE cSurface;
VALUE cBitmap;
VALUE cSprite;
VALUE nZero;
ID id_update;
volatile int zero;

static VALUE bitmap_miyako_blit_aa(VALUE self, VALUE src1, VALUE src2, VALUE mx, VALUE my){
  const int bytes_pp = 4;
  int i;

  rb_funcall(src1, rb_intern("lock"), 0);
  rb_funcall(src2, rb_intern("lock"), 0);

  VALUE src1_px = rb_funcall(src1, rb_intern("pixels"), 0);
  VALUE src2_px = rb_funcall(src2, rb_intern("pixels"), 0);
  VALUE s1w = rb_funcall(src1, rb_intern("w"), 0);
  VALUE s1h = rb_funcall(src1, rb_intern("h"), 0);
  VALUE s2w = rb_funcall(src2, rb_intern("w"), 0);
  VALUE s2h = rb_funcall(src2, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src2, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src2, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src2, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src2, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src2, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2ULONG(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int mg_x = NUM2INT(mx);
  int mg_y = NUM2INT(my);
  if(mg_x < 0 || mg_y < 0){ return Qnil; }

  int src_w = NUM2INT(s2w);
  int src_h = NUM2INT(s2h);
  if(NUM2INT(s1w) != src_w || NUM2INT(s1h) != src_h){ return Qnil; }

  int dst_w = src_w + mg_x;
  int dst_h = src_h + mg_y;
  int dst_sz = dst_w * dst_h * bytes_pp;

  char *src1_pixels = RSTRING_PTR(src1_px);
  char *src2_pixels = RSTRING_PTR(src2_px);
  VALUE dst_px = rb_str_new(NULL, dst_sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, dst_sz);

  int dst_len = dst_w * bytes_pp;

  int x, y;
  for(y=0; y<src_h; y++){
    unsigned long *src_p = (unsigned long *)src2_pixels + y * src_w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + (mg_y + y) * dst_w + mg_x;
    for(x=0; x<src_w; x++){ *dst_p++ = *src_p++; }		
  }
  for(y=0; y<src_h; y++){
    unsigned long *src_p = (unsigned long *)src1_pixels + y * src_w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * dst_w;
    for(x=0; x<src_w; x++){
#if 0
      unsigned long pa = GET_VAR(*src_p, shift[COLOR_A]);
      if(pa > 0){ *dst_p = *src_p; }
#else
      unsigned long sr = GET_VAR(*src_p, shift[COLOR_R]);
      unsigned long sg = GET_VAR(*src_p, shift[COLOR_G]);
      unsigned long sb = GET_VAR(*src_p, shift[COLOR_B]);
      unsigned long sa = GET_VAR(*src_p, shift[COLOR_A]);
      unsigned long dr = GET_VAR(*dst_p, shift[COLOR_R]);
      unsigned long dg = GET_VAR(*dst_p, shift[COLOR_G]);
      unsigned long db = GET_VAR(*dst_p, shift[COLOR_B]);
      unsigned long da = GET_VAR(*dst_p, shift[COLOR_A]);

      if(da == 0){ *dst_p = *src_p; }
      else{
	if(sa > 0){
	  dr = ((sr * (sa + 1)) >> 8) + ((dr * (256 - sa)) >> 8);
	  dg = ((sg * (sa + 1)) >> 8) + ((dg * (256 - sa)) >> 8);
	  db = ((sb * (sa + 1)) >> 8) + ((db * (256 - sa)) >> 8);
	  da = 0xff;
	  *dst_p = ((dr << shift[COLOR_R]) | (dg << shift[COLOR_G]) | (db << shift[COLOR_B]) | (da << shift[COLOR_A]));
	}
      }
#endif
      src_p++;
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(dst_w), INT2NUM(dst_h),
			 bpp, INT2NUM(dst_len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src1, rb_intern("unlock"), 0);
  rb_funcall(src2, rb_intern("unlock"), 0);

  return dst;
}

static VALUE bitmap_miyako_blit_aa2(VALUE self, VALUE src1, VALUE src2, VALUE px, VALUE py){
  const int bytes_pp = 4;
  int i;

  rb_funcall(src1, rb_intern("lock"), 0);
  rb_funcall(src2, rb_intern("lock"), 0);

  VALUE src1_px = rb_funcall(src1, rb_intern("pixels"), 0);
  VALUE src2_px = rb_funcall(src2, rb_intern("pixels"), 0);
  VALUE s1w = rb_funcall(src1, rb_intern("w"), 0);
  VALUE s1h = rb_funcall(src1, rb_intern("h"), 0);
  VALUE s2w = rb_funcall(src2, rb_intern("w"), 0);
  VALUE s2h = rb_funcall(src2, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src2, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src2, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src2, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src2, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src2, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2ULONG(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int pt_x = NUM2INT(px);
  int pt_y = NUM2INT(py);
  if(pt_x < 0 || pt_y < 0){ return src2; }

  int src_w = NUM2INT(s1w);
  int src_h = NUM2INT(s1h);

  int dst_w = NUM2INT(s2w);
  int dst_h = NUM2INT(s2h);
  int dst_sz = dst_w * dst_h * bytes_pp;

  char *src1_pixels = RSTRING_PTR(src1_px);
  char *src2_pixels = RSTRING_PTR(src2_px);
  VALUE dst_px = rb_str_new(NULL, dst_sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, dst_sz);

  int dst_len = dst_w * bytes_pp;

  int x, y;
  for(y=0; y<dst_h; y++){
    unsigned long *src2_p = (unsigned long *)src2_pixels + y * dst_w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * dst_w;
#if 0
    for(x=0; x<dst_w; x++){ *dst_p++ = *src2_p++; }
#else
    for(x=0; x<dst_w; x++){
      unsigned long sr = GET_VAR(*src2_p, shift[COLOR_R]);
      unsigned long sg = GET_VAR(*src2_p, shift[COLOR_G]);
      unsigned long sb = GET_VAR(*src2_p, shift[COLOR_B]);
      unsigned long sa = GET_VAR(*src2_p, shift[COLOR_A]);
      unsigned long dr = GET_VAR(*dst_p, shift[COLOR_R]);
      unsigned long dg = GET_VAR(*dst_p, shift[COLOR_G]);
      unsigned long db = GET_VAR(*dst_p, shift[COLOR_B]);
      unsigned long da = GET_VAR(*dst_p, shift[COLOR_A]);

      if(da == 0){ *dst_p = *src2_p; }
      else{
	if(sa > 0){
	  dr = ((sr * (sa + 1)) >> 8) + ((dr * (256 - sa)) >> 8);
	  dg = ((sg * (sa + 1)) >> 8) + ((dg * (256 - sa)) >> 8);
	  db = ((sb * (sa + 1)) >> 8) + ((db * (256 - sa)) >> 8);
	  da = sa;
	  *dst_p = ((dr << shift[COLOR_R]) | (dg << shift[COLOR_G]) | (db << shift[COLOR_B]) | (da << shift[COLOR_A]));
	}
      }
      src2_p++;
      dst_p++;
    }		
#endif
  }
  for(y=0; y<src_h; y++){
    if(pt_y + y >= dst_h){ break; }
    unsigned long *src_p = (unsigned long *)src1_pixels + y * src_w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + (pt_y + y) * dst_w + pt_x;
    for(x=0; x<src_w; x++){
      if(pt_x + x >= dst_w){ break; }

      unsigned long sr = GET_VAR(*src_p, shift[COLOR_R]);
      unsigned long sg = GET_VAR(*src_p, shift[COLOR_G]);
      unsigned long sb = GET_VAR(*src_p, shift[COLOR_B]);
      unsigned long sa = GET_VAR(*src_p, shift[COLOR_A]);
      unsigned long dr = GET_VAR(*dst_p, shift[COLOR_R]);
      unsigned long dg = GET_VAR(*dst_p, shift[COLOR_G]);
      unsigned long db = GET_VAR(*dst_p, shift[COLOR_B]);
      unsigned long da = GET_VAR(*dst_p, shift[COLOR_A]);

      if(da == 0){ *dst_p = *src_p; }
      else{
	if(sa > 0){
	  dr = ((sr * (sa + 1)) >> 8) + ((dr * (256 - sa)) >> 8);
	  dg = ((sg * (sa + 1)) >> 8) + ((dg * (256 - sa)) >> 8);
	  db = ((sb * (sa + 1)) >> 8) + ((db * (256 - sa)) >> 8);
	  da = 0xff;
	  *dst_p = ((dr << shift[COLOR_R]) | (dg << shift[COLOR_G]) | (db << shift[COLOR_B]) | (da << shift[COLOR_A]));
	}
      }
      src_p++;
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(dst_w), INT2NUM(dst_h),
			 bpp, INT2NUM(dst_len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src1, rb_intern("unlock"), 0);
  rb_funcall(src2, rb_intern("unlock"), 0);

  return dst;
}

/*
===画像のαチャネルの値を一定の割合で減少させる
_src_v_:: 対象の画像(Surfaceクラスのインスタンス)
_degree_:: 減少率。0.0<degree<1.0までの実数
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_dec_alpha(VALUE self, VALUE src_v, VALUE degree){
  const int bytes_pp = 4;
  int i;

  rb_funcall(src_v, rb_intern("lock"), 0);

  VALUE src_px = rb_funcall(src_v, rb_intern("pixels"), 0);
  VALUE sw = rb_funcall(src_v, rb_intern("w"), 0);
  VALUE sh = rb_funcall(src_v, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src_v, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src_v, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src_v, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src_v, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src_v, rb_intern("Amask"), 0);
  
  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  double deg = NUM2DBL(degree);

  int w = NUM2INT(sw);
  int h = NUM2INT(sh);

  int sz = w * h * bytes_pp;

  char *src_pixels = RSTRING_PTR(src_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int len = w * bytes_pp;

  unsigned long unmask = 0xffffffff ^ (0xff << shift[COLOR_A]);

  int x, y;
  for(y=0; y<h; y++){
    unsigned long *src_p = (unsigned long *)src_pixels + y * w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * w;
    for(x=0; x<w; x++){
      unsigned long src = *src_p;
      unsigned long pa = GET_VAR(src, shift[COLOR_A]);
      pa = (unsigned long)((double)pa * deg);
      if(pa < 0){ pa = 0; }
      if(pa > 255){ pa = 255; }
      *dst_p = (src & unmask) | (pa << shift[COLOR_A]);
      src_p++;
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(w), INT2NUM(h),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src_v, rb_intern("unlock"), 0);

  return dst;
}

/*
===画像のRGB値を反転させる
αチャネルの値は変更しない
_src_:: 対象の画像(Surfaceクラスのインスタンス)
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_inverse(VALUE self, VALUE src){
  const int bytes_pp = 4;
  int i;

  rb_funcall(src, rb_intern("lock"), 0);

  VALUE src_px = rb_funcall(src, rb_intern("pixels"), 0);
  VALUE sw = rb_funcall(src, rb_intern("w"), 0);
  VALUE sh = rb_funcall(src, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int w = NUM2INT(sw);
  int h = NUM2INT(sh);

  int sz = w * h * bytes_pp;

  char *src_pixels = RSTRING_PTR(src_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int len = w * bytes_pp;

  int x, y;
  for(y=0; y<h; y++){
    unsigned long *src_p = (unsigned long *)src_pixels + y * w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * w;
    for(x=0; x<w; x++){
      unsigned long src = *src_p;
      unsigned long pr = (GET_VAR(src, shift[COLOR_R])) ^ 0xff;
      unsigned long pg = (GET_VAR(src, shift[COLOR_G])) ^ 0xff;
      unsigned long pb = (GET_VAR(src, shift[COLOR_B])) ^ 0xff;
      unsigned long pa = (GET_VAR(src, shift[COLOR_A]));
      *dst_p = ((pr << shift[COLOR_R]) | (pg << shift[COLOR_G]) | (pb << shift[COLOR_B]) | (pa << shift[COLOR_A]));
      src_p++;
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(w), INT2NUM(h),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src, rb_intern("unlock"), 0);

  return dst;
}

/*
===2枚の画像の加算合成を行う
_src1_:: 合成する画像インスタンス(Surfaceクラスのインスタンス)
_src2_:: 合成元の画像インスタンス
_vmx_:: src1をsrc2上に貼り付けるときに補正する位置
_vmy_:: src1をsrc2上に貼り付けるときに補正する位置
返却値:: 合成後の画像インスタンス
*/
static VALUE bitmap_miyako_additive_synthesis(VALUE self, VALUE src1, VALUE src2, VALUE vmx, VALUE vmy){
  const int bytes_pp = 4;
  int i;
  
  rb_funcall(src1, rb_intern("lock"), 0);
  rb_funcall(src2, rb_intern("lock"), 0);

  VALUE src1_px = rb_funcall(src1, rb_intern("pixels"), 0);
  VALUE s1w = rb_funcall(src1, rb_intern("w"), 0);
  VALUE s1h = rb_funcall(src1, rb_intern("h"), 0);
  VALUE src2_px = rb_funcall(src2, rb_intern("pixels"), 0);
  VALUE s2w = rb_funcall(src2, rb_intern("w"), 0);
  VALUE s2h = rb_funcall(src2, rb_intern("h"), 0);

  int w1 = NUM2INT(s1w);
  int h1 = NUM2INT(s1h);
  int w2 = NUM2INT(s2w);
  int h2 = NUM2INT(s2h);
  int mx = NUM2INT(vmx);
  int my = NUM2INT(vmy);

  if(mx < 0 || my < 0){ return Qnil; }
  if(mx >= w2 || my >= h2){ return Qnil; }

  VALUE bpp = rb_funcall(src2, rb_intern("bpp"), 0);

  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src2, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src2, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src2, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src2, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int sz = w2 * h2 * bytes_pp;

  char *src1_pixels = RSTRING_PTR(src1_px);
  char *src2_pixels = RSTRING_PTR(src2_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int len = w2 * bytes_pp;

  unsigned long unmask = 0xffffffff ^ (0xff << shift[COLOR_A]);

  if(mx + w1 > w2){ w1 -= (mx + w1 - w2); }
  if(my + h1 > h2){ h1 -= (my + h1 - h2); }
	
  int x, y;
  for(y=0; y<h2; y++){
    unsigned long *src2_p = (unsigned long *)src2_pixels + y * w2;
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * w2;
    for(x=0; x<w2; x++){ *dst_p++ = *src2_p++; }
  }
  for(y=0; y<h1; y++){
    unsigned long *src1_p = (unsigned long *)src1_pixels + y * w1;
    unsigned long *dst_p = (unsigned long *)dst_pixels + (y + my) * w2 + mx;
    for(x=0; x<w1; x++){
      unsigned long src1 = *src1_p;
      unsigned long dst1 = *dst_p;
      unsigned long pa1 = (GET_VAR(src1, shift[COLOR_A]));
      unsigned long pa2 = (GET_VAR(dst1, shift[COLOR_A]));
      unsigned long pr = (GET_VAR(src1, shift[COLOR_R])) + (GET_VAR(dst1, shift[COLOR_R]));
      unsigned long pg = (GET_VAR(src1, shift[COLOR_G])) + (GET_VAR(dst1, shift[COLOR_G]));
      unsigned long pb = (GET_VAR(src1, shift[COLOR_B])) + (GET_VAR(dst1, shift[COLOR_B]));
      if(pa1 == 0){
	src1_p++;
	dst_p++;
	continue;
      }
      if(pr > 0xff) pr = 0xff;
      if(pg > 0xff) pg = 0xff;
      if(pb > 0xff) pb = 0xff;
      *dst_p = ((pr << shift[COLOR_R]) | (pg << shift[COLOR_G]) | (pb << shift[COLOR_B]) | ((pa1>pa2?pa1:pa2) << shift[COLOR_A]));
      src1_p++;
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(w2), INT2NUM(h2),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src1, rb_intern("unlock"), 0);
  rb_funcall(src2, rb_intern("unlock"), 0);

  return dst;
}

/*
===2枚の画像の減算合成を行う
_src1_:: 合成する画像インスタンス(Surfaceクラスのインスタンス)
_src2_:: 合成元の画像インスタンス
_vmx_:: src1をsrc2上に貼り付けるときに補正する位置
_vmy_:: src1をsrc2上に貼り付けるときに補正する位置
返却値:: 合成後の画像インスタンス
*/
static VALUE bitmap_miyako_subtraction_synthesis(VALUE self, VALUE src1, VALUE src2, VALUE vmx, VALUE vmy){
  VALUE inv_bitmap = bitmap_miyako_inverse(self, src2);
  VALUE add_bitmap = bitmap_miyako_additive_synthesis(self, src1, inv_bitmap, vmx, vmy);
  return bitmap_miyako_inverse(self, add_bitmap);
}

/*
===画像を回転させる
画像を回転させる際に、縦横の大きさが違っているときは、長辺に合わせた正方形で出力される

引数<i>size_force</i>がfalseのときは、<b>画像サイズが1.5倍になる</b>ことに注意すること

(特にメモリ周り！)

<i>size_force_</i>がtrueのときは画像サイズは変化しないが、画像の一部が欠けたり大幅に崩れるため、注意すること

_src_:: 回転元の画像
_radian_:: 回転角度。反時計回りに回転する。単位はラジアン。範囲は0.0〜Math::PI*2
_size_force_:: trueのときは、回転による画像の大きさの変更を行わない。規定値はfalse
返却値:: 回転後の画像インスタンス
*/
static VALUE bitmap_miyako_rotate(int argc, VALUE *argv, VALUE self){
  const int bytes_pp = 4;
  int i;

  VALUE src, radian, size_force;
  rb_scan_args(argc, argv, "21", &src, &radian, &size_force);
  
  rb_funcall(src, rb_intern("lock"), 0);

  VALUE src_px = rb_funcall(src, rb_intern("pixels"), 0);
  VALUE sw = rb_funcall(src, rb_intern("w"), 0);
  VALUE sh = rb_funcall(src, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int w = NUM2INT(sw);
  int h = NUM2INT(sh);

  if(w >= 32768 || h >= 32768){ return self; }

  int org_center_x = w >> 1;
  int org_center_y = h >> 1;
  int new_w = w + (size_force == Qtrue ? 0 : org_center_x);
  int new_h = h + (size_force == Qtrue ? 0 : org_center_y);
  if(new_w > new_h){ new_h = new_w; }
  int new_center_x = new_w >> 1;
  int new_center_y = new_h >> 1;

  int sz = new_w * new_h * bytes_pp;

  char *src_pixels = RSTRING_PTR(src_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int len = new_w * bytes_pp;

  double rad = NUM2DBL(radian);
  long isin = (long)(sin(rad)*4096.0);
  long icos = (long)(cos(rad)*4096.0);

  int x, y;
  unsigned long *src_p;
  for(y=0; y<new_h; y++){
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * new_w;
    for(x=0; x<new_w; x++){
      int nx = (((x-new_center_x)*icos-(y-new_center_y)*isin) >> 12) + org_center_x;
      int ny = (((x-new_center_x)*isin+(y-new_center_y)*icos) >> 12) + org_center_y;
      if(nx < 0 || nx >= w || ny < 0 || ny >= h){ dst_p++; continue; }
      *dst_p = *((unsigned long *)src_pixels + ny * w + nx);
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(new_w), INT2NUM(new_h),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src, rb_intern("unlock"), 0);

  return dst;
}

/*
===画像を拡大・縮小・反転させる
_src_:: 変形元の画像
_scale_x_:: x軸の拡大率。-1を指定すると、y軸方向のミラー反転となる
_scale_y_:: y軸の拡大率。-1を指定すると、x軸方向のミラー反転となる
返却値:: 変形後の画像インスタンス
*/
static VALUE bitmap_miyako_scale(VALUE self, VALUE src, VALUE scale_x, VALUE scale_y){
  const int bytes_pp = 4;
  int i;

  rb_funcall(src, rb_intern("lock"), 0);

  VALUE src_px = rb_funcall(src, rb_intern("pixels"), 0);
  VALUE sw = rb_funcall(src, rb_intern("w"), 0);
  VALUE sh = rb_funcall(src, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int w = NUM2INT(sw);
  int h = NUM2INT(sh);

  if(w >= 32768 || h >= 32768){ return self; }

  double scx = NUM2DBL(scale_x);
  double scy = NUM2DBL(scale_y);
  double ascx = scx < 0.0 ? -scx : scx;
  double ascy = scy < 0.0 ? -scy : scy;

  if(scx == 0.0 || scy == 0.0){ return self; }

  int new_w = (int)((double)w * ascx);
  int new_h = (int)((double)h * ascy);

  if(new_w == 0 || new_h == 0 || new_w >= 32768 || new_h >= 32768){ return self; }

  scx = 1.0 / scx;
  scy = 1.0 / scy;

  int org_center_x = w >> 1;
  int org_center_y = h >> 1;
  int new_center_x = new_w >> 1;
  int new_center_y = new_h >> 1;

  int sz = new_w * new_h * bytes_pp;

  char *src_pixels = RSTRING_PTR(src_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int len = new_w * bytes_pp;

  int off_x = scx < 0 ? 1 : 0;
  int off_y = scy < 0 ? 1 : 0;

  int x, y;
  unsigned long *src_p;
  for(y=0; y<new_h; y++){
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * new_w;
    for(x=0; x<new_w; x++){
      int nx = (int)((double)(x-new_center_x) * scx) + org_center_x - off_x;
      int ny = (int)((double)(y-new_center_y) * scy) + org_center_y - off_y;
      *dst_p = *((unsigned long *)src_pixels + ny * w + nx);
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(new_w), INT2NUM(new_h),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src, rb_intern("unlock"), 0);

  return dst;
}

/*
===画像を変形(回転・拡大・縮小・反転)させる
画像を回転させる際に、縦横の大きさが違っているときは、長辺に合わせた正方形で出力される

引数<i>size_force</i>がfalseのときは、<b>画像サイズが1.5倍になる</b>ことに注意すること

(特にメモリ周り！)

<i>size_force_</i>がtrueのときは画像サイズは変化しないが、画像の一部が欠けたり大幅に崩れるため、注意すること

_src_:: 変形元の画像
_radian_:: 回転角度。反時計回りに回転する。単位はラジアン。範囲は0.0〜Math::PI*2
_scale_x_:: x軸の拡大率。-1を指定すると、y軸方向のミラー反転となる
_scale_y_:: y軸の拡大率。-1を指定すると、x軸方向のミラー反転となる
_size_force_:: trueのときは、回転による画像の大きさの変更を行わない。規定値はfalse
返却値:: 変形後の画像インスタンス
*/
static VALUE bitmap_miyako_transform(int argc, VALUE *argv, VALUE self){
  const int bytes_pp = 4;
  int i;

  VALUE src, radian, scale_x, scale_y, size_force;
  rb_scan_args(argc, argv, "41", &src, &radian, &scale_x, &scale_y, &size_force);
  
  rb_funcall(src, rb_intern("lock"), 0);

  VALUE src_px = rb_funcall(src, rb_intern("pixels"), 0);
  VALUE sw = rb_funcall(src, rb_intern("w"), 0);
  VALUE sh = rb_funcall(src, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int w = NUM2INT(sw);
  int h = NUM2INT(sh);

  if(w >= 32768 || h >= 32768){ return self; }

  double rad = NUM2DBL(radian);
  long isin = (long)(sin(rad)*4096.0);
  long icos = (long)(cos(rad)*4096.0);

  double scx = NUM2DBL(scale_x);
  double scy = NUM2DBL(scale_y);
  double ascx = scx < 0.0 ? -scx : scx;
  double ascy = scy < 0.0 ? -scy : scy;

  if(scx == 0.0 || scy == 0.0){ return self; }

  int org_center_x = w >> 1;
  int org_center_y = h >> 1;
  int new_w = (int)((double)(w + (size_force == Qtrue ? 0 : org_center_x)) * ascx);
  int new_h = (int)((double)(h + (size_force == Qtrue ? 0 : org_center_y)) * ascy);
  if(new_w > new_h){ new_h = new_w; }
  int new_center_x = new_w >> 1;
  int new_center_y = new_h >> 1;

  if(new_w == 0 || new_h == 0 || new_w >= 32768 || new_h >= 32768){ return self; }

  scx = 1.0 / scx;
  scy = 1.0 / scy;

  int sz = new_w * new_h * bytes_pp;
  int len = new_w * bytes_pp;

  char *src_pixels = RSTRING_PTR(src_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int off_x = scx < 0 ? 1 : 0;
  int off_y = scy < 0 ? 1 : 0;

  int x, y;
  unsigned long *src_p;
  for(y=0; y<new_h; y++){
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * new_w;
    for(x=0; x<new_w; x++){
      int nx = (int)((double)(((x-new_center_x)*icos-(y-new_center_y)*isin) >> 12) * scx) + org_center_x - off_x;
      int ny = (int)((double)(((x-new_center_x)*isin+(y-new_center_y)*icos) >> 12) * scy) + org_center_y - off_y;
      if(nx < 0 || nx >= w || ny < 0 || ny >= h){ dst_p++; continue; }
      *dst_p = *((unsigned long *)src_pixels + ny * w + nx);
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(new_w), INT2NUM(new_h),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src, rb_intern("unlock"), 0);

  return dst;
}

/*
===自分自身のαチャネルの値を一定の割合で減少させる
_degree_:: 減少率。0.0<degree<1.0までの実数
返却値:: 変更後の画像インスタンス
*/
static VALUE surface_miyako_dec_alpha(VALUE self, VALUE degree){
  return bitmap_miyako_dec_alpha(cBitmap, self, degree);
}

/*
===自分自身のRGB値を反転させる
αチャネルの値は変更しない
返却値:: 変更後の画像インスタンス
*/
static VALUE surface_miyako_inverse(VALUE self){
  return bitmap_miyako_inverse(cBitmap, self);
}

/*
===自分自身との2枚の画像の加算合成を行う
_src2_:: 合成元の画像インスタンス
_vmx_:: src2上に貼り付けるときに補正する位置
_vmy_:: src2上に貼り付けるときに補正する位置
返却値:: 合成後の画像インスタンス
*/
static VALUE surface_miyako_additive_synthesis(VALUE self, VALUE src2, VALUE vmx, VALUE vmy){
  return bitmap_miyako_additive_synthesis(cBitmap, self, src2, vmx, vmy);
}

/*
===自分自身との2枚の画像の減算合成を行う
_src2_:: 合成元の画像インスタンス
_vmx_:: src2上に貼り付けるときに補正する位置
_vmy_:: src2上に貼り付けるときに補正する位置
返却値:: 合成後の画像インスタンス
*/
static VALUE surface_miyako_subtraction_synthesis(VALUE self, VALUE src2, VALUE vmx, VALUE vmy){
  return bitmap_miyako_subtraction_synthesis(cBitmap, self, src2, vmx, vmy);
}

/*
===自分自身を回転させる
画像を回転させる際に、縦横の大きさが違っているときは、長辺に合わせた正方形で出力される

引数<i>size_force</i>がfalseのときは、<b>画像サイズが1.5倍になる</b>ことに注意すること

(特にメモリ周り！)

<i>size_force_</i>がtrueのときは画像サイズは変化しないが、画像の一部が欠けたり大幅に崩れるため、注意すること

_radian_:: 回転角度。反時計回りに回転する。単位はラジアン。範囲は0.0〜Math::PI*2
_size_force_:: trueのときは、回転による画像の大きさの変更を行わない。規定値はfalse
返却値:: 回転後の画像インスタンス
*/
static VALUE surface_miyako_rotate(int argc, VALUE *argv, VALUE self){
  VALUE *new_p = ALLOC_N(VALUE, argc+1);
  *new_p = self;
  int i;
  for(i=0; i<argc; i++){ *(new_p+i+1) = *(argv+i); }
  VALUE ret = bitmap_miyako_rotate(argc+1, new_p, cBitmap);
  free(new_p);
  return ret;
}

/*
===自分自身を拡大・縮小・反転させる
_scale_x_:: x軸の拡大率。-1を指定すると、y軸方向のミラー反転となる
_scale_y_:: y軸の拡大率。-1を指定すると、x軸方向のミラー反転となる
返却値:: 変形後の画像インスタンス
*/
static VALUE surface_miyako_scale(VALUE self, VALUE scale_x, VALUE scale_y){
  return bitmap_miyako_scale(cBitmap, self, scale_x, scale_y);
}

/*
===自分自身を変形(回転・拡大・縮小・反転)させる
画像を回転させる際に、縦横の大きさが違っているときは、長辺に合わせた正方形で出力される

引数<i>size_force</i>がfalseのときは、<b>画像サイズが1.5倍になる</b>ことに注意すること

(特にメモリ周り！)

<i>size_force_</i>がtrueのときは画像サイズは変化しないが、画像の一部が欠けたり大幅に崩れるため、注意すること

_radian_:: 回転角度。反時計回りに回転する。単位はラジアン。範囲は0.0〜Math::PI*2
_scale_x_:: x軸の拡大率。-1を指定すると、y軸方向のミラー反転となる
_scale_y_:: y軸の拡大率。-1を指定すると、x軸方向のミラー反転となる
_size_force_:: trueのときは、回転による画像の大きさの変更を行わない。規定値はfalse
返却値:: 変形後の画像インスタンス
*/
static VALUE surface_miyako_transform(int argc, VALUE *argv, VALUE self){
  VALUE *new_p = ALLOC_N(VALUE, argc+1);
  *new_p = self;
  int i;
  for(i=0; i<argc; i++){ *(new_p+i+1) = *(argv+i); }
  VALUE ret = bitmap_miyako_transform(argc+1, new_p, cBitmap);
  free(new_p);
  return ret;
}

static void bitmap_miyako_rgb_to_hsv(double r, double g, double b, double *h, double *s, double *v){
  double max = r;
  double min = max;
  max = max < g ? g : max;
  max = max < b ? b : max;
  min = min > g ? g : min;
  min = min > b ? b : min;
  *v = max;
  if(*v == 0.0){ *h = 0.0; *s = 0.0; return; }
  *s = (max - min) / max;
  if(*s == 0.0){ *h = 0.0; return; }
  double cr = (max - r)/(max - min);
  double cg = (max - g)/(max - min);
  double cb = (max - b)/(max - min);
  if(max == r){ *h = cb - cg; }
  if(max == g){ *h = 2.0 + cr - cb; }
  if(max == b){ *h = 4.0 + cg - cr; }
  *h *= 60.0;
  if(*h < 0){ *h += 360.0; }
}

static void bitmap_miyako_hsv_to_rgb(double h, double s, double v, double *r, double *g, double *b){
  if(s == 0.0){ *r = *g = *b = v; return; }
  double i = h / 60.0;
  if(     i < 1.0){ i = 0.0; }
  else if(i < 2.0){ i = 1.0; }
  else if(i < 3.0){ i = 2.0; }
  else if(i < 4.0){ i = 3.0; }
  else if(i < 5.0){ i = 4.0; }
  else if(i < 6.0){ i = 5.0; }
  double f = h / 60.0 - i;
  double m = v * (1 - s);
  double n = v * (1 - s * f);
  double k = v * (1 - s * (1 - f));
  if(     i == 0.0){ *r = v; *g = k, *b = m; }
  else if(i == 1.0){ *r = n; *g = v, *b = m; }
  else if(i == 2.0){ *r = m; *g = v, *b = k; }
  else if(i == 3.0){ *r = m; *g = n, *b = v; }
  else if(i == 4.0){ *r = k; *g = m, *b = v; }
  else if(i == 5.0){ *r = v; *g = m, *b = n; }
}

/*
===画像の色相を変更する
_src_:: 変更元の画像
_radian_:: 色相の変更量。単位はラジアン。範囲は0.0〜Math::PI*2
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_hue(VALUE self, VALUE src, VALUE radian){
  const int bytes_pp = 4;
  int i;

  rb_funcall(src, rb_intern("lock"), 0);

  VALUE src_px = rb_funcall(src, rb_intern("pixels"), 0);
  VALUE sw = rb_funcall(src, rb_intern("w"), 0);
  VALUE sh = rb_funcall(src, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int w = NUM2INT(sw);
  int h = NUM2INT(sh);

  int sz = w * h * bytes_pp;

  char *src_pixels = RSTRING_PTR(src_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int len = w * bytes_pp;

  double deg = (NUM2DBL(radian) * 180.0) / 3.14;

  int x, y;
  long pr, pg, pb, pa;
  double ph, ps, pv;
  double d_pi = M_PI * 2;
  for(y=0; y<h; y++){
    unsigned long *src_p = (unsigned long *)src_pixels + y * w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * w;
    for(x=0; x<w; x++){
      unsigned long src = *src_p;
      double pr_d = (double)(GET_VAR(src, shift[COLOR_R])) / 255.0;
      double pg_d = (double)(GET_VAR(src, shift[COLOR_G])) / 255.0;
      double pb_d = (double)(GET_VAR(src, shift[COLOR_B])) / 255.0;
      pa = GET_VAR(src, shift[COLOR_A]);
      bitmap_miyako_rgb_to_hsv(pr_d, pg_d, pb_d, &ph, &ps, &pv);
      ph += deg;
      if(ph < 0.0){ while(ph >= 0.0){ ph += d_pi; } }
      if(ph > d_pi){ while(ph <= d_pi){ ph -= d_pi; } }
      bitmap_miyako_hsv_to_rgb(ph, ps, pv, &pr_d, &pg_d, &pb_d);
      pr = (unsigned long)(pr_d * 255.0);
      pg = (unsigned long)(pg_d * 255.0);
      pb = (unsigned long)(pb_d * 255.0);
      *dst_p = ((pr << shift[COLOR_R]) | (pg << shift[COLOR_G]) | (pb << shift[COLOR_B]) | (pa << shift[COLOR_A]));
      src_p++;
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(w), INT2NUM(h),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src, rb_intern("unlock"), 0);

  return dst;
}

/*
===画像の彩度を変更する
_src_:: 変更元の画像
_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_saturation(VALUE self, VALUE src, VALUE saturation){
  const int bytes_pp = 4;
  int i;

  rb_funcall(src, rb_intern("lock"), 0);

  VALUE src_px = rb_funcall(src, rb_intern("pixels"), 0);
  VALUE sw = rb_funcall(src, rb_intern("w"), 0);
  VALUE sh = rb_funcall(src, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int w = NUM2INT(sw);
  int h = NUM2INT(sh);

  int sz = w * h * bytes_pp;

  char *src_pixels = RSTRING_PTR(src_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int len = w * bytes_pp;

  double sat = NUM2DBL(saturation);

  int x, y;
  long pr, pg, pb, pa;
  double ph, ps, pv;
  for(y=0; y<h; y++){
    unsigned long *src_p = (unsigned long *)src_pixels + y * w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * w;
    for(x=0; x<w; x++){
      unsigned long src = *src_p;
      double pr_d = (double)(GET_VAR(src, shift[COLOR_R])) / 255.0;
      double pg_d = (double)(GET_VAR(src, shift[COLOR_G])) / 255.0;
      double pb_d = (double)(GET_VAR(src, shift[COLOR_B])) / 255.0;
      pa = GET_VAR(src, shift[COLOR_A]);
      bitmap_miyako_rgb_to_hsv(pr_d, pg_d, pb_d, &ph, &ps, &pv);
      ps += sat;
      if(ps < 0.0){ ps = 0.0; }
      if(ps > 1.0){ ps = 1.0; }
      bitmap_miyako_hsv_to_rgb(ph, ps, pv, &pr_d, &pg_d, &pb_d);
      pr = (unsigned long)(pr_d * 255);
      pg = (unsigned long)(pg_d * 255);
      pb = (unsigned long)(pb_d * 255);
      *dst_p = ((pr << shift[COLOR_R]) | (pg << shift[COLOR_G]) | (pb << shift[COLOR_B]) | (pa << shift[COLOR_A]));
      src_p++;
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(w), INT2NUM(h),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src, rb_intern("unlock"), 0);

  return dst;
}

/*
===画像の明度を変更する
_src_:: 変更元の画像
_value_:: 明度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_value(VALUE self, VALUE src, VALUE value){
  const int bytes_pp = 4;
  int i;

  rb_funcall(src, rb_intern("lock"), 0);

  VALUE src_px = rb_funcall(src, rb_intern("pixels"), 0);
  VALUE sw = rb_funcall(src, rb_intern("w"), 0);
  VALUE sh = rb_funcall(src, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int w = NUM2INT(sw);
  int h = NUM2INT(sh);

  int sz = w * h * bytes_pp;

  char *src_pixels = RSTRING_PTR(src_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int len = w * bytes_pp;

  double val = NUM2DBL(value);

  int x, y;
  long pr, pg, pb, pa;
  double ph, ps, pv;
  for(y=0; y<h; y++){
    unsigned long *src_p = (unsigned long *)src_pixels + y * w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * w;
    for(x=0; x<w; x++){
      unsigned long src = *src_p;
      double pr_d = (double)(GET_VAR(src, shift[COLOR_R])) / 255.0;
      double pg_d = (double)(GET_VAR(src, shift[COLOR_G])) / 255.0;
      double pb_d = (double)(GET_VAR(src, shift[COLOR_B])) / 255.0;
      pa = GET_VAR(src, shift[COLOR_A]);
      bitmap_miyako_rgb_to_hsv(pr_d, pg_d, pb_d, &ph, &ps, &pv);
      pv += val;
      if(pv < 0.0){ pv = 0.0; }
      if(pv > 1.0){ pv = 1.0; }
      bitmap_miyako_hsv_to_rgb(ph, ps, pv, &pr_d, &pg_d, &pb_d);
      pr = (unsigned long)(pr_d * 255);
      pg = (unsigned long)(pg_d * 255);
      pb = (unsigned long)(pb_d * 255);
      *dst_p = ((pr << shift[COLOR_R]) | (pg << shift[COLOR_G]) | (pb << shift[COLOR_B]) | (pa << shift[COLOR_A]));
      src_p++;
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(w), INT2NUM(h),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src, rb_intern("unlock"), 0);

  return dst;
}

/*
===画像の色相・彩度・明度を変更する
_radian_:: 色相の変更量。単位はラジアン。範囲は0.0〜Math::PI*2
_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
_value_:: 明度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE bitmap_miyako_hsv(VALUE self, VALUE src, VALUE radian, VALUE saturation, VALUE value){
  const int bytes_pp = 4;
  int i;

  rb_funcall(src, rb_intern("lock"), 0);

  VALUE src_px = rb_funcall(src, rb_intern("pixels"), 0);
  VALUE sw = rb_funcall(src, rb_intern("w"), 0);
  VALUE sh = rb_funcall(src, rb_intern("h"), 0);
  VALUE bpp = rb_funcall(src, rb_intern("bpp"), 0);
  VALUE Mask[bytes_pp];
  Mask[0] = rb_funcall(src, rb_intern("Rmask"), 0);
  Mask[1] = rb_funcall(src, rb_intern("Gmask"), 0);
  Mask[2] = rb_funcall(src, rb_intern("Bmask"), 0);
  Mask[3] = rb_funcall(src, rb_intern("Amask"), 0);

  unsigned long mask[bytes_pp];
  unsigned long shift[bytes_pp];
  for(i=0; i<bytes_pp; i++){
    mask[i] = NUM2UINT(Mask[i]);
    shift[i] = GET_SHIFT(mask[i]);
  }

  int w = NUM2INT(sw);
  int h = NUM2INT(sh);

  int sz = w * h * bytes_pp;

  char *src_pixels = RSTRING_PTR(src_px);
  VALUE dst_px = rb_str_new(NULL, sz);
  char *dst_pixels = RSTRING_PTR(dst_px);
  memset(dst_pixels, 0, sz);

  int len = w * bytes_pp;

  double deg = (NUM2DBL(radian) * 180.0) / 3.14;
  double sat = NUM2DBL(saturation);
  double val = NUM2DBL(value);

  int x, y;
  long pr, pg, pb, pa;
  double ph, ps, pv;
  for(y=0; y<h; y++){
    unsigned long *src_p = (unsigned long *)src_pixels + y * w;
    unsigned long *dst_p = (unsigned long *)dst_pixels + y * w;
    for(x=0; x<w; x++){
      unsigned long src = *src_p;
      double pr_d = (double)(GET_VAR(src, shift[COLOR_R])) / 255.0;
      double pg_d = (double)(GET_VAR(src, shift[COLOR_G])) / 255.0;
      double pb_d = (double)(GET_VAR(src, shift[COLOR_B])) / 255.0;
      pa = GET_VAR(src, shift[COLOR_A]);
      bitmap_miyako_rgb_to_hsv(pr_d, pg_d, pb_d, &ph, &ps, &pv);

      ph += deg;
      if(ph < 0.0){ ph += 360.0; }
      if(ph > 360.0){ ph -= 360.0; }

      ps += sat;
      if(ps < 0.0){ ps = 0.0; }
      if(ps > 1.0){ ps = 1.0; }

      pv += val;
      if(pv < 0.0){ pv = 0.0; }
      if(pv > 1.0){ pv = 1.0; }

      bitmap_miyako_hsv_to_rgb(ph, ps, pv, &pr_d, &pg_d, &pb_d);
      pr = (unsigned long)(pr_d * 255);
      pg = (unsigned long)(pg_d * 255);
      pb = (unsigned long)(pb_d * 255);
      *dst_p = ((pr << shift[COLOR_R]) | (pg << shift[COLOR_G]) | (pb << shift[COLOR_B]) | (pa << shift[COLOR_A]));
      src_p++;
      dst_p++;
    }		
  }

  VALUE dst = rb_funcall(cSurface, rb_intern("new_from"), 9, 
			 dst_px, 
			 INT2NUM(w), INT2NUM(h),
			 bpp, INT2NUM(len), 
			 Mask[COLOR_R], Mask[COLOR_G], Mask[COLOR_B], Mask[COLOR_A]);

  rb_funcall(src, rb_intern("unlock"), 0);

  return dst;
}

/*
===自分自身の色相を変更する
_radian_:: 色相の変更量。単位はラジアン。範囲は0.0〜Math::PI*2
返却値:: 変更後の画像インスタンス
*/
static VALUE surface_miyako_hue(VALUE self, VALUE radian){
  return bitmap_miyako_hue(cBitmap, self, radian);
}

/*
===自分自身の彩度を変更する
_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE surface_miyako_saturation(VALUE self, VALUE saturation){
  return bitmap_miyako_saturation(cBitmap, self, saturation);
}

/*
===自分自身の明度を変更する
_value_:: 明度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE surface_miyako_value(VALUE self, VALUE value){
  return bitmap_miyako_value(cBitmap, self, value);
}

/*
===自分自身画像の色相・彩度・明度を変更する
_radian_:: 色相の変更量。単位はラジアン。範囲は0.0〜Math::PI*2
_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
_value_:: 明度の変更量。範囲は0.0〜1.0の実数
返却値:: 変更後の画像インスタンス
*/
static VALUE surface_miyako_hsv(VALUE self, VALUE radian, VALUE saturation, VALUE value){
  return bitmap_miyako_hsv(cBitmap, self, radian, saturation, value);
}

void Init_miyako_no_katana(){
  mSDL = rb_define_module("SDL");
  mMiyako = rb_define_module("Miyako");
  mScreen = rb_define_module_under(mMiyako, "Screen");
  eMiyakoError  = rb_define_class_under(mMiyako, "MiyakoError", rb_eException);
  cSurface = rb_define_class_under(mSDL, "Surface", rb_cObject);
  cBitmap = rb_define_class_under(mMiyako, "Bitmap", rb_cObject);
  cSprite = rb_define_class_under(mMiyako, "Sprite", rb_cObject);

  zero = 0;
  nZero = INT2NUM(zero);

  rb_define_singleton_method(cBitmap, "miyako_blit_aa", bitmap_miyako_blit_aa, 4);
  rb_define_singleton_method(cBitmap, "miyako_blit_aa2", bitmap_miyako_blit_aa2, 4);
  rb_define_singleton_method(cBitmap, "dec_alpha", bitmap_miyako_dec_alpha, 2);
  rb_define_singleton_method(cBitmap, "additive", bitmap_miyako_additive_synthesis, 4);
  rb_define_singleton_method(cBitmap, "subtraction", bitmap_miyako_subtraction_synthesis, 4);
  rb_define_singleton_method(cBitmap, "inverse", bitmap_miyako_inverse, 1);
  rb_define_singleton_method(cBitmap, "rotate", bitmap_miyako_rotate, -1);
  rb_define_singleton_method(cBitmap, "scale", bitmap_miyako_scale, 3);
  rb_define_singleton_method(cBitmap, "transform", bitmap_miyako_transform, -1);

  rb_define_singleton_method(cBitmap, "hue", bitmap_miyako_hue, 2);
  rb_define_singleton_method(cBitmap, "saturation", bitmap_miyako_saturation, 2);
  rb_define_singleton_method(cBitmap, "value", bitmap_miyako_value, 2);
  rb_define_singleton_method(cBitmap, "hsv", bitmap_miyako_hsv, 4);

  rb_define_method(cSurface, "miyako_dec_alpha", surface_miyako_dec_alpha, 1);
  rb_define_method(cSurface, "miyako_additive", surface_miyako_additive_synthesis, 3);
  rb_define_method(cSurface, "miyako_subtraction", surface_miyako_subtraction_synthesis, 3);
  rb_define_method(cSurface, "miyako_inverse", surface_miyako_inverse, 0);
  rb_define_method(cSurface, "miyako_rotate", surface_miyako_rotate, -1);
  rb_define_method(cSurface, "miyako_scale", surface_miyako_scale, 2);
  rb_define_method(cSurface, "miyako_transform", surface_miyako_transform, -1);

  rb_define_method(cSurface, "miyako_hue", surface_miyako_hue, 1);
  rb_define_method(cSurface, "miyako_saturation", surface_miyako_saturation, 1);
  rb_define_method(cSurface, "miyako_value", surface_miyako_value, 1);
  rb_define_method(cSurface, "miyako_hsv", surface_miyako_hsv, 3);

}
