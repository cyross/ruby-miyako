#encoding: utf-8
# Drawerクラス
# 図形描画をスプライトとして扱うクラス
# 2010.05.01 Cyross Makoto

module Miyako
  # SpriteBase, Animation, Layoutモジュールのメソッドが利用可能
  class Drawer
    include SpriteBase
    include Animation
    include Layout

    attr_accessor :method, :color
    attr_accessor :r, :rx, :ry, :aa, :fill
    attr_accessor :visible
    attr_accessor :base, :point, :rect, :points

    # 図形描画オブジェクトを作る
    # 引数はハッシュ引数
    # それぞれのキーは、Drawerクラスオブジェクトのメソッドとしてアクセス可能
    # :method => メソッドを指定(:fill,:pset,:line,:rect,:circle,:ellipse,:polygon) 省略不可
    # :base => 描画先スプライト 全メソッドで有効 省略時はScreen(画面)
    # :color => 描画色 全メソッドで有効 省略時は白色([255,255,255,255])
    # :point => 描画開始座標/円の中心座標(Point構造体) :pset, :circle, :ellipseのみ有効 省略時はPoint(0,0)
    # :rect => 描画矩形(Rect構造体) :line,:rectのみ有効 省略時はRect(0,0,1,1)
    # :points => 座標の配列([Point構造体,Point構造体,...]) :polygonのみ有効 省略時は空の配列
    # :r => 円の半径(数値) :circleのみ有効 省略時は1
    # :rx => 楕円の横方向半径 :ellipseのみ有効 省略時は1
    # :ry => 楕円の縦方向半径 :ellipseのみ有効 省略時は1
    # :aa => アンチエイリアスを付けるかどうか(true/false) :line, :cirle, :ellipse, :polygonのみ有効 省略時はfalse
    # :fill => 描画色で図形の中を塗りつぶすかどうか(true/false) :rect, :circle, :ellipse, :polygonのみ有効 省略時はfalse
    def initialize(hash)
      init_layout
      set_layout_size(1,1)
      @method = hash[:method]
      @base   = hash[:base] || Screen
      @color  = hash[:color] || [255,255,255]
      @point  = hash[:point] ? Point.new(*(hash[:point].to_a)) : Point.new(0,0)
      @rect  = hash[:rect] ? Rect.new(*(hash[:rect].to_a)) : Rect.new(0,0,1,1)
      @points = hash[:points] ? hash[:points].map{|pos| Point.new(*pos.to_a)} : []
      @r = hash[:r] || 1
      @rx = hash[:rx] || 1
      @ry = hash[:ry] || 1
      @aa = hash[:aa] || false
      @fill = hash[:fill] || false
      @visible = true
      @off = Point.new(0,0)
      raise MiyakoError, "set correct method name by symbol!" unless @method
    end

    def render
      return self unless @visible
      @off.move_to!(0,0)
      __send__(@method)
    end

    def render_xy(x, y)
      return self unless @visible
      @off.move_to!(x,y)
      __send__(@method)
    end

    def fill
      Drawing.fill(@base,
                   @color)
    end

    def pset
      Drawing.pser(@base,
                   @point.move(*@layout.pos).move!(*@off),
                   @color)
    end

    def line
      Drawing.line(@base,
                   @rect.move(*@layout.pos).move!(*@off),
                   @color,
                   @aa)
    end

    def rect
      Drawing.rect(@base,
                   @rect.move(*@layout.pos).move!(*@off),
                   @color,
                   @fill)
    end

    def circle
      Drawing.circle(@base,
                     @point.move(*@layout.pos).move!(*@off),
                     @r,
                     @color,
                     @fill,
                     @aa)
    end

    def ellipse
      Drawing.ellipse(@base,
                      @point.move(*@layout.pos).move!(*@off),
                      @rx,
                      @ry,
                      @color,
                      @fill,
                      @aa)
    end

    def polygon
      Drawing.polygon(@base,
                      @points.map{|pos| pos.move(*@layout.pos).move!(*@off)},
                      @color,
                      @fill,
                      @aa)
    end

    private :fill, :pset, :line, :rect, :circle, :ellipse, :polygon
  end
end
