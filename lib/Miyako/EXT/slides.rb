# Miyako Extension
=begin
Miyako Extention Library v1.5
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
      return Parts.new(Sprite.new(tmp).fill(tmp[:color])).main_bottom
    end
    
    @@templates["320x240"] = {:size=>Size.new(320,240)}
    @@templates["640x480"] = {}
    @@templates["800x600"] = {:size=>Size.new(800,600)}
    @@templates["gray"]    = {:color=>[128,128,128,255]}

    def Slide.[](sym = "640x480")
      return Slide.create(@@templates[sym])
    end
    
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
      @body.main_bottom
      return self
    end

    #===@bodyに登録したオブジェクトとは別に作成していたインスタンスを解放する
    def dispose
    end
    
    def_delegators(:@body,
                   :main_top, :main_bottom,
                   :max_dp, :min_dp, :sort_dp,
                   :remove, :each,
                   :show, :hide, :start, :stop, :reset,
                   :viewport, :viewport=)
  end
end
