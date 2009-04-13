# encoding: utf-8
# ���X�^�X�N���[���T���v��
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'
require 'Miyako/EXT/raster_scroll'

include Miyako

#1�b��Ƀ��X�^�X�N���[���̃t�F�[�h�A�E�g��ݒ肷��
wait = WaitCounter.new(1.0).start
# 0.05�b���ƂɁA2���C�����A8�s�N�Z���P�ʂ̃��X�^�X�N���[�����s��
sprite = Sprite.new(:file => "Animation2/lex_body.png", :type => :ck).centering
rs = RasterScroll.new(sprite).start({:lines => 2, :size => 8, :wait=>WaitCounter.new(0.05)})
fade = false

Miyako.main_loop do
  break if Input.quit_or_escape?
  rs.effecting? ? rs.update.render : sprite.render
  if fade == false && wait.finish?
    #1�b�ゲ�ƂɁA���X�^�X�N���[���̕����k�߂�
    rs.fade_out(1, WaitCounter.new(1.0))
    fade = true
  end
end