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
  #==当たり判定領域(コリジョン)クラス
  #コリジョンの範囲は、元データ(スプライト等)の左上端を[0,0]として考案する
  #本クラスに設定できる方向(direction)・移動量(amount)は、コリジョンの範囲・位置に影響しない
  class Collision
    extend Forwardable

    # コリジョンの範囲([x,y,w,h])
    attr_reader :rect
    # 元データの位置([x,y])
    attr_reader :pos
    # 移動方向([dx,dy], dx,dy:-1,0,1)
    attr_reader :direction
    # 移動量([w,h])
    attr_reader :amount
    
    #===コリジョンのインスタンスを作成する
    #_rect_:: コリジョンを設定する範囲
    #_pos_:: 元データの位置
    #返却値:: 作成されたコリジョン
    def initialize(rect, pos)
      @rect = Rect.new(*(rect.to_a[0..3]))
      @pos = Point.new(*(pos.to_a[0..1]))
      @direction = Point.new(0, 0)
      @amount = Size.new(0, 0)
    end

    #===コリジョンの方向を転換する
    #_dx_:: 変換する方向(x軸方向、-1,0,1の3種類)
    #_dy_:: 変換する方向(y軸方向、-1,0,1の3種類)
    #返却値:: 自分自身を返す
    def turn(dx, dy)
      @direction = Point.new(dx, dy)
      return self
    end

    #===コリジョンの移動量を変更する
    #_mx_:: 変更する移動量(x軸方向)
    #_my_:: 変更する移動量(y軸方向)
    #返却値:: 自分自身を返す
    def adjust(mx, my)
      @amount = Size.new(mx, my)
      return self
    end

    #===当たり判定を行う(領域が重なっている)
    #_c2_:: 判定対象のコリジョンインスタンス
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def collision?(c2)
      return Collision.collision?(self, c2)
    end

    #===当たり判定を行う(領域が当たっている(重なっていない))
    #_c2_:: 判定対象のコリジョンインスタンス
    #返却値:: 領域が当たっていれば true を返す
    def meet?(c2)
      return Collision.meet?(self, c2)
    end

    #===当たり判定を行う(移動後に領域が重なっている(移動前は重なっていない))
    #_c2_:: 判定対象のコリジョンインスタンス
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def into?(c2)
      return Collision.into?(self, c2)
    end

    #===当たり判定を行う(移動後に領域が離れている(移動前は重なっている))
    #_c2_:: 判定対象のコリジョンインスタンス
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def out?(c2)
      return Collision.out?(self, c2)
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #_c2_:: 判定対象のコリジョンインスタンス
    #返却値:: 領域が覆われていれば true を返す
    def cover?(c2)
      return Collision.cover?(self, c2)
    end

    #===コリジョンの位置を、指定の移動量で移動する
    #ブロックを渡したとき、そのブロックを評価中のときのみ移動を反映する
    #_x_:: 移動量(x方向)。単位はピクセル
    #_y_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move(x, y)
      @pos.move(x, y)
      if block_given?
        yield
        @pos.move(-x, -y)
      end
      return self
    end

    #===コリジョンの位置を、指定の位置へ移動する
    #ブロックを渡したとき、そのブロックを評価中のときのみ移動を反映する
    #_x_:: 移動先の位置(x方向)。単位はピクセル
    #_y_:: 移動先の位置(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move_to(x, y)
      ox, oy = @pos.to_a
      @pos.move_to(x, y)
      if block_given?
        yield
        @pos.move_to(ox, oy)
      end
      return self
    end

    #===当たり判定を行う(領域が重なっている)
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def Collision.collision?(c1, c2)
      l1 = c1.pos[0] + c1.rect[0]
      t1 = c1.pos[1] + c1.rect[1]
      r1 = l1 + c1.rect[2] - 1
      b1 = t1 + c1.rect[3] - 1
      l2 = c2.pos[0] + c2.rect[0]
      t2 = c2.pos[1] + c2.rect[1]
      r2 = l2 + c2.rect[2] - 1
      b2 = t2 + c2.rect[3] - 1
      v =  0
      v |= 1 if l1 <= l2 && l2 <= r1
      v |= 1 if l1 <= r2 && r2 <= r1
      v |= 2 if t1 <= t2 && t2 <= b1
      v |= 2 if t1 <= b2 && b2 <= b1
      return v == 3
    end

    #===当たり判定を行う(移動後の領域が重なっている)
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def Collision.collision_with_move?(c1, c2)
      l1 = c1.pos[0] + c1.rect[0] + c1.direction[0] * c1.amount[0]
      t1 = c1.pos[1] + c1.rect[1] + c1.direction[1] * c1.amount[1]
      r1 = l1 + c1.rect[2] - 1
      b1 = t1 + c1.rect[3] - 1
      l2 = c2.pos[0] + c2.rect[0] + c2.direction[0] * c2.amount[0]
      t2 = c2.pos[1] + c2.rect[1] + c2.direction[1] * c2.amount[1]
      r2 = l2 + c2.rect[2] - 1
      b2 = t2 + c2.rect[3] - 1
      v =  0
      v |= 1 if l1 <= l2 && l2 <= r1
      v |= 1 if l1 <= r2 && r2 <= r1
      v |= 2 if t1 <= t2 && t2 <= b1
      v |= 2 if t1 <= b2 && b2 <= b1
      return v == 3
    end

    #===当たり判定を行う(領域が当たっている(重なっていない))
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #返却値:: 領域が当たっていれば true を返す
    def Collision.meet?(c1, c2)
      l1 = c1.pos[0] + c1.rect[0]
      t1 = c1.pos[1] + c1.rect[1]
      r1 = l1 + c1.rect[2]
      b1 = t1 + c1.rect[3]
      l2 = c2.pos[0] + c2.rect[0]
      t2 = c2.pos[1] + c2.rect[1]
      r2 = l2 + c2.rect[2]
      b2 = t2 + c2.rect[3]
      v =  0
      v |= 1 if r1 == l2
      v |= 1 if b1 == t2
      v |= 1 if l1 == r2
      v |= 1 if t1 == b2
      return v == 1
    end

    #===当たり判定を行う(移動後に領域が重なっている(移動前は重なっていない))
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def Collision.into?(c1, c2)
      f1 = Collision.collision?(c1, c2)
      f2 = Collision.collision_with_move?(c1, c2)
      return !f1 & f2
    end

    #===当たり判定を行う(移動後に領域が離れている(移動前は重なっている))
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def Collision.out?(c1, c2)
      f1 = Collision.collision?(c1, c2)
      f2 = Collision.collision_with_move?(c1, c2)
      return f1 & !f2
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #_c1_:: 判定対象のコリジョンインスタンス(1)
    #_c2_:: 判定対象のコリジョンインスタンス(2)
    #返却値:: 領域が覆われていれば true を返す
    def Collision.cover?(c1, c2)
      l1 = c1.pos[0] + c1.rect[0]
      t1 = c1.pos[1] + c1.rect[1]
      r1 = l1 + c1.rect[2]
      b1 = t1 + c1.rect[3]
      l2 = c2.pos[0] + c2.rect[0]
      t2 = c2.pos[1] + c2.rect[1]
      r2 = l2 + c2.rect[2]
      b2 = t2 + c2.rect[3]
      v =  0
      v |= 1 if l1 <= l2 && r2 <= r1
      v |= 2 if t1 <= t2 && b2 <= b1
      v |= 4 if l2 <= l1 && r1 <= r2
      v |= 8 if t2 <= t1 && b1 <= b2
      return v == 3 || v == 12
    end

    #== インスタンスの内容を解放する
    #返却値:: なし
    def dispose
      @pos.clear
      @pos = nil
      @rect.clear
      @rect = nil
      @amount.clear
      @amount = nil
      @direction.clear
      @direction = nil
    end
  end

  #==コリジョン管理クラス
  #複数のコリジョンと元オブジェクトを配列の様に一括管理できる
  #当たり判定を一括処理することで高速化を図る
  class Collisions
    include Enumerable
    extend Forwardable

    #===コリジョンのインスタンスを作成する
    #_collisions_:: コリジョンの配列。デフォルトは []
    #_pos_:: 元データの配列。デフォルトは []
    #返却値:: 作成されたインスタンス
    def initialize(collisions=[], bodies=[])
      @collisions = Array.new(collisions).zip(bodies)
    end

    #===コリジョンと本体を追加する
    #_collisions_:: コリジョン
    #_pos_:: 元データ
    #返却値:: 自分自身を返す
    def add(collision, body)
      @collisions << [collision, body]
      return self
    end

    #===インスタンスに、コリジョンと本体の集合を追加する
    #_collisions_:: コリジョンの配列
    #_pos_:: 元データの配列
    #返却値:: 自分自身を返す
    def append(collisions, bodies)
      @collisions.concat(collisions.zip(bodies))
      return self
    end

    #===インデックス形式でのコリジョン・本体の取得
    #_idx_:: 配列のインデックス番号
    #返却値:: インデックスに対応したコリジョンと本体との対。
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

    #===すべてのコリジョンの方向を転換する
    #_dx_:: 変換する方向(x軸方向、-1,0,1の3種類)
    #_dy_:: 変換する方向(y軸方向、-1,0,1の3種類)
    #返却値:: 自分自身を返す
    def turn(dx, dy)
      @collisions.each{|cs| cs.turn(dx, dy) }
      return self
    end

    #===すべてのコリジョンの移動量を変更する
    #_mx_:: 変更する移動量(x軸方向)
    #_my_:: 変更する移動量(y軸方向)
    #返却値:: 自分自身を返す
    def adjust(mx, my)
      @collisions.each{|cs| cs.adjust(mx, my) }
      return self
    end
    
    #===当たり判定を行う(領域が重なっている)
    #判定に引っかかったコリジョンが一つでもあれば、最初に引っかかったコリジョンを返す
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対。
    def collision?(c)
      return @collisions.detect{|cc| c.collision?(cc[0])}
    end

    #===当たり判定を行う(領域が当たっている(重なっていない))
    #判定に引っかかったコリジョンが一つでもあれば、最初に引っかかったコリジョンを返す
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対。
    #返却値:: 領域が当たっていれば true を返す
    def meet?(c)
      return @collisions.detect{|cc| c.meet?(cc[0])}
    end

    #===当たり判定を行う(移動後に領域が重なっている(移動前は重なっていない))
    #判定に引っかかったコリジョンが一つでもあれば、最初に引っかかったコリジョンを返す
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対。
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def into?(c)
      return @collisions.detect{|cc| c.into?(cc[0])}
    end

    #===当たり判定を行う(移動後に領域が離れている(移動前は重なっている))
    #判定に引っかかったコリジョンが一つでもあれば、最初に引っかかったコリジョンを返す
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対。
    #返却値:: 1ピクセルでも重なっていれば true を返す
    def out?(c)
      return @collisions.detect{|cc| c.out?(cc[0])}
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #判定に引っかかったコリジョンが一つでもあれば、最初に引っかかったコリジョンを返す
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対。
    #返却値:: 領域が覆われていれば true を返す
    def cover?(c)
      return @collisions.detect{|cc| c.cover?(cc[0])}
    end

    #===当たり判定を行う(領域が重なっている)
    #判定に引っかかったコリジョンが一つでもあれば、すべてのコリジョンの配列を返す
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対の配列。
    def collision_all?(c)
      return @collisions.select{|cc| c.collision?(cc[0])}
    end

    #===当たり判定を行う(領域が当たっている(重なっていない))
    #判定に引っかかったコリジョンが一つでもあれば、すべてのコリジョンの配列を返す
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対の配列。
    def meet_all?(c)
      return @collisions.select{|cc| c.meet?(cc[0])}
    end

    #===当たり判定を行う(移動後に領域が重なっている(移動前は重なっていない))
    #判定に引っかかったコリジョンが一つでもあれば、すべてのコリジョンの配列を返す
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対の配列。
    def into_all?(c)
      return @collisions.select{|cc| c.into?(cc[0])}
    end

    #===当たり判定を行う(移動後に領域が離れている(移動前は重なっている))
    #判定に引っかかったコリジョンが一つでもあれば、すべてのコリジョンの配列を返す
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対の配列。
    def out_all?(c)
      return @collisions.select{|cc| c.out?(cc[0])}
    end

    #===当たり判定を行う(どちらかの領域がもう一方にすっぽり覆われている))
    #判定に引っかかったコリジョンが一つでもあれば、すべてのコリジョンの配列を返す 
    #当たり判定に引っかかったコリジョンが無い場合はnilを返す
    #_c_:: 判定対象のコリジョンインスタンス
    #返却値:: コリジョンと本体の対の配列。
    def cover_all?(c)
      return @collisions.select{|cc| c.cover?(cc[0])}
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
