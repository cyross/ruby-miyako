# -*- encoding: utf-8 -*-
#キャラクタ管理クラス
class PChara # Player Character
  extend Forwardable
  attr_accessor :dir
  attr_reader :collision, :position
  @@dir2dir = {[0,1]=>0,[-1,0]=>1,[1,0]=>2,[0,-1]=>3}
  @@dir2dir.default = -1

  def initialize(fname, pw = 0.2)
    # キャラクタスプライトを作成
    @spr = Sprite.new({:filename => fname, :type => :color_key})
    @spr.ow = 32
    @spr.oh = 32
    param = Hash.new
    param[:sprite] = @spr
    param[:wait] = pw
    # コリジョン設定
    @collision = Collision.new(@spr.rect)
    # キャラクタ位置設定
    @position = Point.new(0, 0)
    # キャラパターンを表示
    @anim = SpriteAnimation.new(param)
    @anim.centering
    @dir = :down
  end

  # マップの表示座標と実座標とのマージンを設定
  def margin
    return Size.new(-@spr.x, -@spr.y)
  end

  def turn(d)
    @anim.character = @@dir2dir[d]
  end

  def start
    @anim.start
  end
  
  def stop
    @anim.stop
  end

  def update
    @anim.update_animation
  end
  
  def render
    @anim.render
  end
  
  def size
    return Size.new(@spr.ow, @spr.oh)
  end
  
  def_delegators(:@spr, :dispose, :rect, :ow, :oh, :x, :y)
end
