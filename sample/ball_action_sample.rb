# encoding: utf-8
# 自由落下運動サンプル
# 2009 Cyross Makoto

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
    @sprite.move(@layout.pos[0]-@position[0],
                 @layout.pos[1]-@position[1])
    @position.move_to(*@layout.pos.to_a)
  end
  
  # スプライトとコリジョン間でマージンを設定
  def margin(dx, dy)
    @sprite.move(dx, dy)
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
  FIRST_SPEED = [8.0, 12.0, 16.0, 24.0].cycle
  X_SPEED = [1, -1].cycle
  G = 9.8

  # 初速度の取得
  attr_reader :first_speed
  
  def initialize
    size = Size.new(32, 32)
    super(size)
    Drawing.circle(@sprite,
                   [size.w/2,size.h/2],
                   size.w/2,
                   [255,255,255],
                   true)

    # 床の跳ね返り係数
    @e = 0.9
    # ジャンプ中？
    @jumping = false
    # x方向移動量
    @dx  = 0
    # 初速度
    @first_speed = 0.0
    # カウント
    @count = 0.0
    # カウント刻み
    @dcount = 0.2
    # ウェイト
    @wait  = WaitCounter.new(0.01)
  end

  # ボールの更新
  # 床(floor)を引数に取る
  def update(floor)
    if @jumping
      # 放物運動の式。間違えてないよね？
      d = -(@first_speed * @count - (G * (@count ** 2)) / 2).to_i
      # 床とぶつかる？
      # 移動範囲を作成
      rect = Rect.new(@position.x,
                      @position.y,
                      1, d)
      # 所定の間隔で床と衝突判定
      if Utility.product_liner(rect, floor.h).any?{|pos|
        @collision.collision?(pos,
                              floor.collision,
                              floor.position)
      }
        # 床までの距離を求める
        d = floor.y - self.h - self.y
        # 床にぶつかれば跳ね返る
        self.move(@dx, d)
        @first_speed = @first_speed < d ? @first_speed * @e : d.to_f * @e
        @first_speed = 0 if @first_speed < 0.0
        @count = 0.0
        @wait.start
      elsif @wait.finish?
        # ぶつからなければ移動
        self.move(@dx, d)
        @count = @count + @dcount
        @wait.start
      end
      # 初速度がゼロ？（止まった？）
      if @first_speed == 0.0
        # ジャンプの終了
        @wait.stop
        @jumping = false
      end
    end
  end

  # 飛び上がれ！
  def jumpup
    return if @jumping
    # x方向移動量
    @dx = X_SPEED.next
    # 初速度の決定
    @first_speed = FIRST_SPEED.next
    @jumping = true
    @count = 0
    @wait.start
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
@floor.center.bottom

# ボールの初期位置設定
@ball.center.bottom{|b| @floor.size.h }

# フォントの用意
@font = Font.serif
@font.size = 16
@speed = Sprite.new(size: Size.new(640, 16), type: :ac)

Miyako.main_loop do
  break if Input.quit_or_escape?
  @ball.update(@floor)
  # １ボタンを押した時、ボールのジャンプを始める
  @ball.jumpup if Input.pushed_any?(:btn1)

  # 初速度表示スプライトの更新
  @speed.clear!
  @font.draw_text(@speed, "初速度：#{@ball.first_speed}", 0, 0)

  # 画面への描画
  @floor.render
  @ball.render
  @speed.render
end
