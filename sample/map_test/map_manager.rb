#�}�b�v�Ǘ��N���X
class MapManager
  extend Forwardable

  attr_reader :collision
  
  def initialize
    @moving = false

    #�}�b�v�`�b�v�C���X�^���X�̍쐬
    @mp = MapChipFactory.load("./mapchip.csv")

    #�}�b�v�̍쐬
    @map = Map.new(@mp, "./map_layer.csv")
    @map.dp = -100

    #�����W���R���W�����ݒ�
    rect = Rect.new(0, 0, @mp.chip_size[0], @mp.chip_size[1])
    @collision = Collision.new(rect, Point.new(0, 0))

    #�C�̃}�b�v�`�b�v��g���A�j���[�V��������摜�ɒu������
    sp = Sprite.new(:file=>"sea.png", :type=>:as)
    sp.oh = sp.w
    ar = SpriteAnimation.new(:sprite=>sp, :wait=>0.4).start # �J�n�̂݁A�\���͂��Ȃ�
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
