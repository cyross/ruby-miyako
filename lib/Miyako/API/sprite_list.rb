# -*- encoding: utf-8 -*-
=begin
--
Miyako v2.1
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

# スプライト関連クラス群
module Miyako
  #==名前-本体ペアを構成する構造体用クラス
  class ListPairStruct < Struct
    include SpriteBase
    include Animation
    include Layout

    # ディープコピー
    def deep_dup
      [self[0], self[1].dup]
    end

    # ディープコピー
    def deep_clone
      self.deep_copy
    end

    # 構造体を配列に変換する
    def to_ary
      [self[0], self[1]]
    end

    # 構造体を配列に変換する
    def to_a
      self.to_ary
    end

    # 構造体を文字列に変換する
    def to_s
      "#{self[0]} : #{self[1]}"
    end

    #===スプライトの移動(変化量を指定)
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move!(dx, dy)
      self[1].move!(dx, dy)
      self
    end

    #===本体の移動(位置を指定)
    #_x_:: 位置(x方向)。単位はピクセル
    #_y_:: 位置(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move_to!(x, y)
      self[1].move_to!(x, y)
      self
    end

    #===本体のアニメーションを開始する
    #各要素のstartメソッドを呼び出す
    #返却値:: 自分自身を返す
    def start
      self[1].start
      return self
    end

    #===本体のアニメーションを停止する
    #各要素のstopメソッドを呼び出す
    #返却値:: 自分自身を返す
    def stop
      self[1].stop
      return self
    end

    #===本体のアニメーションを先頭パターンに戻す
    #各要素のresetメソッドを呼び出す
    #返却値:: 自分自身を返す
    def reset
      self[1].reset
      return self
    end

    #===本体のアニメーションを更新する
    #各要素のupdate_animationメソッドを呼び出す
    #返却値:: 本体のupdate_spriteメソッドを呼び出した結果
    def update_animation
      self[1].update_animation
    end

    #画面に描画する
    def render
      self[1].render
    end

    #指定の画像に描画する
    #_dst_:: 描画先インスタンス
    def render_to(dst)
      self[1].render_to(dst)
    end
  end

  #===名前-本体ペアを構成する構造体
  #ハッシュのようにキー・バリュー構成を持たせるための構造体
  #_name_:: 名前
  #_body_:: 本体
  ListPair = ListPairStruct.new(:name, :body)

  #==複数スプライト管理(リスト)クラス
  #複数のスプライトを、[名前,インスタンス]の一対一のリストとして持っておく。
  #値の並びの基準は、名前の並びを配列にしたときのもの(SpriteList#valuesの値)に対応する
  #Enumerableからmixinされたメソッド、Array・Hashクラスで使用されている一部メソッド、
  #swapなどの独自メソッドを追加している
  #(Enumerableからmixinされたメソッドでは、ブロック引数に[名前,インスタンス]の配列として渡される)
  #render、render_toを用意し、一気に描画が可能。
  #名前は配列として管理している。render時には、名前の順番に描画される。
  #各要素のレイアウトは関与していない(そこがPartsとの違い)
  #また、このクラスインスタンスのdup、cloneはディープコピー(配列の要素も複写)となっていることに注意。
  class SpriteList
    include SpriteBase
    include Animation
    include Layout
    include Enumerable

    attr_accessor :visible

    #===ハッシュを元にSpriteListを生成する
    #ハッシュのキーをスプライト名にして生成する
    #_hash_:: 生成元のハッシュ
    #返却値:: 生成したインスタンス
    def SpriteList.[](hash)
      body = SpriteList.new
      hash.each{|k, v| body.push(k ,v)}
    end

    #===ハッシュを元にSpriteListを生成する
    #引数を省略すると空のSpriteListを生成する。
    #要素が[スプライト名,スプライト]の配列となる配列を引数として渡すこともできる。
    #(ただし、要素がスプライトのみのときは、
    #名前を":s_nnn"(nnn:配列インデックス(3桁))として追加する)
    #ハッシュを引数として渡すと、キーをスプライト名とするSpriteListを生成する。
    #_pairs_:: 生成元のインスタンス
    #返却値:: 生成したインスタンス
    def initialize(pairs = nil)
      init_layout
      set_layout_size(1,1)
      @list = []
      if pairs.is_a?(Array)
        pairs.each_with_index{|pair, i|
        if pair.is_a?(Array) || pair.is_a?(ListPair)
          @list << ListPair.new(*pair)
        else
          name = sprintf("s_%03d", i).to_sym
          @list << ListPair.new(name, pair)
        end
      }
      elsif pairs.is_a?(Hash)
        pairs.each{|key, value|
          @list << ListPair.new(key, value)
        }
       end
      @visible = true
    end

    #===内部で使用している配列などを新しいインスタンスに置き換える
    #initialize_copy用で元・新インスタンスで配列などを共用している場合に対応
    def reflesh
      @list = []
    end

    def initialize_copy(obj) #:nodoc:
      reflesh
      obj.names.each{|name| self.push([name, obj[name].deep_dup]) }
      @visible = obj.visible
    end

    #===スプライト以外のインスタンスを削除したSpriteListを生成する
    #新しいSpriteListを作成し、本体がnilや、SpriteBaseもしくはSpritArrayモジュールを
    #mixinしていない対を削除する。
    #返却値:: 新しく生成したインスタンス
    def sprite_only
      ret = SpriteList.new
      @list.each{|pair|
        name = pair.name
        body = pair.body
        ret[name] = pair.value if !body.class.include?(SpriteBase) &&
                                  !body.class.include?(SpriteArray)
      }
      return ret
    end

    #===スプライト以外のインスタンスを破壊的に削除する
    #自分自身から、本体がnilや、SpriteBaseもしくはSpritArrayモジュールを
    #mixinしていない対を削除する。
    #返却値:: 自分自身を帰す
    def sprite_only!
      @list.each{|pair|
        if !pair.body.class.include?(SpriteBase) &&
           !pair.body.class.include?(SpriteArray)
          @list.delete(pair)
        end
      }
      return self
    end

    #===ブロックを受け取り、リストの各要素にたいして処理を行う
    #ブロック引数には、|[スプライト名,スプライト本体]|が渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each
      return self.to_enum(:each) unless block_given?
      self.to_a.each{|pair| yield pair}
    end

    #===ブロックを受け取り、スプライト名リストの各要素にたいして処理を行う
    #ブロック引数には、|スプライト名,スプライト本体|が渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_pair
      return self.to_enum(:each_pair) unless block_given?
      @list.each{|pair| yield *pair}
    end

    #===ブロックを受け取り、名前リストの各要素にたいして処理を行う
    #ブロック引数には、|スプライト名|が渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_name
      return self.to_enum(:each_name) unless block_given?
      @list.each{|pair| yield pair.name}
    end

    #===ブロックを受け取り、値リストの各要素にたいして処理を行う
    #ブロック引数には、|スプライト本体|の配列として渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_value
      return self.to_enum(:each_value) unless block_given?
      @list.each{|pair| yield pair.body}
    end

    #===ブロックを受け取り、配列インデックスにたいして処理を行う
    #ブロック引数には、|スプライト名に対応する配列インデックス|の配列として渡ってくる
    #0,1,2,...の順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_index
      return self.to_enum(:each_index) unless block_given?
      @list.length.times{|idx| yield idx}
    end

    #===スプライト名配列を取得する
    #SpriteList#show,hideメソッドを呼び出す際、すべての要素を表示・非表示にするときに使う
    #返却値:: スプライト名配列
    def all
      @list.map{|pair| pair.name }
    end

    #===スプライト名配列を取得する
    #名前が登録されている順に渡ってくる
    #返却値:: スプライト名配列
    def names
      @list.map{|pair| pair.name }
    end

    #===スプライト配列を取得する
    #名前が登録されている順に渡ってくる
    #返却値:: スプライト本体配列
    def values
      @list.map{|pair| pair.body }
    end

    #===名前-本体ペア配列を取得する
    #名前が登録されている順にListPair構造体の構造体を構成して返す
    #返却値:: ListPair構造体の配列
    def pairs
      @list
    end

    #===リストが空っぽかどうか確かめる
    #リストに何も登録されていないかどうか確かめる
    #返却値:: 空っぽの時はtrue、なにか登録されているときはfalse
    def empty?
      @list.empty?
    end

    def index(pair)
      @list.index(pair)
    end

    #===内容が同じかどうか比較する
    #リストに含まれるスプライト名(順番も)・値が同じかどうか比較する
    #返却値:: 同じときはtrue、違うときはfalseを返す
    def eql?(other)
      return false unless other.class.method_defined?(:index)
      @list.find{|pair|
        self.index(pair) == other.index(pair) &&
        pair.body.eql?(other[pair.name].body)
      } != nil
    end

    #===リストに名前が登録されているか確認する
    #スプライト名リスト内に、引数で指定した名前が含まれているか調べる
    #(include?メソッドと同じ)
    #_name_:: 検索対象の名前
    #返却値:: 名前が含まれていればtrue、含まれていなければfalseと返す
    def has_key?(name)
      self.names.include?(name)
    end

    #===リストに名前が登録されているか確認する
    #スプライト名リスト内に、引数で指定した名前が含まれているか調べる
    #(include?メソッドと同じ)
    #_name_:: 検索対象の名前
    #返却値:: 名前が含まれていればtrue、含まれていなければfalseと返す
    def has_name?(name)
      self.names.include?(name)
    end

    #===リストに名前が登録されているか確認する
    #スプライト名リスト内に、引数で指定した名前が含まれているか調べる
    #(has_name?メソッドと同じ)
    #_name_:: 検索対象の名前
    #返却値:: 名前が含まれていればtrue、含まれていなければfalseと返す
    def include?(name)
      self.names.include?(name)
    end

    #===リストにスプライトが登録されているか確認する
    #スプライトリスト内に、引数で指定したスプライトが含まれているか調べる
    #_value_:: 検索対象のスプライト
    #返却値:: スプライトが含まれていればtrue、含まれていなければfalseと返す
    def has_value?(value)
      self.values.include?(value)
    end

    #===リストの長さを求める
    #スプライトの登録数(リストの要素数)を返す
    #(sizeメソッドと同じ)
    #返却値:: リストの要素数(殻のときは0)
    def length
      @list.length
    end

    #===リストの長さを求める
    #スプライトの登録数(リストの要素数)を返す
    #(lengthメソッドと同じ)
    #返却値:: リストの要素数(殻のときは0)
    def size
      @list.length
    end

    #===スプライト名を探し、あればその対を返す
    #引数で渡された名前を元に、リストから探し出す。
    #(内部でHash#assocを呼び出し)
    #_name_:: 検索対象のスプライト名
    #返却値:: 見つかればListPair構造体、無ければnil
    def assoc(name)
      @list.find(nil){|pair| pair.name == name }
    end

    #===スプライトが登録されている名前を求める
    #実際のスプライト本体から、登録されているスプライトを探す。
    #見つかれば、それに対応する名前を返す。
    #(内部でHash#keyメソッドを呼び出している)
    #_name_:: 検索対象のスプライト名
    #返却値:: 名前が見つかったときはそのスプライト名、無ければnil
    def name(value)
      @list.find(nil){|pair| pair.value.eql?(value) }
    end

    #===名前が何番目にあるかを求める
    #スプライト名リスト中、指定したスプライト名のインデックスを求める
    #(内部でHash#indexメソッドを呼び出している)
    #_name_:: 検索対象のスプライト名
    #返却値:: 名前が見つかったときはそのインデックス(0以上の整数)、無ければnil
    def index(name)
      self.names.index(name)
    end

    #===リストの先頭要素を求める
    #リストの先頭からn要素をSpriteListとして返す。
    #リストが空のとき、nが0のときはnilを返す
    #_n_:: 先頭からの数。省略時は1
    #返却値:: 先頭からn個の要素を設定したSpriteList
    def first(n=1)
      return nil if @list.empty?
      return nil if n == 0
      SpriteList.new(@list.first(n))
    end

    #===リストの終端要素を求める
    #リストの終端からn要素をSpriteListとして返す。
    #リストが空のとき、nが0のときはnilを返す
    #_n_:: 終端からの数。省略時は1
    #返却値:: 終端からn個の要素を設定したSpriteList
    def last(n=1)
      return nil if @list.empty?
      return nil if n == 0
      SpriteList.new(@list.last(n))
    end

    #===名前・スプライトの対を登録する
    #リストに名前・スプライトをリストの後ろに追加する
    #効果はSpriteList#pushと同じ
    #_pair_:: 名前とスプライトの対。[name,sprite]として渡す
    #返却値:: 追加した自分自身を渡す
    def <<(pair)
      self.push(pair)
    end

    #===引数と自分自身との和集合を取る
    #otherと自分自身で一方でも割り付けられた名前の本体のみ登録する(方法はpush・addと同じ)
    #名前がバッティングしたときは引数の本体を優先する
    #_other_:: 計算をするSpriteList
    #返却値:: 変更を加えた自分自身の複製
    def +(other)
      list = self.dup
      other.to_a.each{|pair| list.add(pair[0], pair[1].dup)}
      list
    end

    #===引数と自分自身との積集合を取る
    #otherと自分自身で両方割り付けられた名前のみ登録されたリストを生成する
    #内容は自分自身の本体を割り当てる
    #_other_:: 計算をするSpriteList
    #返却値:: 変更を加えた自分自身の複製
    def *(other)
      list = SpriteList.new
      self.to_a.each{|pair| list.add(pair[0], pair[1].dup) if other.has_key?(pair[0])}
      list
    end

    #===引数と自分自身との差集合を取る
    #otherと自分自身で両方割り付けられた名前を取り除いたリストを生成する
    #_other_:: 計算をするSpriteList
    #返却値:: 変更を加えた自分自身の複製
    def -(other)
      list = SpriteList.new
      self.to_a.each{|pair| list.add(pair[0], pair[1].dup) unless other.has_key?(pair[0])}
      list
    end

    #===引数と自分自身とのANDを取る
    #方法は積集合と同じ(#*参照)
    #_other_:: 計算をするSpriteList
    #返却値:: 変更を加えた自分自身の複製
    def &(other)
      self * other
    end

    #===引数と自分自身とのORを取る
    #方法は和集合と同じ(#+参照)
    #_other_:: 計算をするSpriteList
    #返却値:: 変更を加えた自分自身の複製
    def |(other)
      self + other
    end

    #===引数と内容が同じかどうかを確認する
    #方法は#eql?と同じ(#eql?参照)
    #_other_:: 比較元SpriteList
    #返却値:: 同じ内容ならばtrue,違ったらfalseを返す
    def ==(other)
      self.eql?(other)
    end

    #===名前・スプライトを登録する
    #リストに名前・スプライトをリストの後ろに追加する
    #効果はSpriteList#push,<<と同じ
    #_name_:: スプライト名
    #_sprite_:: スプライト本体
    #返却値:: 追加した自分自身を渡す
    def add(name, sprite)
      self.push([name, sprite])
    end

    #===名前・スプライトの対を登録する
    #リストに名前・スプライトをリストの後ろに追加する
    #効果はSpriteList#addと同じだが、複数の対を登録できることが特徴
    #(例)push([name1,sprite1])
    #    push([name1,sprite1],[name2,sprite2])
    #_pairs_:: 名前とスプライトの対を配列にしたもの。対は、[name,sprite]として渡す。
    #返却値:: 追加した自分自身を渡す
    def push(*pairs)
      pairs.each{|name, sprite|
        unless sprite.class.include?(SpriteBase) || sprite.class.include?(SpriteArray)
          raise MiyakoValueError, "Illegal Sprite!"
        end
        pair = ListPair.new(name, sprite)
        @list.reject!{|pair| pair.name == name}
        @list <<  pair
      }
      return self
    end

    #===リストの終端から名前・スプライトの対を取り出す
    #リストに名前・スプライトをリストの終端から取り除いて、取り除いた対を返す
    #返却値:: 終端にあった名前に対応するListPair構造体
    def pop
      return nil if @list.empty?
      @list.pop
    end

    #===名前・スプライトを登録する
    #リストに名前・スプライトをリストの先頭に追加する
    #(先頭に追加することがSpriteList#<<,add,pushとの違い)
    #_name_:: スプライト名
    #_sprite_:: スプライト本体
    #返却値:: 追加した自分自身を渡す
    def unshift(name, sprite)
      @list.reject!{|pair| pair.name == name}
      @list.unshift(ListPair.new(name, sprite))
      return self
    end

    #===指定した名前の要素を取り除いたSpriteListを取得する
    #登録されていない名前が指定されたときは何もしない
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.slice(:a,:b)
    #      =>a=SpriteList(pair(:c))
    #        b=SpriteList(pair(:a),pair(:b))
    #    b=a.slice(:d,:b)
    #      =>a=SpriteList(pair(:a),pair(:c))
    #        b=SpriteList(pair(:b))
    #_names_:: スプライト名のリスト
    #返却値:: 自分自身の複製から指定した名前の要素を取り除いたインスタンス
    def slice(*names)
      list = self.dup
      list.delete_if!{|name, sprite| !names.include?(name)}
    end

    #===指定した名前の要素を取り除く
    #登録されていない名前が指定されたときは何もしない
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.slice!(:a,:b)
    #      =>a=SpriteList(pair(:c))
    #        b=SpriteList(pair(:c))
    #    b=a.slice!(:d,:b)
    #      =>a=SpriteList(pair(:a),pair(:c))
    #        b=SpriteList(pair(:a),pair(:c))
    #_names_:: スプライト名のリスト
    #返却値:: 更新した自分自身
    def slice!(*names)
      self.delete_if!{|name, sprite| !names.include?(name)}
    end

    #===指定した数の要素を先頭から取り除く
    #SpriteListの先頭からn個の要素を取り除いて、新しいSpriteListとする。
    #nがマイナスの時は、後ろからn個の要素を取り除く。
    #nが0の時は、空のSpriteListを返す。
    #自分自身に何も登録されていなければnilを返す
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.shift(1)
    #      =>a=SpriteList(pair(:b),pair(:c))
    #        b=SpriteList(pair(:a))
    #    b=a.shift(2)
    #      =>a=SpriteList(pair(:c))
    #        b=SpriteList(pair(:a),pair(:b))
    #    b=a.shift(0)
    #      =>a=SpriteList(pair(:a),pair(:b),pair(:c))
    #        b=SpriteList()
    #(例)a=SpriteList()
    #    b=a.shift(1)
    #      =>a=SpriteList()
    #        b=nil
    #_n_:: 取り除く要素数。省略時は1
    #返却値:: 取り除いた要素から作られたSpriteList
    def shift(n = 1)
      return nil if @list.empty?
      return SpriteList.new if n == 0
      SpriteList.new(@list.shift(n))
    end

    #===指定した数の要素を先頭から取り除く
    #SpriteListの先頭からn個の要素を取り除いて、新しいSpriteListとする。
    #nがマイナスの時は、後ろからn個の要素を取り除く。
    #nが0の時は、空のSpriteListを返す。
    #自分自身に何も登録されていなければnilを返す
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.delete(:b)
    #      =>a=SpriteList(pair(:a),pair(:c))
    #        b=SpriteList(pair(:b))
    #    b=a.delete(:d)
    #      =>a=SpriteList(pair(:a),pair(:b),pair(:c))
    #        b=nil
    #_n_:: 取り除く要素数。省略時は1
    #返却値:: 取り除いたSpriteListPair
    def delete(name)
      pair = @list.find{|pair| pair.name == name}
      return nil unless pair
      @list.delete(pair)
      pair
    end

    #===指定したインデックスの要素を取り除く
    #SpriteListの先頭からn個の要素を取り除いて、新しいSpriteListとする。
    #nがマイナスの時は、後ろからn個の要素を取り除く。
    #nが0の時は、空のSpriteListを返す。
    #自分自身に何も登録されていなければnilを返す
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.delete_at(2)
    #      =>a=SpriteList(pair(:a),pair(:b))
    #        b=SpriteList(pair(:c))
    #    b=a.delete_at(3)
    #      =>a=SpriteList(pair(:a),pair(:b),pair(:c))
    #        b=nil
    #_idx_:: 取り除く要素数。省略時は1
    #返却値:: 取り除いた要素から作られたSpriteList
    def delete_at(idx)
      self.delete(@list[idx])
    end

    #===ブロックの評価結果が真のときのみ削除するSpriteListを作成
    #SpriteListの複製を作り、各要素でブロックを評価したときに、真になった要素は削除される。
    #引数は、各要素を示すListPari構造体インスタンスが渡ってくる。
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.delete_if{|pair| pair[0] == :b}
    #      =>a=SpriteList(pair(:a),pair(:b),pair(:c))
    #        b=SpriteList(pair(:b))
    #返却値:: 取り除いた後のSpriteList
    def delete_if
      ret = self.deep_dup
      ret.each{|pair| ret.delete(pair) if yield(*pair)}
      ret
    end

    #===ブロックの評価結果が真のときのみ削除するSpriteListを作成
    #SpriteListの複製を作り、各要素でブロックを評価したときに、真になった要素は削除される。
    #引数は、各要素を示すListPari構造体インスタンスが渡ってくる。
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.reject{|pair| pair[0] == :b}
    #      =>a=SpriteList(pair(:a),pair(:b),pair(:c))
    #        b=SpriteList(pair(:b))
    #返却値:: 取り除いた後のSpriteList
    def reject
      ret = self.deep_dup
      ret.each{|pair| ret.delete(pair) if yield(*pair)}
      ret
    end

    #===ブロックの評価結果が真のときのみ破壊的に削除する
    #自分自身に対して、各要素でブロックを評価したときに、真になった要素は削除される。
    #引数は、各要素を示すListPari構造体インスタンスが渡ってくる。
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.delete_if!{|pair| pair[0] == :b}
    #      =>a=SpriteList(pair(:a),pair(:c))
    #        b=SpriteList(pair(:b))
    #返却値:: 取り除いた後のSpriteList
    def delete_if!
      self.each{|pair| self.delete(pair) if yield(*pair)}
      self
    end

    #===ブロックの評価結果が真のときのみ破壊的に削除する
    #自分自身に対して、各要素でブロックを評価したときに、真になった要素は削除される。
    #引数は、各要素を示すListPari構造体インスタンスが渡ってくる。
    #(例)a=SpriteList(pair(:a),pair(:b),pair(:c))
    #    b=a.reject!{|pair| pair[0] == :b}
    #      =>a=SpriteList(pair(:a),pair(:c))
    #        b=SpriteList(pair(:b))
    #返却値:: 取り除いた後のSpriteList
    def reject!
      self.each{|pair| self.delete(pair) if yield(*pair)}
      self
    end

    #===別のSpriteListと破壊的につなげる
    #自分自身にotherで指定したListの要素をつなげる。
    #ただし、既に自分自身に登録されている要素は追加しない。
    #(例)a=SpriteList(pair(:a),pair(:b)(b1),pair(:c))
    #    b=SpriteList(pair(:b)(b2),pair(:d),pair(:e))
    #    a.concat(b)
    #      =>a=SpriteList(pair(:a),pair(:b)(b1),pair(:c),pair(:d),pair(:e))
    #        b=SpriteList(pair(:b)(b2),pair(:d),pair(:e))
    #返却値:: 自分自身を返す
    def concat(other)
      other.each{|pair| self.add(pair[0],pair[1].dup) unless self.has_name?(pair[0]) }
      self
    end

    #===引数と自分自身との結果をマージする
    #otherで割り付けられた名前のうち、自分では登録されていないものは新規登録する(方法はpushと同じ)
    #名前がバッティングしたときは自分自身の本体を優先する
    #_other_:: マージするSpriteList
    #返却値:: 変更を加えた自分自身の複製
    def merge(other)
      ret = other.dup + self
      ret.names.each{|name| yield name, self[name], other[name] } if block_given?
      ret
    end

    #===自分自身と引数との結果を破壊的にマージする
    #otherで割り付けられた名前のうち、自分では登録されていないものは新規登録する(方法はpushと同じ)
    #名前がバッティングしたときは自分自身の本体を優先する
    #_other_:: マージするSpriteList
    #返却値:: 変更された自分自身
    def merge!(other)
      self.replace(other+self)
      self.names.each{|name| yield name, self[name], other[name] } if block_given?
      self
    end

    #===名前-スプライトの対を繰り返し取得する
    #インスタンスを配列化し、周回して要素を取得できるEnumeratorを生成する
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c)).cycle
    #   =>pair(:a),pair(:b),pair(:c),pair(:a),pair(:b),pair(:c),pair(:a)...
    #返却値:: 生成されたEnumerator
    def cycle(&block)
      return self.to_enum(:cycle) unless block_given?
      self.to_a.cycle(&block)
    end

    #===名前の順番をシャッフルしたSpriteListを返す
    #自分自身を複製し、登録されている名前の順番をシャッフルして返す
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c))
    #   a.shuffle
    #   =>SpriteList(pair(:a),pair(:b),pair(:c)) or SpriteList(pair(:a),pair(:c),pair(:b)) or
    #     SpriteList(pair(:b),pair(:a),pair(:c)) or SpriteList(pair(:b),pair(:c),pair(:a)) or
    #     SpriteList(pair(:c),pair(:a),pair(:b)) or SpriteList(pair(:c),pair(:b),pair(:a))
    #     a=SpriteList(pair(:a),pair(:b),pair(:c))
    #返却値:: シャッフルした自分自身の複製
    def shuffle
      self.dup.shuffle!
    end

    #===名前の順番をシャッフルする
    #自分自身で登録されている名前の順番をシャッフルする
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c))
    #   a.shuffle!
    #   =>a=SpriteList(pair(:a),pair(:b),pair(:c)) or SpriteList(pair(:a),pair(:c),pair(:b)) or
    #       SpriteList(pair(:b),pair(:a),pair(:c)) or SpriteList(pair(:b),pair(:c),pair(:a)) or
    #       SpriteList(pair(:c),pair(:a),pair(:b)) or SpriteList(pair(:c),pair(:b),pair(:a))
    #返却値:: シャッフルした自分自身
    def shuffle!
      @list.shuffle!
      self
    end

    #===自身から要素をランダムに選ぶ
    #自分自身を配列化(to_ary)し、最大n個の要素(ListPair)をランダムに選び出して配列として返す
    #自分自身が空のときは、n=nilのときはnilを、n!=nilのときは空配列を返す
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c))
    #   a.sample(1)
    #   =>[pair(:a)] or [pair(:b)] or [pair(:c)]
    #   a.sample(2)
    #   =>[pair(:a),pair(:b)] or [pair(:a),pair(:c)] or
    #     [pair(:b),pair(:a)] or [pair(:b),pair(:c)] or
    #     [pair(:c),pair(:a)] or [pair(:c),pair(:b)]
    #   a.sample(3)
    #   =>[pair(:a),pair(:b),pair(:c)] or [pair(:a),pair(:c),pair(:b)] or
    #     [pair(:b),pair(:a),pair(:c)] or [pair(:b),pair(:c),pair(:a)] or
    #     [pair(:c),pair(:a),pair(:b)] or [pair(:c),pair(:b),pair(:a)]
    #_n_:: 選び出す個数。n=nilのときは1個とみなす
    #返却値:: 選び出したListPairを配列化したもの
    def sample(n=nil)
      n ? self.to_a.sample(n) : self.to_a.sample
    end

    #===自身での組み合わせを配列として返す
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c))
    #   a.combination(1)
    #   =>[[pair(:a)],[pair(:b)],[pair(:c)]]
    #   a.combination(2)
    #   =>[[pair(:a),pair(:b)],[pair(:a),pair(:c)],[pair(:b),pair(:c)]]
    #   a.combination(3)
    #   =>[[pair(:a),pair(:b),pair(:c)]]
    #自分自身を配列化(to_ary)し、サイズnの組み合わせをすべて求めて配列化したものを
    #Enumeratorとして返す
    #_n_:: 組み合わせのサイズ
    #返却値:: Enumerator(ただしブロックを渡すと配列)
    def combination(n, &block)
      self.to_a.combination(n, &block)
    end

    #===自身での順列を配列として返す
    #自分自身を配列化(to_ary)し、サイズnの順列をすべて求めて配列化したものを
    #Enumeratorとして返す
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c))
    #   a.permutation(1)
    #   =>[[pair(:a)],[pair(:b)],[pair(:c)]]
    #   a.permutation(2)
    #   =>[[pair(:a),pair(:b)],[pair(:a),pair(:c)],
    #      [pair(:b),pair(:a)],[pair(:b),pair(:c)],
    #      [pair(:c),pair(:a)],[pair(:c),pair(:b)]]
    #   a.permutation(3)
    #   =>[[pair(:a),pair(:b),pair(:c)],[pair(:a),pair(:c),pair(:b)],
    #      [pair(:b),pair(:a),pair(:c)],[pair(:b),pair(:c),pair(:a)],
    #      [pair(:c),pair(:a),pair(:b)],[pair(:c),pair(:b),pair(:a)]]
    #_n_:: 順列のサイズ
    #返却値:: Enumerator(ただしブロックを渡すと配列)
    def permutation(n, &block)
      self.to_a.permutation(n, &block)
    end

    private :reflesh

    #===内容を引数のものに置き換える
    #現在登録されているデータをいったん解除し、
    #引数として渡ってきたSpriteListの無いようにデータを置き換える
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c),pair(:d))
    #   a.replace(SpriteList(pair(:e),pair(:f),pair(:g),pair(:h)))
    #   =>a=SpriteList(pair(:e),pair(:f),pair(:g),pair(:h))
    #_other_:: 置き換え元のSpriteList
    #返却値:: 置き換えた自分自身
    def replace(other)
      self.clear
      other.to_a.each{|pair| self.add(pair[0], pair[1].dup)}
      self
    end

    #===名前の順番を反転する
    #名前の順番を反転した、自分自身のコピーを生成する
    #例:a=SpriteList(pari(:a),pair(:b),pair(:c),pair(:d))
    #   a.reverse
    #   =>SpriteList(pari(:d),pair(:c),pair(:b),pair(:a))
    #     a=SpriteList(pari(:a),pair(:b),pair(:c),pair(:d))
    #返却値:: 名前を反転させた自分自身の複製を返す
    def reverse
      ret = self.dup
      ret.reverse!
    end

    #===名前の順番を破壊的に反転する
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c),pair(:d))
    #   a.reverse!
    #   =>SpriteList(pair(:d),pair(:c),pair(:b),pair(:a))
    #     a=SpriteList(pair(:d),pair(:c),pair(:b),pair(:a))
    #返却値:: 自分自身を帰す
    def reverse!
      @list.reverse!
      return self
    end

    #===名前と関連付けられたスプライトを取得する
    #関連付けられているスプライトが見つからなければnilが返る
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c),pair(:d))
    #   a[:c] => spr(:c)
    #   a[:q] => nil
    #_name_:: 名前
    #返却値:: 名前に関連付けられたスプライト
    def [](name)
      pair = @list.find{|pair| pair.name == name }
      return pair ? pair.body : nil
    end

    #===名前と関連付けられたスプライトを置き換える
    #名前に対応したスプライトを、引数で指定したものに置き換える。
    #ただし、まだ名前が登録されていないときは、新規追加と同じになる。
    #新規追加のときはSpriteList#pushと同じ
    #例:SpriteList(pair(:a),pair(:b),pair(:c),pair(:d))[:e]=spr(:e)
    #   => SpriteList(pair(:a),pair(:b),pair(:c),pair(:d),pair(:e))
    #例:SpriteList(pair(:a),pair(:b),pair(:c),pair(:d))[:b]=spr(:b2)
    #   => SpriteList(pair(:a),pair(:b2),pair(:c),pair(:d))
    #_name_:: 名前
    #_sprite_:: スプライト
    #返却値:: 登録された自分自身
    def []=(name, sprite)
      return self.push([name, sprite]) unless self.names.include?(name)
      @list[self.names.index(name)].body = sprite
      return self
    end

    #===名前の一覧から新しいSpriteListを生成する
    #リストの順番はnamesの順番と同じ
    #自分自身に登録されていない名前があったときはnilが登録される
    #例:SpriteList(pair(:a),pair(:b),pair(:c),pair(:d)).pairs_at(:b, :d)
    #   => [pair(:b),pair(:d)]
    #例:SpriteList(pair(:a),pair(:b),pair(:c),pair(:d)).pairs_at(:b, :e)
    #   => [pair(:b),nil]
    #_names_:: 取り出した名前のリスト名前
    #返却値:: 生成されたSpriteList
    def pairs_at(*names)
      SpriteList.new(@list.select{|pair| names.include?(pair.name)})
    end

    #===名前の一覧から本体のリストを生成する
    #本体のみの配列を返す。要素の順番はnamesの順番と同じ
    #自分自身に登録されていない名前があったときはnilが登録される
    #例:SpriteList(pair(:a),pair(:b),pair(:c),pair(:d)).values_at(:b, :d)
    #   => [spr(:b),spr(:d)]
    #例:SpriteList(pair(:a),pair(:b),pair(:c),pair(:d)).values_at(:b, :e)
    #   => [spr(:b),nil]
    #_names_:: 取り出した名前のリスト名前
    #返却値:: 生成された配列
    def values_at(*names)
      @list.search{|pair| names.include?(pair.name)}.map{|pair| pair.body }
    end

    #===SpriteListを配列化し、同じ位置の要素を一つの配列にまとめる
    #自分自身に登録されていない名前があったときはnilが登録される
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).zip(SpriteList(pair(:d),pair(:e),pair(:f))
    #   => [[pair(:a),pair(:d)],[pair(:b),pair(:e)],[pair(:c),pair(:f)]]
    #例:SpriteList(pair(:a),pair(:b)).zip(SpriteList(pair(:d),pair(:e),pair(:f))
    #   => [[pair(:a),pair(:d)],[pair(:b),pair(:e)]]
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).zip(SpriteList(pair(:d),pair(:e))
    #   => [[pair(:a),pair(:d)],[pair(:b),pair(:e)],[pair(:c),nil]]
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).zip(
    #       SpriteList(pair(:d),pair(:e),pair(:f),
    #       SpriteList(pair(:g),pair(:h),pair(:i))
    #   => [[pair(:a),pair(:d),pair(:g)],[pair(:b),pair(:e),pair(:h)],[pair(:c),pair(:f),pair(:i)]]
    #_names_:: 取り出した名前のリスト名前
    #返却値:: 生成されたSpriteList
    def zip(*lists, &block)
      lists = lists.map{|list| list.to_a}
      self.to_a.zip(*lists, &block)
    end

    #===各要素の位置を変更する(変化量を指定)
    #ブロックを渡したとき、戻り値として[更新したdx,更新したdy]とした配列を返すと、
    #それがその要素での移動量となる。
    #ブロックの引数は、|ListPair, インデックス(0,1,2,...), dx, dy|となる。
    #(例)a=SpriteList(pair(:a), pair(:b), pair(:c))
    #    #各スプライトの位置=すべて(10,15)
    #    a.move!(20,25) => pair(:a)の位置:(30,40)
    #                      pair(:b)の位置:(30,40)
    #                      pair(:c)の位置:(30,40)
    #    a.move!(20,25){|pair,i,dx,dy|
    #      [i*dx, i*dy]
    #    }
    #                   => pair(:a)の位置:(10,15)
    #                      pair(:b)の位置:(30,40)
    #                      pair(:c)の位置:(50,65)
    #_dx_:: 移動量(x方向)。単位はピクセル
    #_dy_:: 移動量(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move!(dx, dy)
      if block_given?
        @list.each_with_index{|pair, i|
          pair.body.move!(*(yield pair, i, dx, dy))
        }
      else
        @list.each{|pair| pair.body.move!(dx, dy) }
      end
      self
    end

    #===各要素の位置を変更する(変化量を指定)
    #ブロックを渡したとき、戻り値として[更新したdx,更新したdy]とした配列を返すと、
    #それがその要素での移動量となる。
    #ブロックの引数は、|ListPair, インデックス(0,1,2,...), x, y|となる。
    #(例)a=SpriteList(pair(:a), pair(:b), pair(:c))
    #    #各スプライトの位置=すべて(10,15)
    #    a.move!(20,25) => pair(:a)の位置:(20,25)
    #                      pair(:b)の位置:(20,25)
    #                      pair(:c)の位置:(20,25)
    #    a.move!(20,25){|pair,i,dx,dy|
    #      [i*dx, i*dy]
    #    }
    #                   => pair(:a)の位置:( 0, 0)
    #                      pair(:b)の位置:(20,25)
    #                      pair(:c)の位置:(40,50)
    #_x_:: 移動先位置(x方向)。単位はピクセル
    #_y_:: 移動先位置(y方向)。単位はピクセル
    #返却値:: 自分自身を返す
    def move_to!(x, y)
      if block_given?
        @list.each_with_index{|pair, i|
          pair.body.move_to!(*(yield pair, i, x, y))
        }
      else
        @list.each{|pair| pair.body.move_to!(x, y) }
      end
      self
    end

    #===リストを配列化する
    #インスタンスの内容を元に、配列を生成する。
    #各要素は、ListPair構造体
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c)).to_a
    #   => [pair(:a),pair(:b),pair(:c)]
    #返却値:: 生成した配列
    def to_a
      self.to_ary
    end

    #===リストを配列化する
    #インスタンスの内容を元に、配列を生成する。
    #各要素は、ListPair構造体
    #例:a=SpriteList(pair(:a),pair(:b),pair(:c)).to_ary
    #   => [pair(:a),pair(:b),pair(:c)]
    #返却値:: 生成した配列
    def to_ary
      @list.dup
    end

    #===スプライト名とスプライト本体とのハッシュを取得する
    #スプライト名とスプライト本体が対になったハッシュを作成して返す
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).to_hash
    #   => {:a=>spr(:a),:b=>spr(:b),:c=>spr(:c)}
    #返却値:: 生成したハッシュ
    def to_hash
      @list.inject({}){|r, pair| r[pair.name] = pair.value}
    end

    #===リストの中身を消去する
    #リストに登録されているスプライト名・スプライト本体への登録を解除する
    def clear
      @list.clear
    end

    #===オブジェクトを解放する
    def dispose
      @list.clear
      @list = nil
    end

    #===名前に対して値を渡す
    #仕様はHash#fetchと同じ
    def fetch(name, default = nil, &block)
      ret = @list.find(nil){|pair| pair.name == name}
      ret = default unless ret
      yield ret if block_given?
      ret
    end

    #===指定の名前の直前に名前を挿入する
    #配列上で、keyの前にnameを挿入する
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).insert(:b, :d, spr(:d))
    #   => SpriteList(pair(:a),pair(:d),pair(:b),pair(:c))
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).insert(:c, :a)
    #   => SpriteList(pair(:c),pair(:a),pair(:b))
    #_key_:: 挿入先の名前。この名前の直前に挿入する
    #_name_:: 挿入するスプライトの名前
    #_value_:: (名前が未登録の時の)スプライト本体省略時はnil
    #返却値：自分自身を返す
    def insert(key, name, value = nil)
      raise MiyakoValueError, "Illegal key! : #{key}" unless self.names.include?(key)
      return self if key == name
      pair = ListPair.new(name, value)
      unless value
        pair = @list.find{|pair| pair.name == name}
        raise MiyakoValueError, "name is not regist! : #{name}" unless pair
      end
      self.delete(name)
      @list.insert(self.names.index(key), pair)
      self
    end

    #===指定の名前の直後に名前を挿入する
    #配列上で、keyの後ろにnameを挿入する
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).insert_after(:b, :d, spr(:d))
    #   => SpriteList(pair(:a),pair(:b),,pair(:d)pair(:c))
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).insert_after(:c, :b)
    #   => SpriteList(pair(:a),pair(:c),pair(:b))
    #_key_:: 挿入先の名前。この名前の直後に挿入する
    #_name_:: 挿入するスプライトの名前
    #_value_:: (名前が未登録の時の)スプライト本体。省略時はnil
    #返却値：自分自身を返す
    def insert_after(key, name, value = nil)
      raise MiyakoValueError, "Illegal key! : #{key}" unless self.names.include?(key)
      return self if key == name
      if value
        pair = ListPair.new(name, value)
      else
        pair = @list.find{|pair| pair.name == name}
        raise MiyakoValueError, "name is not regist! : #{name}" unless pair
      end
      self.delete(name)
      @list.insert(self.names.index(key)-@list.length, pair)
      self
    end

    #===指定した要素の内容を入れ替える
    #例:SpriteList(pair(:a),pair(:b),pair(:c),pair(:d)).insert(:b, :d)
    #   => SpriteList(pair(:a),pair(:d),pair(:c),pair(:b))
    #_name1,name_:: 入れ替え対象の名前
    #返却値:: 自分自身を帰す
    def swap(name1, name2)
      names = self.names
      raise MiyakoValueError, "Illegal name! : idx1:#{name1}" unless names.include?(name1)
      raise MiyakoValueError, "Illegal name! : idx2:#{name2}" unless names.include?(name2)
      idx1 = names.index(name1)
      idx2 = names.index(name2)
      @list[idx1], @list[idx2] = @list[idx2], @list[idx1]
      return self
    end

    #===指定の名前の順番に最前面から表示するように入れ替える
    #namesで示した名前一覧の順番を逆転させて、配列の一番後ろに入れ替える。
    #(renderメソッドは、配列の一番後ろのスプライトが一番前に描画されるため
    #存在しない名前を指定すると例外MiyakoErrorが発生する
    #(例)
    #[:a,:b,:c,:d,:e]のとき、pickup(:d,:a,:e) -> [:d, :a, :e, :b,:c]
    #_names_:: 入れ替えるスプライトの名前一覧
    #返却値：自分自身を返す
    def to_first_inner(name)
      raise MiyakoError, "Canoot regist name! #{name}" unless self.names.include?(name)
      @list.unshift(self.delete(name))
    end

    private :to_first_inner

    #===配列の最初で、指定の名前の順番に描画するように入れ替える
    #namesで示した名前一覧の順番を逆転させて、配列の一番後ろに入れ替える。
    #(renderメソッドは、配列の一番後ろのスプライトが一番前に描画されるため
    #存在しない名前を指定すると例外MiyakoErrorが発生する
    #(例)
    #[:a,:b,:c,:d,:e]のとき、pickup(:d,:a,:e) -> [:d, :a, :e, :b,:c]
    #_names_:: 入れ替えるスプライトの名前一覧
    #返却値：入れ替えたSpriteListの複製を返す
    def to_first(*names)
      ret = self.dup
      ret.to_first!(*names)
    end

    #===配列の最初で、指定の名前の順番に描画するように破壊的に入れ替える
    #namesで示した名前一覧の順番を逆転させて、配列の一番後ろに入れ替える。
    #(renderメソッドは、配列の一番後ろのスプライトが一番前に描画されるため
    #存在しない名前を指定すると例外MiyakoErrorが発生する
    #(例)
    #[:a,:b,:c,:d,:e]のとき、pickup(:d,:a,:e) -> [:b,:c,:e,:a,:d]
    #_names_:: 入れ替えるスプライトの名前一覧
    #返却値：自分自身を返す
    def to_first!(*names)
      names.reverse.each{|name| to_first_inner(name) }
      self
    end

    #===指定の名前の順番に最前面から表示するように入れ替える
    #namesで示した名前一覧の順番を逆転させて、配列の一番後ろに入れ替える。
    #(renderメソッドは、配列の一番後ろのスプライトが一番前に描画されるため
    #存在しない名前を指定すると例外MiyakoErrorが発生する
    #(例)
    #[:a,:b,:c,:d,:e]のとき、pickup(:d,:a,:e) -> [:b,:c,:e,:a,:d]
    #_names_:: 入れ替えるスプライトの名前一覧
    #返却値：自分自身を返す
    def pickup_inner(name)
      raise MiyakoError, "Canoot regist name! #{name}" unless self.names.include?(name)
      @list.push(self.delete(name))
    end

    private :pickup_inner

    #===指定の名前の順番に最前面から表示するように入れ替える
    #namesで示した名前一覧の順番を逆転させて、配列の一番後ろに入れ替える。
    #(renderメソッドは、配列の一番後ろのスプライトが一番前に描画されるため
    #存在しない名前を指定すると例外MiyakoErrorが発生する
    #(例)
    #[:a,:b,:c,:d,:e]のとき、pickup(:d,:a,:e) -> [:b,:c,:e,:a,:d]
    #_names_:: 入れ替えるスプライトの名前一覧
    #返却値：入れ替えたSpriteListの複製を返す
    def pickup(*names)
      ret = self.dup
      ret.pickup!(*names)
    end

    #===指定の名前の順番に最前面から表示するように破壊的に入れ替える
    #namesで示した名前一覧の順に、配列の一番後ろに入れ替える。
    #(renderメソッドは、配列の一番後ろのスプライトが一番前に描画されるため
    #存在しない名前を指定すると例外MiyakoErrorが発生する
    #(例)
    #[:a,:b,:c,:d,:e]のとき、pickup(:d,:a,:e) -> [:b,:c,:e,:a,:d]
    #_names_:: 入れ替えるスプライトの名前一覧
    #返却値：自分自身を返す
    def pickup!(*names)
      names.reverse.each{|name| pickup_inner(name) }
      self
    end

    #===配列の最後で、指定の名前の順番に描画するように入れ替える
    #配列の最後に、namesで示した名前一覧の順に要素を入れ替える。
    #(renderメソッドは、配列の一番後ろのスプライトが一番前に描画されるため
    #存在しない名前を指定すると例外MiyakoErrorが発生する
    #(例)
    #[:a,:b,:c,:d,:e]のとき、pickup(:d,:a,:e) -> [:b,:c,:d,:a,:e]
    #_names_:: 入れ替えるスプライトの名前一覧
    #返却値：入れ替えたSpriteListの複製を返す
    def to_last(*names)
      ret = self.dup
      ret.to_last!(*names)
    end

    #===配列の最後で、指定の名前の順番に描画するように破壊的に入れ替える
    #配列の最後に、namesで示した名前一覧の順に要素を入れ替える。
    #(renderメソッドは、配列の一番後ろのスプライトが一番前に描画されるため
    #存在しない名前を指定すると例外MiyakoErrorが発生する
    #(例)
    #[:a,:b,:c,:d,:e]のとき、pickup(:d,:a,:e) -> [:b,:c,:d,:a,:e]
    #_names_:: 入れ替えるスプライトの名前一覧
    #返却値：自分自身を返す
    def to_last!(*names)
      names.each{|name| pickup_inner(name) }
      self
    end

    #===要素全体もしくは一部を描画可能状態にする
    #他のshowメソッドとの違いは、名前のリストを引数に取れること(省略可)。
    #paramsで指定した名前に対応したスプライトのみ描画可能にする
    #paramsの省略時は自分自身を描画可能にする(現在、どの要素が描画可能かは考えない。他クラスのshowと同じ動作)
    #すべての要素を描画可能にしたいときは、引数にSpriteList#allを使用する
    #paramsに登録されていない名前が含まれているときは無視される
    #また、ブロック(名前nameとスプライトbodyが引数)を渡したときは、リストに渡した名前一覧のうち、
    #ブロックを評価した結果がtrueのときのみ描画可能にする。
    #(引数paramsを省略したときは、すべての要素に対してブロックを評価すると見なす)
    #_params_:: 表示対象に名前リスト。
    def show(*params)
      if block_given?
        if params == []
          @list.each{|pair| pair.body.show if yield(pair.name, pair.body) }
        else
          @list.each{|pair|
            next unless params.include?(pair.name)
            pair.body.show if yield(pair.name, pair.body)
          }
        end
      elsif params == []
        self.visible = true
      else
        @list.each{|pair| pair.body.show if params.include?(pair.name) }
      end
    end

    #===要素全体もしくは一部を描画不可能状態にする
    #他のhideメソッドとの違いは、名前のリストを引数に取れること(省略可)。
    #paramsで指定した名前に対応したスプライトのみ描画不可能にする
    #paramsの省略時は自分自身を描画不可にする(現在、どの要素が描画不可になっているかは考えない。他クラスのhideと同じ動作)
    #すべての要素を描画不可能にしたいときは、引数にSpriteList#allを使用する
    #paramsに登録されていない名前が含まれているときは無視される
    #また、ブロック(名前nameとスプライトbodyが引数)を渡したときは、リストに渡した名前一覧のうち、
    #ブロックを評価した結果がtrueのときのみ描画可能にする。
    #(引数paramsを省略したときは、すべての要素に対してブロックを評価すると見なす)
    #_params_:: 表示対象に名前リスト。
    def hide(*params)
      if block_given?
        if params == []
          @list.each{|pair| pair.body.hide if yield(pair.name, pair.body) }
        else
          @list.each{|pair|
            next unless params.include?(pair.name)
            pair.body.hide if yield(pair.name, pair.body)
          }
        end
      elsif params == []
        self.visible = false
      else
        @list.each{|pair| pair.body.hide if params.include?(pair.name) }
      end
    end

    #===要素全体もしくは一部のみ描画可能状態にする
    #paramsで指定した名前に対応したスプライトのみ描画可能にし、それ以外を描画不可能にする
    #paramsに登録されていない名前が含まれているときは無視される
    #paramsを省略したときは、すべての要素を描画可能にする
    #また、ブロック(名前nameとスプライトbodyが引数)を渡したときは、リストに渡した名前一覧のうち、
    #ブロックを評価した結果がtrueのときのみ描画可能にする。
    #_params_:: 表示対象に名前リスト。
    def show_only(*params)
      if block_given?
        if params == []
          @list.each{|pair| yield(pair.name, pair.body) ? pair.body.show : pair.body.hide }
        else
          @list.each{|pair|
            next unless params.include?(pair.name)
            yield(pair.name, pair.body) ? pair.body.show : pair.body.hide
          }
        end
      elsif params == []
        @list.each{|pair| pair.body.show }
      else
        @list.each{|pair| params.include?(pair.name) ? pair.body.show : pair.body.hide }
      end
    end

    #===要素全体もしくは一部のみ描画不可能状態にする
    #paramsで指定した名前に対応したスプライトのみ描画不可能にし、それ以外を描画可能にする
    #paramsに登録されていない名前が含まれているときは無視される
    #paramsを省略したときは、すべての要素を描画不可能にする
    #また、ブロック(名前nameとスプライトbodyが引数)を渡したときは、リストに渡した名前一覧のうち、
    #ブロックを評価した結果がtrueのときのみ描画可能にする。
    #_params_:: 表示対象に名前リスト。
    def hide_only(*params)
      if block_given?
        if params == []
          @list.each{|pair| yield(pair.name, pair.body) ? pair.body.hide : pair.body.show }
        else
          @list.each{|pair|
            next unless params.include?(pair.name)
            yield(pair.name, pair.body) ? pair.body.hide : pair.body.show
          }
        end
      elsif params == []
        @list.each{|pair| pair.body.hide }
      else
        @list.each{|pair| params.include?(pair.name) ? pair.body.hide : pair.body.show }
      end
    end

    #===各要素のアニメーションを開始する
    #各要素のstartメソッドを呼び出す
    #返却値:: 自分自身を返す
    def start
      self.sprite_only.each{|pair| pair[1].start }
      return self
    end

    #===各要素のアニメーションを停止する
    #各要素のstopメソッドを呼び出す
    #返却値:: 自分自身を返す
    def stop
      self.sprite_only.each{|pair| pair[1].stop }
      return self
    end

    #===各要素のアニメーションを先頭パターンに戻す
    #各要素のresetメソッドを呼び出す
    #返却値:: 自分自身を返す
    def reset
      self.sprite_only.each{|pair| pair[1].reset }
      return self
    end

    #===各要素のアニメーションを更新する
    #各要素のupdate_animationメソッドを呼び出す
    #返却値:: 各要素のupdate_spriteメソッドを呼び出した結果を配列で返す
    def update_animation
      self.sprite_only.map{|pair| pair[1].update_animation }
    end

    #===配列の要素を画面に描画する
    #配列の先頭から順にrenderメソッドを呼び出す。
    #返却値:: 自分自身を帰す
    def render
      return self unless @visible
      self.sprite_only.each{|pair| pair[1].render }
      return self
    end

    #===配列の要素を対象の画像に描画する
    #配列の先頭から順にrender_toメソッドを呼び出す。
    #_dst_:: 描画対象の画像インスタンス
    #返却値:: 自分自身を帰す
    def render_to(dst)
      return self unless @visible
      self.sprite_only.each{|pair| pair[1].render_to(dst) }
      return self
    end

    #===オブジェクトを文字列に変換する
    #いったん、名前とスプライトとの対の配列に変換し、to_sメソッドで文字列化する。
    #例:[[name1, sprite1], [name2, sprite2],...]
    #返却値:: 変換した文字列
    def to_s
      self.to_a.to_s
    end
  end
end
