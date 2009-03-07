# -*- encoding: utf-8 -*-
=begin
--
Miyako v2.0
Copyright (C) 2007-2009  Cyross Makoto

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
=end

# ビットマップ関連クラス群
module Miyako
  #==ビットマップ(画像)管理クラス
  #SDLのSurfaceクラスインスタンスを管理するクラス
  class Bitmap
    def Bitmap.create(w, h, flag=SDL::HWSURFACE | SDL::SRCCOLORKEY | SDL::SRCALPHA) #:nodoc:
      return SDL::Surface.new(flag, w, h, 32, Screen.screen.Rmask, Screen.screen.Gmask, Screen.screen.Bmask, Screen.screen.Amask)
    end

    def Bitmap.load(filename) #:nodoc:
      return SDL::Surface.load(filename)
    end

    #===画像をαチャネル付き画像へ転送する
    #範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。
    #src==dstの場合、何も行わない
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_x_:: 転送先の転送開始位置(x方向・単位：ピクセル)
    #_y_:: 転送先の転送開始位置(y方向・単位：ピクセル)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.blit_aa!(src, dst, x, y)
    end

    #===２つの画像のandを取り、別の画像へ転送する
    #範囲は、src1側SpriteUnitとsrc2側との(ow,oh)の小さい方の範囲で転送する。
    #src1とsrc2の合成は、src2側SpriteUnitの(x,y)をsrc1側の起点として、src2側SpriteUnitの(ow,oh)の範囲で転送する。
    #dst側は、src1側SpriteUnitの(x,y)を起点に転送する。
    #以下の条件のどれかに合致しているとき、転送を行わなずにnilを返す
    #1.src1とsrc2のどちらかが、もう一方の内側にない
    #2.src2の大きさとdstの大きさが違う
    #3.src1==src2の場合、何も行わない
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src1,src2,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る。
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src1側SpriteUnit,src2側SpriteUnit,dst側SpriteUnit|となる。
    #_src1_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_src2_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.blit_and!(src1, src2, dst)
    end

    #===２つの画像のorを取り、別の画像へ転送する
    #範囲は、src1側SpriteUnitとsrc2側との(ow,oh)の小さい方の範囲で転送する。
    #src1とsrc2の合成は、src2側SpriteUnitの(x,y)をsrc1側の起点として、src2側SpriteUnitの(ow,oh)の範囲で転送する。
    #dst側は、src1側SpriteUnitの(x,y)を起点に転送する。
    #以下の条件のどれかに合致しているとき、転送を行わなずにnilを返す
    #1.src1とsrc2のどちらかが、もう一方の内側にない
    #2.src2の大きさとdstの大きさが違う
    #3.src1==src2の場合、何も行わない
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src1,src2,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る)
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src1側SpriteUnit,src2側SpriteUnit,dst側SpriteUnit|となる。
    #_src1_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_src2_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.blit_or!(src1, src2, dst)
    end

    #===２つの画像のxorを取り、別の画像へ転送する
    #範囲は、src1側SpriteUnitとsrc2側との(ow,oh)の小さい方の範囲で転送する。
    #src1とsrc2の合成は、src2側SpriteUnitの(x,y)をsrc1側の起点として、src2側SpriteUnitの(ow,oh)の範囲で転送する。
    #dst側は、src1側SpriteUnitの(x,y)を起点に転送する。
    #以下の条件のどれかに合致しているとき、転送を行わなずにnilを返す
    #1.src1とsrc2のどちらかが、もう一方の内側にない
    #2.src2の大きさとdstの大きさが違う
    #3.src1==src2の場合、何も行わない
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src1,src2,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src1側SpriteUnit,src2側SpriteUnit,dst側SpriteUnit|となる。
    #_src1_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_src2_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.blit_xor!(src1, src2, dst)
    end

    #===画像をαチャネル付き画像へ転送する
    #引数で渡ってきた特定の色に対して、α値をゼロにする画像を生成する
    #src==dstの場合、何も行わずすぐに呼びだし元に戻る
    #範囲は、src側SpriteUnitの(w,h)の範囲で転送する。
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_color_key_:: 透明にしたい色(各要素がr,g,bに対応している整数の配列(0～255))
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.ck_to_ac!(src, dst, color_key)
    end

    #===画像のαチャネルを255に拡張する
    #αチャネルの値を255に拡張する(α値をリセットする)
    #範囲は、src側SpriteUnitの(w,h)の範囲で転送する。
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.reset_ac!(src, dst)
    end

    #===画像をαチャネル付き画像へ変換する
    #２４ビット画像(αチャネルがゼロの画像)に対して、すべてのα値を255にする画像を生成する
    #範囲は、src側SpriteUnitの(w,h)の範囲で転送する。
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.normal_to_ac!(src, dst)
    end

    #===画面(αチャネル無し32bit画像)をαチャネル付き画像へ転送する
    #α値がゼロの画像から、α値を255にする画像を生成する
    #src==dstの場合、何も行わずすぐに呼びだし元に戻る
    #範囲は、src側SpriteUnitの(w,h)の範囲で転送する。
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.screen_to_ac!(src, dst)
    end

    #===画像のαチャネルの値を一定の割合で変化させて転送する
    #degreeの値が1.0に近づけば近づくほど透明に近づき、
    #degreeの値が-1.0に近づけば近づくほど不透明に近づく(値が-1.0のときは完全不透明、値が0.0のときは変化なし、1.0のときは完全に透明になる)
    #但し、元々αの値がゼロの時は変化しない
    #範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
    #但しsrc==dstのときはx,yを無視する
    #src == dst : 元の画像を変換した画像に置き換える
    #src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_degree_:: 減少率。-1.0<=degree<=1.0までの実数
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.dec_alpha!(src, dst, degree)
    end

    #===画像の色を一定の割合で黒に近づける(ブラックアウト)
    #赤・青・緑・αの各要素を一定の割合で下げ、黒色に近づける。
    #degreeの値が1.0に近づけば近づくほど黒色に近づく(値が0.0のときは変化なし、1.0のときは真っ黒になる)
    #αの値が0のときは変わらないことに注意！
    #範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
    #但しsrc==dstのときはx,yを無視する
    #src == dst : 元の画像を変換した画像に置き換える
    #src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_degree_:: 変化率。0.0<=degree<=1.0までの実数
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.black_out!(src, dst, degree)
    end

    #===画像の色を一定の割合で白に近づける(ホワイトアウト)
    #赤・青・緑・αの各要素を一定の割合で上げ、白色に近づける。
    #degreeの値が1.0に近づけば近づくほど白色に近づく(値が0.0のときは変化なし、1.0のときは真っ白になる)
    #αの値が0のときは変わらないことに注意！
    #範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
    #但しsrc==dstのときはx,yを無視する
    #src == dst : 元の画像を変換した画像に置き換える
    #src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_degree_:: 変化率。0.0<=degree<=1.0までの実数
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.white_out!(src, dst, degree)
    end

    #===画像のRGB値を反転させる
    #αチャネルの値は変更しない
    #範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
    #但しsrc==dstのときはx,yを無視する
    #src == dst : 元の画像を変換した画像に置き換える
    #src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.inverse!(src, dst)
    end

    #===2枚の画像の加算合成を行う
    #範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.additive!(src, dst)
    end

    #===2枚の画像の減算合成を行う
    #範囲は、src側SpriteUnitの(ow,oh)の範囲で転送する。転送先の描画開始位置は、src側SpriteUnitの(x,y)を左上とする。
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.subtraction!(src, dst)
    end

    #===画像を回転させて貼り付ける
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、(ow,oh)の範囲で転送する。回転の中心は(ox,oy)を起点に、(cx,cy)が中心になるように設定する。
    #転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に、dst側SpriteUnitの(cx,cy)が中心になるように設定にする。
    #回転角度が正だと右回り、負だと左回りに回転する
    #src==dstの場合、何も行わない
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_radian_:: 回転角度。単位はラジアン。値の範囲は0<=radian<2pi
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.rotate(src, dst, radian)
    end

    #===画像を拡大・縮小・鏡像(ミラー反転)させて貼り付ける
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、(ow,oh)の範囲で転送する。回転の中心は(ox,oy)を起点に、(cx,cy)が中心になるように設定する。
    #転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に、dst側SpriteUnitの(cx,cy)が中心になるように設定にする。
    #度合いが scale > 1.0 だと拡大、 0 < scale < 1.0 だと縮小、scale < 0.0 負だと鏡像の拡大・縮小になる(scale == -1.0 のときはミラー反転になる)
    #但し、拡大率が4096分の1以下だと、拡大/縮小しない可能性がある
    #src==dstの場合、何も行わない
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_xscale_:: 拡大率(x方向)
    #_yscale_:: 拡大率(y方向)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.scale(src, dst, xscale, yscale)
    end

    #===画像を変形(回転・拡大・縮小・鏡像)させて貼り付ける
    #転送元の描画範囲は、src側SpriteUnitの(ox,oy)を起点に、src側(ow,oh)の範囲で転送する。回転の中心はsrc側(ox,oy)を起点に、src側(cx,cy)が中心になるように設定する。
    #転送先の描画範囲は、src側SpriteUnitの(x,y)を起点に、dst側SpriteUnitの(cx,cy)が中心になるように設定にする。
    #回転角度は、src側SpriteUnitのangleを使用する
    #回転角度が正だと右回り、負だと左回りに回転する
    #変形の度合いは、src側SpriteUnitのxscale, yscaleを使用する(ともに実数で指定する)。それぞれ、x方向、y方向の度合いとなる
    #度合いが scale > 1.0 だと拡大、 0 < scale < 1.0 だと縮小、scale < 0.0 負だと鏡像の拡大・縮小になる(scale == -1.0 のときはミラー反転になる)
    #但し、拡大率が4096分の1以下だと、拡大/縮小しない可能性がある
    #src==dstの場合、何も行わない
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_radian_:: 回転角度。単位はラジアン。値の範囲は0<=radian<2pi
    #_xscale_:: 拡大率(x方向)
    #_yscale_:: 拡大率(y方向)
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.transform(src, dst, radian, xscale, yscale)
    end

    #===画像の色相を変更する
    #範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
    #src == dst : 元の画像を変換した画像に置き換える
    #src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.hue!(src, dst, degree)
    end

    #===画像の彩度を変更する
    #範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
    #src == dst : 元の画像を変換した画像に置き換える
    #src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.saturation!(src, dst, saturation)
    end

    #===画像の明度を変更する
    #範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
    #src == dst : 元の画像を変換した画像に置き換える
    #src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_value_:: 明度の変更量。範囲は0.0〜1.0の実数
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.value!(src, dst, value)
    end

    #===画像の色相・彩度・明度を変更する
    #範囲は、srcの(ow,oh)の範囲で転送する。転送先の描画開始位置は、srcの(x,y)を左上とする。但しsrc==dstのときはx,yを無視する
    #src == dst : 元の画像を変換した画像に置き換える
    #src != dst : 元の画像を対象の画像に転送する(αチャネルの計算付き)
    #(注)このメソッドは、画面に転送する場合、Viewportを反映しない
    #ブロックを渡すと、src,dst側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る
    #(ブロック引数のインスタンスは複写しているので、メソッドの引数として渡した値が持つSpriteUnitには影響しない)
    #ブロックの引数は、|src側SpriteUnit,dst側SpriteUnit|となる。
    #_src_:: 転送元ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_dst_:: 転送先ビットマップ(to_unitメソッドを呼び出すことが出来る/値がnilではないインスタンス)
    #_degree_:: 色相の変更量。単位は度(実数)。範囲は、-360.0<degree<360.0
    #_saturation_:: 彩度の変更量。範囲は0.0〜1.0の実数
    #_value_:: 明度の変更量。範囲は0.0〜1.0の実数
    #返却値:: 転送に成功すればdstを返す。失敗すればnilを返す
    def Bitmap.hsv!(src, dst, degree, saturation, value)
    end
  end
end
