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

module Miyako
  #==矩形当たり判定領域(コリジョン)クラス
  #コリジョンの範囲は、元データ(スプライト等)の左上端を[0,0]として考案する
  class Collision
    extend Forwardable

    # コリジョンの範囲([x,y,w,h])
    attr_reader :rect
    # 移動時イベントブロック配列
    
    #===コリジョンのインスタンスを作成する
    #_rect_:: コリジョンを設定する範囲
    #返却値:: 作成されたコリジョン
    def initialize(rect)
      @rect = Rect.new(*(rect.to_a[0..3]))
    end

    #===当たり判定を行う(領域が重なっている)
    #_pos1_:: 自分自身の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def collision?(pos1, c2, pos2)
      return Collision.collision?(self, pos1, c2, pos2)
    end

    #===当たり判定を行う(領域がピクセル単位で隣り合っている)
    #_pos1_:: 自分自身の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 領域が隣り合っていれば true を返す
    def meet?(pos1, c2, pos2)
      return Collision.meet?(self, pos1, c2, pos2)
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #_pos1_:: 自分自身の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 領域が覆われていれば true を返す
    def cover?(pos1, c2, pos2)
      return Collision.cover?(self, pos1, c2, pos2)
    end

    #===当たり判定を行う(領域が重なっている)
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_pos1_:: c1の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def Collision.collision?(c1, pos1, c2, pos2)
      l1 = pos1[0] + c1.rect[0]
      t1 = pos1[1] + c1.rect[1]
      r1 = l1 + c1.rect[2] - 1
      b1 = t1 + c1.rect[3] - 1
      l2 = pos2[0] + c2.rect[0]
      t2 = pos2[1] + c2.rect[1]
      r2 = l2 + c2.rect[2] - 1
      b2 = t2 + c2.rect[3] - 1
      v =  0
      v |= 1 if l1 <= l2 && l2 <= r1
      v |= 1 if l1 <= r2 && r2 <= r1
      v |= 2 if t1 <= t2 && t2 <= b1
      v |= 2 if t1 <= b2 && b2 <= b1
      return v == 3
    end

    #===当たり判定を行う(領域がピクセル単位で隣り合っている)
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_pos1_:: c1の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 領域が隣り合っていれば true を返す
    def Collision.meet?(c1, pos1, c2, pos2)
      l1 = pos1[0] + c1.rect[0]
      t1 = pos1[1] + c1.rect[1]
      r1 = l1 + c1.rect[2]
      b1 = t1 + c1.rect[3]
      l2 = pos2[0] + c2.rect[0]
      t2 = pos2[1] + c2.rect[1]
      r2 = l2 + c2.rect[2]
      b2 = t2 + c2.rect[3]
      v =  0
      v |= 1 if r1 == l2
      v |= 1 if b1 == t2
      v |= 1 if l1 == r2
      v |= 1 if t1 == b2
      return v == 1
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_pos1_:: c1の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 領域が覆われていれば true を返す
    def Collision.cover?(c1, pos1, c2, pos2)
      l1 = pos1[0] + c1.rect[0]
      t1 = pos1[1] + c1.rect[1]
      r1 = l1 + c1.rect[2]
      b1 = t1 + c1.rect[3]
      l2 = pos2[0] + c2.rect[0]
      t2 = pos2[1] + c2.rect[1]
      r2 = l2 + c2.rect[2]
      b2 = t2 + c2.rect[3]
      v =  0
      v |= 1 if l1 >= l2 && r2 <= r1
      v |= 2 if t1 >= t2 && b2 <= b1
      v |= 4 if l2 >= l1 && r1 <= r2
      v |= 8 if t2 >= t1 && b1 <= b2
      return v & 3 == 3 || v & 12 == 12
    end

    #== インスタンスの内容を解放する
    #返却値:: なし
    def dispose
      @rect = nil
    end
  end

  #==円形当たり判定領域(サークルコリジョン)クラス
  #円形の当たり判定を実装する。
  #コリジョンは中心位置と半径で構成され、円形当たり判定同士で衝突判定を行う
  class CircleCollision
    extend Forwardable

    # コリジョンの中心点([x,y])
    attr_reader :center
    # コリジョンの半径
    attr_reader :radius
    # 移動時イベントブロック配列
    
    #===コリジョンのインスタンスを作成する
    #コリジョンの半径が0もしくはマイナスのとき例外が発生する
    #_center_:: コリジョンを設定する範囲
    #_radius_:: コリジョンの半径
    #返却値:: 作成されたコリジョン
    def initialize(center, radius)
      raise MiyakoError, "illegal radius! #{radius}" if radius <= 0
      @center = Point.new(*(center.to_a[0..1]))
      @radius = radius
    end

    #===当たり判定を行う(領域が重なっている)
    #_pos1_:: 自分自身の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def collision?(pos1, c2, pos2)
      return CircleCollision.collision?(self, pos1, c2, pos2)
    end

    #===当たり判定を行う(領域がピクセル単位で隣り合っている)
    #_pos1_:: 自分自身の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 領域が隣り合っていれば true を返す
    def meet?(pos1, c2, pos2)
      return CircleCollision.meet?(self, pos1, c2, pos2)
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #_pos1_:: 自分自身の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 領域が覆われていれば true を返す
    def cover?(pos1, c2, pos2)
      return CircleCollision.cover?(self, pos1, c2, pos2)
    end

    #===当たり判定を行う(領域が重なっている)
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_pos1_:: c1の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def CircleCollision.collision?(c1, pos1, c2, pos2)
      #2点間の距離を求める
      d = (((c1.center[0] + pos1[0]) - (c2.center[0] + pos2[0])) ** 2) +
          (((c1.center[1] + pos1[1]) - (c2.center[1] + pos2[1])) ** 2)
      #半径の和を求める
      r  = (c1.radius + c2.radius) ** 2
      return d <= r
    end

    #===当たり判定を行う(領域がピクセル単位で隣り合っている)
    #但し、実際の矩形範囲が偶数の時は性格に判定できない場合があるため注意
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_pos1_:: c1の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 領域が隣り合っていれば true を返す
    def CircleCollision.meet?(c1, pos1, c2, pos2)
      #2点間の距離を求める
      d = (((c1.center[0] + pos1[0]) - (c2.center[0] + pos2[0])) ** 2) +
          (((c1.center[1] + pos1[1]) - (c2.center[1] + pos2[1])) ** 2)
      #半径の和を求める
      r  = (c1.radius + c2.radius) ** 2
      return d == r
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_pos1_:: c1の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #_pos2_:: c2の位置(Point/Rect/Square構造体、2要素以上の配列、もしくはx,yメソッドを持つインスタンス)
    #返却値:: 領域が覆われていれば true を返す
    def CircleCollision.cover?(c1, pos1, c2, pos2)
      #2点間の距離を求める
      d = ((c1.center[0] + pos1[0]) - (c2.center[0] + pos2[0])) ** 2 +
          ((c1.center[1] + pos1[1]) - (c2.center[1] + pos2[1])) ** 2
      #半径の差分を求める
      r  = c1.radius ** 2 - 2 * (c1.radius * c2.radius) + c2.radius ** 2
      return d <= r
    end

    #== インスタンスの内容を解放する
    #返却値:: なし
    def dispose
      @point = nil
    end
  end

  #==コリジョン管理クラス
  #複数のコリジョンと元オブジェクトを配列の様に一括管理できる
  #当たり判定を一括処理することで高速化を図る
  class Collisions
    include Enumerable
    extend Forwardable

    #===コリジョンのインスタンスを作成する
    #points引数の各要素は、以下の3つの条件のどれかに適合する必要がある。しない場合は例外が発生する
    #1)[x,y]の要素を持つ配列
    #2)Point構造体、Rect構造体、もしくはSquare構造体
    #3)x,yメソッドを持つ
    #_collisions_:: コリジョンの配列。デフォルトは []
    #_points_:: 位置情報の配列。デフォルトは []
    #返却値:: 作成されたインスタンス
    def initialize(collisions=[], points=[])
      @collisions = Array.new(collisions).zip(points)
    end

    #===コリジョンと位置情報を追加する
    #point引数は、以下の3つの条件のどれかに適合する必要がある。しない場合は例外が発生する
    #1)[x,y]の要素を持つ配列
    #2)Point構造体、Rect構造体、もしくはSquare構造体
    #3)x,yメソッドを持つ
    #_collisions_:: コリジョン
    #_point_:: 位置情報
    #返却値:: 自分自身を返す
    def add(collision, point)
      @collisions << [collision, point]
      return self
    end

    #===インスタンスに、コリジョンと位置情報の集合を追加する
    #points引数の各要素は、以下の3つの条件のどれかに適合する必要がある。しない場合は例外が発生する
    #1)[x,y]の要素を持つ配列
    #2)Point構造体、Rect構造体、もしくはSquare構造体
    #3)x,yメソッドを持つ
    #_collisions_:: コリジョンの配列
    #_points_:: 位置情報の配列
    #返却値:: 自分自身を返す
    def append(collisions, points)
      @collisions.concat(collisions.zip(points))
      return self
    end

    #===インデックス形式でのコリジョン・本体の取得
    #_idx_:: 配列のインデックス番号
    #返却値:: インデックスに対応したコリジョンと位置情報との対。
    #インデックスが範囲外の時はnilが返る
    def [](idx)
      return @collisions[idx]
    end
    
    #===コリジョン・本体の削除
    #対応したインデックスのコリジョンと
    #_idx_:: 配列のインデックス番号
    #返却値:: 削除したコリジョンと本体との対
    #インデックスが範囲外の時はnilが返る
    def delete(idx)
      return @collisions.delete_at(idx)
    end
    
    #===インデックス形式でのコリジョン・本体の取得
    #_idx_:: 配列のインデックス番号
    #返却値:: インデックスに対応したコリジョンと本体との対
    def clear
      @collisions.clear
      return self
    end

    #===タッピングを行う
    #ブロックを渡すことにより、タッピングを行う
    #ブロック内の引数は、|コリジョン,本体|の２が渡される
    #返却値:: 自分自身を返す
    def each
      @collisions.each{|cb| yield cb[0], cb[1] }
      return self
    end

    #===タッピングを行う
    #ブロックを渡すことにより、タッピングを行う
    #ブロック内の引数は、|コリジョン,本体|の２が渡される
    #_idx_:: 配列のインデックス
    #返却値:: 自分自身を返す
    def tap(idx)
      yield @collisions[idx][0], @collisions[idx][1]
      return self
    end
    
    #===当たり判定を行う(配列のどれかの領域が重なっている)
    #重なったコリジョンが一つでもあれば、最初に引っかかったコリジョンを返す
    #重なったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #_pos_:: cの位置(Point/Rect/Square構造体、もしくは2要素の配列)
    #返却値:: コリジョンと本体の対。
    def collision?(c, pos)
      return @collisions.detect{|cc| c.collision?(pos, cc[0], cc[1])}
    end

    #===当たり判定を行う(配列のどれかの領域がピクセル単位で隣り合っている)
    #隣り合ったコリジョンが一つでもあれば、最初に引っかかったコリジョンを返す
    #隣り合ったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #_pos_:: cの位置(Point/Rect/Square構造体、もしくは2要素の配列)
    #返却値:: 隣り合っていれば true を返す
    def meet?(c, pos)
      return @collisions.detect{|cc| c.meet?(pos, cc[0], cc[1])}
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #覆われたコリジョンが一つでもあれば、最初に引っかかったコリジョンを返す
    #覆われたコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #_pos_:: cの位置(Point/Rect/Square構造体、もしくは2要素の配列)
    #返却値:: 領域が覆われていれば true を返す
    def cover?(c, pos)
      return @collisions.detect{|cc| c.cover?(pos, cc[0], cc[1])}
    end

    #===当たり判定を行う(領域が重なっている)
    #重なったコリジョンが一つでもあれば、すべてのコリジョンの配列を返す
    #重なったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #_pos_:: cの位置(Point/Rect/Square構造体、もしくは2要素の配列)
    #返却値:: コリジョンと本体の対の配列。
    def collision_all?(c, pos)
      return @collisions.select{|cc| c.collision?(pos, cc[0], cc[1])}
    end

    #===当たり判定を行う(領域がピクセル単位で隣り合っている)
    #隣り合ったコリジョンが一つでもあれば、すべてのコリジョンの配列を返す
    #隣り合ったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #_pos_:: cの位置(Point/Rect/Square構造体、もしくは2要素の配列)
    #返却値:: コリジョンと本体の対の配列。
    def meet_all?(c, pos)
      return @collisions.select{|cc| c.meet?(pos, cc[0], cc[1])}
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #覆われたコリジョンが一つでもあれば、すべてのコリジョンの配列を返す 
    #覆われたコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #_pos_:: cの位置(Point/Rect/Square構造体、もしくは2要素の配列)
    #返却値:: コリジョンと本体の対の配列。
    def cover_all?(c, pos)
      return @collisions.select{|cc| c.cover?(pos, cc[0], cc[1])}
    end

    #===インデックス形式でのコリジョン・本体の取得
    #判定に引っかかったコリジョンが一つでもあれば、すべてのコリジョンの配列を返す    
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_idx_:: 配列のインデックス番号
    #返却値:: インデックスに対応したコリジョンと本体との対
    def [](idx)
      return [@collisions[idx], @bodies[idx]]
    end

    #===オブジェクトを解放する
    #返却値:: なし
    def dispose
      @collisions.clear
      @collisions = nil
    end
  end
end
