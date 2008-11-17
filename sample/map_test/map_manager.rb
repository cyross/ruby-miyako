#マップ管理クラス
class MapManager
  extend Forwardable

  attr_reader :collision
  
  def initialize
    @moving = false

    #マップチップインスタンスの作成
    @mp = MapChipFactory.load("./mapchip.csv")

    #マップの作成
    @map = Map.new(@mp, "./map_layer.csv")
    @map.dp = -100

    #実座標をコリジョン設定
    rect = Rect.new(0, 0, @mp.chip_size[0], @mp.chip_size[1])
    @collision = Collision.new(rect, Point.new(0, 0))

    #海のマップチップを波がアニメーションする画像に置き換え
    sp = Sprite.new(:file=>"sea.png", :type=>:as)
    sp.oh = sp.w
    ar = SpriteAnimation.new(:sprite=>sp, :wait=>0.4).start # 開始のみ、表示はしない
    @map.set_mapchip_base(0, 3, ar)
  end

  def size
    return @mp.chip_size
  end

  def move(dx, dy, type=:sync)
    @map.move(dx, dy, type)
    @collision.pos = @map.pos.dup unless type == :view
  end
  
  def move_to(x, y, type=:sync)
    @map.move_to(x, y, type)
    @collision.pos = @map.pos.dup unless type == :view
  end
  
  def_delegators(:@map, :w, :h, :get_code, :get_code_real)
  def_delegators(:@map, :dispose, :update, :get_amount, :events)
  def_delegators(:@map, :show, :hide)
end
