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
  end
  
  #===名前-本体ペアを構成する構造体
  #ハッシュのようにキー・バリュー構成を持たせるための構造体
  #_name_:: 名前
  #_body_:: 本体
  ListPair = Struct.new(:name, :body)

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
    #ハッシュを引数として渡すと、キーをスプライト名とするSpriteListを生成する。
    #_pairs_:: 生成元のインスタンス
    #返却値:: 生成したインスタンス
    def initialize(pairs = nil)
      @names = []
      @n2v   = {}
      if pairs.is_a?(Array)
        pairs.each{|pair|
          @names << pair[0]
          @n2v[pair[0]] = ListPair.new(*pair)
        }
      elsif pairs.is_a?(Hash)
        pairs.each{|key, value|
          @names << key
          @n2v[key] = ListPair.new(key, value)
        }
      end
      @visible = true
    end
    
    #===内部で使用している配列などを新しいインスタンスに置き換える
    #initialize_copy用で元・新インスタンスで配列などを共用している場合に対応
    def reflesh
      @names = []
      @n2v = {}
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
      ret = self.dup
      ret.names.each{|name|
        ret.delete(name) if !ret[name].class.include?(SpriteBase) &&
                            !ret[name].class.include?(SpriteArray)
      }
      return ret
    end

    #===スプライト以外のインスタンスを破壊的に削除する
    #自分自身から、本体がnilや、SpriteBaseもしくはSpritArrayモジュールを
    #mixinしていない対を削除する。
    #返却値:: 自分自身を帰す
    def sprite_only!
      @names.each{|name|
        if !@n2v[name].class.include?(SpriteBase) &&
           !ret[name].class.include?(SpriteArray)
          @n2v.delete(name)
          @names.delete(name)
        end
      }
      return self
    end

    #===ブロックを受け取り、リストの各要素にたいして処理を行う
    #ブロック引数には、|[スプライト名,スプライト本体]|が渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each
      self.to_a.each{|pair| yield pair}
    end
    
    #===ブロックを受け取り、スプライト名リストの各要素にたいして処理を行う
    #ブロック引数には、|スプライト名,スプライト本体|が渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_pair
      @names.each{|name| yield *@n2v[name]}
    end
    
    #===ブロックを受け取り、名前リストの各要素にたいして処理を行う
    #ブロック引数には、|スプライト名|が渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_name
      @names.each{|name| yield name}
    end
    
    #===ブロックを受け取り、値リストの各要素にたいして処理を行う
    #ブロック引数には、|スプライト本体|の配列として渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_value
      @names.each{|name| yield @n2v[name].body}
    end
    
    #===ブロックを受け取り、配列インデックスにたいして処理を行う
    #ブロック引数には、|スプライト名に対応する配列インデックス|の配列として渡ってくる
    #0,1,2,...の順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_index
      @names.length.times{|idx| yield idx}
    end
    
    #===スプライト名配列を取得する
    #名前が登録されている順に渡ってくる
    #返却値:: スプライト名配列
    def names
      @names
    end
    
    #===スプライト配列を取得する
    #名前が登録されている順に渡ってくる
    #返却値:: スプライト本体配列
    def values
      @names.map{|name| @n2v[name].body}
    end
    
    #===名前-本体ペア配列を取得する
    #名前が登録されている順にListPair構造体の構造体を構成して返す
    #返却値:: ListPair構造体の配列
    def pairs
      @names.map{|name| @n2v[name].body}
    end
    
    #===リストが空っぽかどうか確かめる
    #リストに何も登録されていないかどうか確かめる
    #返却値:: 空っぽの時はtrue、なにか登録されているときはfalse
    def empty?
      @names.empty?
    end

    #===内容が同じかどうか比較する
    #リストに含まれるスプライト名(順番も)・値が同じかどうか比較する
    #返却値:: 同じときはtrue、違うときはfalseを返す
    def eql?(other)
      @names.map{|name|
        self.index(name) == other.index(name) &&
        @n2v[name].body.eql?(other[name].body)
      }.all?
    end
    
    #===リストに名前が登録されているか確認する
    #スプライト名リスト内に、引数で指定した名前が含まれているか調べる
    #(include?メソッドと同じ)
    #_name_:: 検索対象の名前
    #返却値:: 名前が含まれていればtrue、含まれていなければfalseと返す
    def has_name?(name)
      @n2v.has_key?(name)
    end
    
    #===リストに名前が登録されているか確認する
    #スプライト名リスト内に、引数で指定した名前が含まれているか調べる
    #(has_name?メソッドと同じ)
    #_name_:: 検索対象の名前
    #返却値:: 名前が含まれていればtrue、含まれていなければfalseと返す
    def include?(name)
      @names.has_key?(name)
    end
    
    #===リストにスプライトが登録されているか確認する
    #スプライトリスト内に、引数で指定したスプライトが含まれているか調べる
    #_value_:: 検索対象のスプライト
    #返却値:: スプライトが含まれていればtrue、含まれていなければfalseと返す
    def has_value?(value)
      @n2v.values.has_value?(value)
    end

    #===リストの長さを求める
    #スプライトの登録数(リストの要素数)を返す
    #(sizeメソッドと同じ)
    #返却値:: リストの要素数(殻のときは0)
    def length
      @names.length
    end

    #===リストの長さを求める
    #スプライトの登録数(リストの要素数)を返す
    #(lengthメソッドと同じ)
    #返却値:: リストの要素数(殻のときは0)
    def size
      @names.size
    end

    #===スプライト名を探し、あればその対を返す
    #引数で渡された名前を元に、リストから探し出す。
    #(内部でHash#assocを呼び出し)
    #_name_:: 検索対象のスプライト名
    #返却値:: 見つかればListPair構造体、無ければnil
    def assoc(name)
      @n2v.assoc(name)
    end

    #===スプライトが登録されている名前を求める
    #実際のスプライト本体から、登録されているスプライトを探す。
    #見つかれば、それに対応する名前を返す。
    #(内部でHash#keyメソッドを呼び出している)
    #_name_:: 検索対象のスプライト名
    #返却値:: 名前が見つかったときはそのスプライト名、無ければnil
    def name(value)
      @n2v.key(value)
    end
    
    #===名前が何番目にあるかを求める
    #スプライト名リスト中、指定したスプライト名のインデックスを求める
    #(内部でHash#indexメソッドを呼び出している)
    #_name_:: 検索対象のスプライト名
    #返却値:: 名前が見つかったときはそのインデックス(0以上の整数)、無ければnil
    def index(name)
      @names.index(name)
    end
    
    #===リストの先頭要素を求める
    #リストの先頭からn要素をSpriteListとして返す。
    #リストが空のとき、nが0のときはnilを返す
    #_n_:: 先頭からの数。省略時は1
    #返却値:: 先頭からn個の要素を設定したSpriteList
    def first(n=1)
      return nil if @names.empty?
      return nil if n == 0
      SpriteList.new(@names.first(n).map{|name| [name, @n2v[name]]})
    end
    
    #===リストの終端要素を求める
    #リストの終端からn要素をSpriteListとして返す。
    #リストが空のとき、nが0のときはnilを返す
    #_n_:: 終端からの数。省略時は1
    #返却値:: 終端からn個の要素を設定したSpriteList
    def last(n=1)
      return nil if @names.empty?
      return nil if n == 0
      SpriteList.new(@names.last(n).map{|name| [name, @n2v[name]]})
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
      other.to_a.each{|pair| list.add(pair)}
      list
    end
    
    #===引数と自分自身との積集合を取る
    #otherと自分自身で両方割り付けられた名前のみ登録されたリストを生成する
    #内容は自分自身の本体を割り当てる
    #_other_:: 計算をするSpriteList
    #返却値:: 変更を加えた自分自身の複製
    def *(other)
      list = SpriteList.new
      self.to_a.each{|pair| list.add(pair) if other.has_key?(pair[0])}
      list
    end
    
    #===引数と自分自身との差集合を取る
    #otherと自分自身で両方割り付けられた名前を取り除いたリストを生成する
    #_other_:: 計算をするSpriteList
    #返却値:: 変更を加えた自分自身の複製
    def -(other)
      list = SpriteList.new
      self.to_a.each{|pair| list.add(pair) unless other.has_key?(pair[0])}
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
        @names.delete(name) if @names.include?(name)
        @names << name
        @n2v[name] = ListPair.new(name, sprite)
      }
      return self
    end
    
    #===リストの終端から名前・スプライトの対を取り出す
    #リストに名前・スプライトをリストの終端から取り除いて、取り除いた対を返す
    #返却値:: 終端にあった名前に対応するListPair構造体
    def pop
      return nil if @names.empty?
      name = @names.pop
      @n2v.delete(name)
    end
    
    #===名前・スプライトを登録する
    #リストに名前・スプライトをリストの先頭に追加する
    #(先頭に追加することがSpriteList#<<,add,pushとの違い
    #_name_:: スプライト名
    #_sprite_:: スプライト本体
    #返却値:: 追加した自分自身を渡す
    def unshift(name, sprite)
      @names.delete(name) if @names.include?(name)
      @names.unshift(name)
      @n2v[name] = ListPair.new(name, sprite)
      return self
    end
    
    def slice(*names)
      list = self.to_a
      names.map{|name|
        next nil unless @names.include?(name)
        ListPair.new(name, @n2v[name])
      }
    end
    
    def slice!(*names)
      self.delete_if!{|name, sprite| !names.include?(name)}
    end
    
    def shift(n = nil)
      return nil if @names.empty?
      if n
        names = @names.shift(n)
        return names.map{|name| @n2v.delete(name)}
      else
        name = @names.shift
        return @n2v.delete(name)
      end
    end

    def delete(name)
      return nil unless @names.include?(name)
      @names.delete(name)
      @n2v.delete(name)
    end

    def delete_at(idx)
      self.delete(@names[idx])
    end

    def delete_if
      ret = self.deep_dup
      ret.each{|pair| ret.delete(pair[0]) if yield(*pair)}
      ret
    end

    def reject
      ret = self.deep_dup
      ret.each{|pair| ret.delete(pair[0]) if yield(*pair)}
      ret
    end

    def delete_if!
      self.each{|pair| self.delete(pair[0]) if yield(*pair)}
      self
    end

    def reject!
      self.each{|pair| self.delete(pair[0]) if yield(*pair)}
      self
    end
    
    def compact
      ret.delete_if{|pair| pair[1].nil?}
    end

    def compact!
      ret.delete_if!{|pair| pair[1].nil?}
    end

    def concat(other)
      other.to_a.each{|pair| self.add(pair)}
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
      @names.shuffle
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
    #自分自身を配列化(to_ary)し、サイズnの組み合わせをすべて求めて配列にまとめる
    #_n_:: 組み合わせのサイズ
    #返却値:: すべてのListPairの順列を配列化したもの
    def combination(n, &block)
      self.to_a.combination(n, &block)
    end

    #===自身での順列を配列として返す
    #自分自身を配列化(to_ary)し、サイズnの順列をすべて求めて配列にまとめる
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
    #返却値:: すべてのListPairの組み合わせを配列化したもの
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
      other.to_a.each{|pair| self.add(*pair)}
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
      @names.reverse!
      return self
    end
    
    #===名前と関連付けられたスプライトを取得する
    #関連付けられているスプライトが見つからなければnilが返る
    #例:SpriteList(pair(:a),pair(:b),pair(:c),pair(:d))[:c]
    #   => spr(:c)
    #_name_:: 名前
    #返却値:: 名前に関連付けられたスプライト
    def [](name)
      return @n2v[name].body
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
      return self.push(name, sprite) unless @names.include?(name)
      @n2v[name] = ListPair.new(name, sprite)
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
      ret = SpriteList.new
      names.each{|name| ret[name] = @n2v[name]}
      ret
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
      names.map{|name| @n2v[name].body }
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
      @names.map{|name| @n2v[name]}
    end
    
    #===スプライト名とスプライト本体とのハッシュを取得する
    #スプライト名とスプライト本体が対になったハッシュを作成して返す
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).to_hash
    #   => {:a=>spr(:a),:b=>spr(:b),:c=>spr(:c)}
    #返却値:: 生成したハッシュ
    def to_hash
      @n2v.dup
    end
    
    #===リストの中身を消去する
    #リストに登録されているスプライト名・スプライト本体への登録を解除する
    def clear
      @names.clear
      @n2v.clear
    end
    
    #===オブジェクトを解放する
    def dispose
      @names.clear
      @names = nil
      @n2v.clear
      @n2v = nil
    end
    
    #===名前に対して値を渡す
    #仕様はHash#fetchと同じ
    def fetch(name, default = nil, &block)
      @n2v.fetch(name, default, &block)
    end
    
    #===指定の名前の直前に名前を挿入する
    #配列上で、スプライト名配列の指定の名前の前になるように名前を挿入する
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).insert(:b, :d, spr(:d))
    #   => SpriteList(pair(:a),pair(:d),pair(:b),pair(:c))
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).insert(:c, :a)
    #   => SpriteList(pair(:c),pair(:a),pair(:b))
    #_key_:: 挿入先の名前。この名前の直前に挿入する
    #_name_:: 挿入するスプライトの名前
    #_value_:: (名前が未登録の時の)スプライト本体省略時はnil
    #返却値：自分自身を返す
    def insert(key, name, value = nil)
      raise MiyakoValueError, "Illegal key! : #{key}" unless @names.include?(key)
      return self if key == name
      if value
        @n2v[name] = ListPair.new(name, value) 
      else
        raise MiyakoValueError, "name is not regist! : #{name}" unless @names.include?(name)
      end
      @names.delete(name) if @names.include?(name)
      @names.insert(@names.index(key), name)
      self
    end
    
    #===指定の名前の直後に名前を挿入する
    #配列上で、スプライト名配列の指定の名前の次の名前になるように名前を挿入する
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).insert_after(:b, :d, spr(:d))
    #   => SpriteList(pair(:a),pair(:b),,pair(:d)pair(:c))
    #例:SpriteList(pair(:a),pair(:b),pair(:c)).insert_after(:c, :b)
    #   => SpriteList(pair(:a),pair(:c),pair(:b))
    #_key_:: 挿入先の名前。この名前の直後に挿入する
    #_name_:: 挿入するスプライトの名前
    #_value_:: (名前が未登録の時の)スプライト本体省略時はnil
    #返却値：自分自身を返す
    def insert_after(key, name, value = nil)
      raise MiyakoValueError, "Illegal key! : #{key}" unless @names.include?(key)
      return self if key == name
      if value
        @n2v[name] = ListPair.new(name, value) 
      else
        raise MiyakoValueError, "name is not regist! : #{name}" unless @names.include?(name)
      end
      @names.delete(name) if @names.include?(name)
      @names.insert(@parts_list.index(key)-@parts_list.length, name)
      self
    end
    
    #===指定した要素の内容を入れ替える
    #例:SpriteList(pair(:a),pair(:b),pair(:c),pair(:d)).insert(:b, :d)
    #   => SpriteList(pair(:a),pair(:d),pair(:c),pair(:b))
    #_name1,name_:: 入れ替え対象の名前
    #返却値:: 自分自身を帰す
    def swap(name1, name2)
      raise MiyakoValueError, "Illegal name! : idx1:#{name1}" unless @names.include?(name1)
      raise MiyakoValueError, "Illegal name! : idx2:#{name2}" unless @names.include?(name2)
      idx1 = @names.index(name1)
      idx2 = @names.index(name2)
      @names[idx1], @names[idx2] = @names[idx2], @names[idx1]
      return self
    end
    
    #===描く画像のアニメーションを開始する
    #各要素のstartメソッドを呼び出す
    #返却値:: 自分自身を返す
    def start
      self.sprite_only.each{|pair| pair[1].start }
      return self
    end
    
    #===描く画像のアニメーションを停止する
    #各要素のstopメソッドを呼び出す
    #返却値:: 自分自身を返す
    def stop
      self.sprite_only.each{|pair| pair[1].stop }
      return self
    end
    
    #===描く画像のアニメーションを先頭パターンに戻す
    #各要素のresetメソッドを呼び出す
    #返却値:: 自分自身を返す
    def reset
      self.sprite_only.each{|pair| pair[1].reset }
      return self
    end
    
    #===描く画像のアニメーションを更新する
    #各要素のupdate_animationメソッドを呼び出す
    #返却値:: 描く画像のupdate_spriteメソッドを呼び出した結果を配列で返す
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
