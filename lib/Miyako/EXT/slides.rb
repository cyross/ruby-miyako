# -*- encoding: utf-8 -*-
# Miyako Extension
=begin
Miyako Extention Library v2.0
Copyright (C) 2007-2008  Cyross Makoto

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
=end

module Miyako
  #==スライドを構成するモジュール
  #Mixinして使用する
  #使用するには、initializeメソッドの定義内で、init_slideメソッドを呼び出す必要がある
  #ただし、インスタンス変数として、@bodyを予約済み
  module Slide
    include Layout
    extend Forwardable

    @@templates = { }

    #===スライドを作成する
    #スライド本体は、Partsクラスのインスタンス
    #_params_:: あとで書く
    def Slide.create(params = {})
      tmp = params.dup
      tmp[:size]  ||= Size.new(640, 480)
      tmp[:type]  ||= :ac
      tmp[:color] ||= Color[:white]
      return Parts.new(tmp[:size]).tap{|obj| obj[:___base___] = Sprite.new(tmp).fill(tmp[:color])}
    end
    
    @@templates["320x240"]    = {:size=>Size.new(320,240)}
    @@templates["640x480"]    = {}
    @@templates["800x600"]    = {:size=>Size.new(800,600)}
    @@templates["white"]      = {:color=>[255,255,255,255]}
    @@templates["gray"]       = {:color=>[128,128,128,255]}
    @@templates["black"]      = {:color=>[0,0,0,255]}
    @@templates["half-white"] = {:color=>[255,255,255,128]}

    #===スライドをテンプレート文字列から作成する
    #スライドを所定の名称で生成する。利用できるのは以下の7種類
    #"320x240"    大きさは320x240ピクセル、背景は白色
    #"640x480"    大きさは640x480ピクセル、背景は白色(デフォルトのテンプレート)
    #"800x600"    大きさは800x600ピクセル、背景は白色
    #"white"      "640x480"と同一
    #"gray"       大きさは640x480ピクセル、背景は灰色([128,128,128,255])
    #"black"      大きさは640x480ピクセル、背景は黒色([0,0,0,255])
    #"half-white" 背景が半分透明な"white"([255,255,255,128])
    #_sym_:: テンプレートに対応した文字列
    #返却値:: 生成したスライド(Partsクラスインスタンス)
    def Slide.[](sym = "640x480")
      return Slide.create(@@templates[sym])
    end
    
    #===スライドのテンプレートを追加する
    #指定できるテンプレートの内容は、Sprite.newメソッドの引数がそのまま使える(Hashクラスインスタンスとして渡す)
    #また、追加として、:colorパラメータを使って塗りつぶす色を指定することが出来る。
    #(例):color=>Color[:red]
    #_sym_:: テンプレート名
    #_params_:: 生成時のパラメータ
    def Slide.[]=(sym, params)
      @@templates[sym] = params
    end

    #===スライド情報を初期化する
    #(例)init_slide(Slide.create(:size=>Size.new(320,240), :color=>[255,0,0]))
    #(例)init_slide(Slide["640x480"]))
    #_template_:: 元となるPartsクラスインスタンス(Slide.createメソッドで作成もしくはSlide.[]で取得できるテンプレートスライド)
    def init_slide(template)
      init_layout
      @body = template
      set_layout_size(*(@body.size))
      @body.snap(self)
    end
    
    def piece
      return self
    end
    
    private :piece
    
    #===名前に対応したパーツを取得する
    #_title_:: 取得したいパーツに対応したシンボル
    #返却値:: シンボルに対応したパーツ
    def [](title)
      return @body[title]
    end

    #===パーツに名前を割り付けて設定する
    #_title_:: 取得したいパーツに対応したシンボル
    #_objs_:: (1)シンボルに対応させるパーツ(スライドにスナップする)
    #(2)パーツと、スナップさせるパーツの名前(シンボル)
    #返却値:: 自分自身を返す
    def []=(title, objs)
      @body[title] = objs
      return self
    end

    #===スライドを画面に描画する
    #単純にslide_renderメソッドを呼び出し、結果を返すだけのテンプレートメソッド
    #このメソッドを記述し直すことにより、柔軟なrenderを行える
    #ブロックを渡すと、スライド,画面側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る。
    #ブロックの引数は、|スライド側SpriteUnit,画面側SpriteUnit|となる。
    #返却値:: 自分自身を返す
    def render(&block)
      return slide_render(&block)
    end

    #===スライドを画像に描画する
    #単純にslide_render_toメソッドを呼び出し、結果を返すだけのテンプレートメソッド
    #このメソッドを記述し直すことにより、柔軟なrenderを行える
    #ブロックを渡すと、スライド,画像側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る。
    #ブロックの引数は、|スライド側SpriteUnit,画像側SpriteUnit|となる。
    #_dst_:: 描画先画像(Spriteクラスインスタンスなど)
    #返却値:: 自分自身を返す
    def render_to(dst, &block)
      return slide_render_to(dst, &block)
    end

    #===スライドを画面に描画する
    #ブロックを渡すと、スライド,画面側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る。
    #ブロックの引数は、|スライド側SpriteUnit,画面側SpriteUnit|となる。
    #返却値:: 自分自身を返す
    def slide_render(&block)
      @body.render(&block)
      return self
    end

    #===スライドを画像に描画する
    #ブロックを渡すと、スライド,画像側のSpriteUnitを更新して、それを実際の転送に反映させることが出来る。
    #ブロックの引数は、|スライド側SpriteUnit,画像側SpriteUnit|となる。
    #_dst_:: 描画先画像(Spriteクラスインスタンスなど)
    #返却値:: 自分自身を返す
    def slide_render_to(dst, &block)
      @body.render(dst, &block)
      return self
    end

    #===@bodyに登録したオブジェクトとは別に作成していたインスタンスを解放する
    def dispose
    end
    
    def_delegators(:@body, :remove, :each, :start, :stop, :reset, :update, :update_animation)
  end
end
