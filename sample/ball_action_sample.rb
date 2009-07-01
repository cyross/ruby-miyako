# encoding: utf-8
# 自由落下運動サンプル
# 2009.4.19 Cyross Makoto

require 'Miyako/miyako'

include Miyako

# 基本オブジェクト
class Obj
  include Layout

  attr_reader :collision, :position

  def initialize(size)
    init_layout
    set_layout_size(*size.to_a)
  
    # スプライトの生成
    @sprite = Sprite.new(size: size, type: :ac)
    
    # コリジョンの生成
    @collision = Collision.new(Rect.new(0, 0, *size.to_a))
    
    # 位置情報の生成
    @position = Point.new(0, 0)
  end

  def update_layout_position
    # 画像はマージンが掛かっている可能性があるため、
    # 補正を掛けておく
    pos = @layout.pos.move(-@position[0],-@position[1])
    @sprite.move!(*pos)
    @position.move_to!(*@layout.pos)
  end
  
  # スプライトとコリジョン間でマージンを設定
  def margin(dx, dy)
    @sprite.move!(dx, dy)
    return self
  end

  # 衝突判定
  def collision?(col, pos)
    return @collision.collision?(@position, col, pos)
  end

  # 画面へ描画
  def render
    @sprite.render
  end
end

# ボール
class Ball < Obj
  V0 = [8.0, 12.0].cycle
  VX = [1, -1].cycle
  G = 9.8

  # 初速度の取得
  attr_reader :v0
  
  def initialize
    size = Size.new(32, 32)
    super(size)
    Drawing.circle(@sprite,
                   [size.w/2,size.h/2],
                   size.w/2,
                   [255,255,255],
                   true)

    # ジャンプ中？
    @jumping = false
    # y基準位置
    @by  = 0.0
    # 元y
    @oy  = 0.0
    # 速度
    @v = 0.0
    # 初速度
    @v0 = 0.0
    # 時間
    @t = 0.0
    # 時間刻み
    @dt = 0.01
    # 床の跳ね返り係数
    # 0.9や0.8にすると永遠に跳ねる
    @e = 0.5
    # 拡大率
    @zoom = 1.0 / @dt
    # ウェイト
    @wait  = WaitCounter.new(@dt)
  end

  # ボールの更新
  # 床(floor)を引数に取る
  def update(floor)
    if @jumping
      # 放物運動の公式より。
      # 当たり判定のテストも兼ねていることから、
      # 整数単位の値が必要だったため、時間刻みを元に値を拡大している
      y = (@v0 * @t - G * (@t ** 2) / 2) * @zoom
      # 移動量の算出
      dy = y - @oy
      # 床とぶつかる？
      # 移動範囲を作成
      rect = Rect.new(@position.x,
                      @position.y,
                      1, -dy)
      # 所定の間隔で床と衝突判定
      if Utility.product_liner_f(rect, floor.h).any?{|pos|
        @collision.collision?(pos,
                              floor.collision,
                              floor.position)
      }
        # 床にぶつかれば跳ね返る
        self.move_to!(self.x, @by)
        # 跳ね返り時の速度を求める。
        # 実数にすると何故か永遠にはねるため、整数化して強制的に値を少なくしている
        @v0 = -((@v0 - G * @t) * @e).to_i
        @t = @dt
        @oy = 0.0
        @wait.start
      elsif @wait.finish?
        # ぶつからなければ移動
        self.move_to!(self.x, @by - y.to_i)
        @t = @t + @dt
        @oy = y
        @wait.start
      end
      # 初速度がゼロ？（止まった？）
      if @v0 == 0.0
        # ジャンプの終了
        @wait.stop
        @jumping = false
      end
    end
  end

  # 飛び上がれ！
  def jumpup
    return if @jumping
    # y基準位置の決定
    @by  = self.y.to_f
    # 初速度の決定
    @v0 = V0.next
    @jumping = true
    @t = @dt
    @wait.start
  end

  # ジャンプ中？
  def jumping?
    return @jumping
  end
end

# 床
class Floor < Obj
  def initialize
    size = Size.new(640, 16)
    super(size)
    Drawing.fill(@sprite, [255,64,64])
  end
end

# ボールの用意
@ball = Ball.new

# 床の用意
@floor = Floor.new

# 床の初期位置設定
@floor.center!.bottom!

# ボールの初期位置設定
@ball.center!.bottom!{|b| @floor.size.h }

# フォントの用意
@font = Font.serif
@font.size = 16

# 情報表示用スプライトの用意
@speed = Sprite.new(size: Size.new(640, 16), type: :ac)
@info = Shape.text(font: @font, text: "１ボタンを押せばボールが跳ね上がります")
@info.snap(@speed).left!.outside_bottom!

Miyako.main_loop do
  break if Input.quit_or_escape?
  @ball.update(@floor)
  # １ボタンを押した時、ボールのジャンプを始める
  @ball.jumpup if Input.pushed_any?(:btn1)

  # 初速度表示スプライトの更新
  @speed.clear!
  @font.draw_text(@speed, "初速度：#{@ball.v0}", 0, 0)

  # 画面への描画
  @floor.render
  @ball.render
  @speed.render
  # ジャンプ中でなければ説明を表示
  @info.render unless @ball.jumping?
end
