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
          @n2v[pair[0]] = pair[1]
        }
      elsif pairs.is_a?(Hash)
        pairs.each{|key, value|
          @names << key
          @n2v[key] = value
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
      obj.names.each{|name|
        self.push(name, obj[name].deep_dup)
      }
      @visible = obj.visible
    end
    
    #==nilやスプライト以外のインスタンスを削除したSpriteListを生成する
    #新しいSpriteListを作成し、本体がnilや、SpriteBaseもしくはSpritArrayモジュールをmixinしていない対を削除する。
    #返却値:: 新しく生成したインスタンス
    def sprite_only
      ret = self.dup
      ret.names.each{|name|
        ret.delete(name) if !ret[name].class.include?(SpriteBase) && !ret[name].class.include?(SpriteArray)
      }
      return ret
    end

    #==nilやスプライト以外のインスタンスを破壊的に削除する
    #自分自身から、本体がnilや、SpriteBaseもしくはSpritArrayモジュールをmixinしていない対を削除する。
    #返却値:: 自分自身を帰す
    def sprite_only!
      @names.each{|name|
        if !@n2v[name].class.include?(SpriteBase) && !ret[name].class.include?(SpriteArray)
          @n2v.delete(name)
          @names.delete(name)
        end
      }
      return self
    end

    #==ブロックを受け取り、リストの各要素にたいして処理を行う
    #ブロック引数には、|[スプライト名,スプライト本体]|が渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each
      self.to_a.each{|pair| yield pair}
    end
    
    #==ブロックを受け取り、スプライト名リストの各要素にたいして処理を行う
    #ブロック引数には、|スプライト名,スプライト本体|が渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_pair
      @names.each{|name| yield name, @n2v[name]}
    end
    
    #==ブロックを受け取り、名前リストの各要素にたいして処理を行う
    #ブロック引数には、|スプライト名|が渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_name
      @names.each{|name| yield name}
    end
    
    #==ブロックを受け取り、値リストの各要素にたいして処理を行う
    #ブロック引数には、|スプライト本体|の配列として渡ってくる
    #名前が登録されている順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_value
      @names.each{|name| yield @n2v[name]}
    end
    
    #==ブロックを受け取り、配列インデックスにたいして処理を行う
    #ブロック引数には、|スプライト名に対応する配列インデックス|の配列として渡ってくる
    #0,1,2,...の順に渡ってくる
    #返却値:: 自分自身を帰す
    def each_index
      @names.length.times{|idx| yield idx}
    end
    
    #==スプライト名配列を取得する
    #名前が登録されている順に渡ってくる
    #返却値:: スプライト名配列
    def names
      @names
    end
    
    #==スプライト配列を取得する
    #名前が登録されている順に渡ってくる
    #返却値:: スプライト本体配列
    def values
      @names.map{|name| @n2v[name]}
    end
    
    #==リストが空っぽかどうか確かめる
    #リストに何も登録されていないかどうか確かめる
    #返却値:: 空っぽの時はtrue、なにか登録されているときはfalse
    def empty?
      @names.empty?
    end

    def eql?(other)
      @names.eql?(other.names) && @n2v.values.eql?(other.values)
    end
    
    def has_name?(name)
      @n2v.has_key?(name)
    end
    
    def include?(name)
      @names.has_key?(name)
    end
    
    def has_value?(value)
      @n2v.has_value?(value)
    end

    def length
      @names.length
    end

    def size
      @names.size
    end

    def assoc(name)
      @n2v.assoc(name)
    end
    
    def rassoc(val)
      @n2v.rassoc(name)
    end
    
    def name(value)
      @n2v.key(value)
    end
    
    def index(name)
      @names.index(name)
    end
    
    def first(n=1)
      @names.length < n ? nil : @names.first(n).map{|name| [name, @n2v[name]]}
    end
    
    def last(n=1)
      @names.length < n ? nil : @names.last(n).map{|name| [name, @n2v[name]]}
    end
    
    def <<(pair)
      self.push(*pair)
    end
    
    def +(other)
      list = self.dup
      other.to_a.each{|pair| list.add(pair)}
      list
    end
    
    def *(other)
      list = SpriteList.new
      self.to_a.each{|pair| list.add(pair) if other.has_key?(pair[0])}
      list
    end
    
    def -(other)
      list = SpriteList.new
      self.to_a.each{|pair| list.add(pair) unless other.has_key?(pair[0])}
      list
    end
    
    def &(other)
      self * other
    end
    
    def |(other)
      self + other
    end
    
    def ==(other)
      self.eql?(other)
    end

    def add(pair)
      self.push(*pair)
    end
    
    def push(name, sprite)
      @names.delete(name) if @names.include?(name)
      @names << name
      @n2v[name] = sprite
      return self
    end

    def pop
      return nil if @names.empty?
      name = @names.pop
      [name, @n2v.delete(name)]
    end
    
    def unshift(name, sprite)
      @names.delete(name) if @names.include?(name)
      @names.unshift(name)
      @n2v[name] = sprite
      return self
    end
    
    def slice(*names)
      list = self.to_a
      names.map{|name| [name, @n2v[name]]}
    end
    
    def slice!(*names)
      self.delete_if!{|name, sprite| !names.include?(name)}
    end
    
    def shift(n = nil)
      return nil if @names.empty?
      if n
        names = @names.shift(n)
        return names.map{|name| [name, @n2v.delete(name)]}
      else
        name = @names.shift
        return [name, @n2v.delete(name)]
      end
    end

    def delete(name)
      return nil unless @names.include?(name)
      [@names.delete(name), @n2v.delete(name)]
    end

    def delete_at(idx)
      self.delete(@names[idx])
    end

    def delete_if
      ret = self.dup
      ret.each{|pair| ret.delete(pair[0]) if yield(*pair)}
      ret
    end

    def reject
      ret = self.dup
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
    
    def merge(other)
      ret = other.dup + self
      ret.names.each{|name| yield name, self[name], other[name] } if block_given?
      ret
    end
    
    def merge!(other)
      self.replace(other+self)
      self.names.each{|name| yield name, self[name], other[name] } if block_given?
      self
    end
    
    def cycle(&block)
      self.to_a.cycle(&block)
    end

    def shuffle
      self.to_a.shuffle
    end

    def sample(n=nil)
      n ? self.to_a.sample(n) : self.to_a.sample
    end

    def combination(n)
      self.to_a.combination(n)
    end

    def permutation(n, &block)
      self.to_a.permutation(n, &block)
    end
    
    private :reflesh
    
    def replace(other)
      self.clear
      other.to_a.each{|pair| self.add(*pair)}
      self
    end

    #===名前の順番を反転する
    #名前の順番を反転した、自分自身のコピーを生成する
    #返却値:: 名前を反転させた自分自身の複製を返す
    def reverse
      ret = self.dup
      ret.reverse!
      return ret
    end
    
    #===名前の順番を破壊的に反転する
    #返却値:: 自分自身を帰す
    def reverse!
      @names.reverse!
      return self
    end
    
    def [](name)
      return @n2v[name]
    end

    def []=(name, sprite)
      return self.push(name, sprite) unless @names.include?(name)
      @n2v[name] = sprite
      return self
    end
    
    def sort(&block)
      @n2v.sort(&block)
    end
    
    def pairs_at(*names)
      names.map{|name| [name, @n2v[name]]}
    end
    
    def values_at(*names)
      names.map{|name| @n2v[name]}
    end
    
    def zip(*lists, &block)
      lists = lists.map{|list| list.to_a}
      self.to_a.zip(*lists, &block)
    end

    #===リストを配列化する
    #インスタンスの内容を元に、配列を生成する。
    #各要素は、[スプライト名,スプライト本体]という構成。
    #返却値:: 生成したハッシュ
    def to_a
      @names.map{|name| [name, @n2v[name]]}
    end
    
    #===スプライト名とスプライト本体とのハッシュを取得する
    #スプライト名とスプライト本体が対になったハッシュを作成して返す
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
    #_key_:: 挿入先の名前。この名前の直前に挿入する
    #_name_:: 挿入するスプライトの名前
    #_value_:: (名前が未登録の時の)スプライト本体省略時はnil
    #返却値：自分自身を返す
    def insert(key, name, value = nil)
      raise MiyakoValueError, "Illegal key! : #{key}" unless @names.include?(key)
      return self if key == name
      if value
        @n2v[name] = value 
      else
        raise MiyakoValueError, "name is not regist! : #{name}" unless @names.include?(name)
      end
      @names.delete(name) if @names.include?(name)
      @names.insert(@names.index(key), name)
      self
    end
    
    #===指定の名前の直後に名前を挿入する
    #配列上で、スプライト名配列の指定の名前の次の名前になるように名前を挿入する
    #_key_:: 挿入先の名前。この名前の直後に挿入する
    #_name_:: 挿入するスプライトの名前
    #_value_:: (名前が未登録の時の)スプライト本体省略時はnil
    #返却値：自分自身を返す
    def insert_after(key, name, value = nil)
      raise MiyakoValueError, "Illegal key! : #{key}" unless @names.include?(key)
      return self if key == name
      if value
        @n2v[name] = value 
      else
        raise MiyakoValueError, "name is not regist! : #{name}" unless @names.include?(name)
      end
      @names.delete(name) if @names.include?(name)
      @names.insert(@parts_list.index(key)-@parts_list.length, name)
      self
    end
    
    #===指定した要素の内容を入れ替える
    #配列の先頭から順にrenderメソッドを呼び出す。
    #描画するインスタンスは、引数がゼロのrenderメソッドを持っているもののみ(持っていないときは呼び出さない)
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
      self.sprite_only.map{|pair|
        pair[1].update_animation
      }
    end
    
    #===配列の要素を画面に描画する
    #配列の先頭から順にrenderメソッドを呼び出す。
    #描画するインスタンスは、引数がゼロのrenderメソッドを持っているもののみ(持っていないときは呼び出さない)
    #返却値:: 自分自身を帰す
    def render
      return self unless @visible
      @names.each{|e|
        v = @n2v[e]
        next unless v.class.method_defined?(:render)
        v.render if (-1..0).include?(v.method(:render).arity)
      }
      return self
    end
    
    #===配列の要素を対象の画像に描画する
    #配列の先頭から順にrender_toメソッドを呼び出す。
    #描画するインスタンスは、引数が１個のrender_toメソッドを持っているもののみ(持っていないときは呼び出さない)
    #_dst_:: 描画対象の画像インスタンス
    #返却値:: 自分自身を帰す
    def render_to(dst)
      return self unless @visible
      @names.each{|e|
        v = @n2v[e]
        next unless v.class.method_defined?(:render_to)
        v.render_to(dst) if [-2,-1,1].include?(v.method(:render_to).arity)
      }
      return self
    end
    
    #===オブジェクトを文字列に変換する
    #いったん、名前とスプライトとの対の配列に変換し、to_sメソッドで文字列化する。
    #(例)[[name1, sprite1], [name2, sprite2],...]
    #返却値:: 変換した文字列
    def to_s
      self.to_a.to_s
    end
  end
end
