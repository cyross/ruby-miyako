# -*- encoding: utf-8 -*-
#キャラクタ管理クラス
class PChara # Player Character
  extend Forwardable
  attr_accessor :dir
  @@amt2dir = {[0,1]=>0,[-1,0]=>1,[1,0]=>2,[0,-1]=>3}
  @@amt2dir.default = -1

  def initialize(fname, size, pw = 0.2)
    @size = size
    # キャラクタスプライトを作成
    # コリジョンはスプライトのものを共有して使用
    @spr = Sprite.new({:filename => fname, :type => :color_key})
    raise MiyakoError, "Character Size is not aligned by Map Chip Size!" unless (@spr.w % @size[0] == 0 && @spr.h % @size[1] == 0)
    @spr.ow = @size[0]
    @spr.oh = @size[1]
    param = Hash.new
    param[:sprite] = @spr
    param[:wait] = pw
    # キャラパターンを表示
    @anim = SpriteAnimation.new(param)
    @anim.centering
  end

  # マップの表示座標と実座標とのマージンを設定
  def margin
    return Size.new(-@spr.x, -@spr.y)
  end

  def turn(d)
    @anim.character = @@amt2dir[d]
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
  
  def_delegators(:@spr, :dispose, :rect, :ow, :oh, :x, :y)
end
