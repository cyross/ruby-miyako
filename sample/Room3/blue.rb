# -*- encoding: utf-8 -*-
class Blue
  include Story::Scene
  include MainComponent

  def init
    @yuki = Yuki.new
    @yuki.select_textbox(message_box[:box])
    @yuki.select_commandbox(command_box[:box])
    @aoyama = Sprite.new(:file => "image/aoyama.png", :type => :ck)
    @aoyama.center.bottom
    @yuki.regist_parts(:aoyama, @aoyama)

    @room = Sprite.new(:file => "image/room_blue.png", :type => :as)
    @room.center.bottom

    var[:aoyama_aisatsu]        = false if var[:aoyama_aisatsu]        == nil
    var[:release_aoyama_book]   = false if var[:release_aoyama_book]   == nil
    var[:search_bookmark]       = false if var[:search_bookmark]       == nil
    var[:look_video_base]       = false if var[:look_video_base]       == nil
    var[:get_bookmark]          = false if var[:get_bookmark]          == nil
    var[:release_akamatsu_book] = false if var[:release_akamatsu_book] == nil
  end

  def setup
    @yuki.setup
    message_box.start
    command_box.start
    @yuki.start_plot(@yuki.to_plot(self, :plot))
  end

  def update
    return nil if Input.quit_or_escape?
    message_box.update_animation
    command_box.update_animation
    @yuki.update
    r = @yuki.executing? ? @now : @yuki.result
    if @yuki.is_scenario?(r)
      @yuki.start_plot(r)
      r = @now
    end
    return r
  end
  
  def render
    @room.render
    @yuki.render
    message_box.render
    command_box.render if @yuki.selecting?
  end
  
  def get_command
    return [Yuki::Command.new("挨拶する", nil, lambda{var[:aoyama_aisatsu]==false}, @yuki.to_plot(self, :blue2)),
             Yuki::Command.new("辺りを見る", nil, lambda{var[:aoyama_aisatsu]==true}, @yuki.to_plot(self, :look_blue)),
             Yuki::Command.new("話す", nil, lambda{var[:aoyama_aisatsu]==true}, @yuki.to_plot(self, :talk)),
             Yuki::Command.new("渡す", nil, lambda{var[:aoyama_aisatsu]==true && var[:release_aoyama_book]==true && var[:release_akamatsu_book]==false}, @yuki.to_plot(self, :send1)),
             Yuki::Command.new("探す", nil, lambda{var[:search_bookmark]==true && var[:get_bookmark]==false}, @yuki.to_plot(self, :search)),
             Yuki::Command.new("戻る", nil, lambda{var[:aoyama_aisatsu]==true}, MainScene)]
  end
  
  def get_search
    "どこを？"
    return [Yuki::Command.new("壁", nil, nil, @yuki.to_plot(self, :wall)),
             Yuki::Command.new("テレビ", nil, nil, @yuki.to_plot(self, :tv)),
             Yuki::Command.new("テレビ台", nil, nil, @yuki.to_plot(self, :tv_base)),
             Yuki::Command.new("ビデオデッキ", nil, lambda{var[:look_video_base] == true}, @yuki.to_plot(self, :video)),
             Yuki::Command.new("テレビゲーム機", nil, lambda{var[:look_video_base] == true}, @yuki.to_plot(self, :tv_game)),
             Yuki::Command.new("ソファー", nil, nil, @yuki.to_plot(self, :sofar)),
             Yuki::Command.new("ベッド", nil, nil, @yuki.to_plot(self, :bed)),
             Yuki::Command.new("戻る", nil, nil, "ret")]
  end
  
  def plot(yuki)
    yuki.text "青の扉から中に入った。"
    yuki.pause.clear
    yuki.show :aoyama
    yuki.text "目の前には"
    yuki.color(:cyan){var[:aoyama_aisatsu]==true ? "青山くん" : "男の子"}
    yuki.text "が居る。"
    yuki.cr
    return yuki.to_plot(self, :main_command)
  end
  
  def main_command(yuki)
    loop do
      yuki.show :aoyama
      yuki.text "どうする？"
      yuki.command get_command
      yuki.clear
      return yuki.select_result if yuki.is_scene?(yuki.select_result)
      yuki.select_result.call(yuki) if yuki.is_scenario?(yuki.select_result)
    end
  end

  def blue2(yuki)
    yuki.text "「オレの名前は"
    yuki.color(:cyan){"青山"}
    yuki.text "。よろしくな」"
    yuki.pause.clear
    var[:aoyama_aisatsu]=true
  end

  def look_blue(yuki)
    yuki.text "部屋の中は整然としている。"
    yuki.pause.cr
    yuki.text "中にはテレビとソファーがあり、"
    yuki.cr
    yuki.text "ゆったりとくつろげるようになっている。"
    yuki.pause.clear
  end

  def talk(yuki)
    yuki.text "「まぁ、オレはこうやってのんびりするのが"
    yuki.cr
    yuki.text "　好きなんだな。"
    yuki.pause.cr
    yuki.text "　とはいえども、いわゆるニートってやつじゃない。"
    yuki.pause.clear
    yuki.text "　ここには無いが、パソコン使って"
    yuki.cr
    yuki.text "　株の取引やってるわけさ。」"
    yuki.pause.clear
  end

  def send1(yuki)
    yuki.text "あなたは、みどりさんから受け取っていた本を返した。"
    yuki.pause.clear
    yuki.text "「おお、サンキュ。"
    yuki.pause.cr
    yuki.text "　みどりから受け取ったのか。"
    yuki.pause.cr
    yuki.text "　じゃああんたも、"
    yuki.color(:red){"ブチギレみどり"}
    yuki.text "を見たってわけか。」"
    yuki.pause.clear
    yuki.text "そのとき、どこからともなく声が聞こえた。"
    yuki.wait 0.5
    yuki.cr
    yuki.color(:red){
      yuki.text "『なあぁぁぁんですってぇぇぇぇ"
      yuki.wait 0.5
      yuki.cr
      yuki.text "私のどこがブチ切れてるってぇぇぇ！？』"
    }
    yuki.pause.cr
    yuki.text "「・・・ほらね。」"
    yuki.pause.clear
    yuki.text "「じゃあ、ついでにオレからも、"
    yuki.pause.cr
    yuki.text "　隣りの赤松さんところへ行って、"
    yuki.pause.cr
    yuki.text "　この本を返してきてくれないかなぁ？"
    yuki.pause.cr
    yuki.text "　頼むよ。」"
    yuki.pause.clear
    yuki.text "　赤松さんの本を受け取った。"
    yuki.pause.clear
    var[:release_akamatsu_book] = true
  end

  def search(yuki)
    yuki.text "「どうぞ」"
    yuki.cr
    yuki.hide :aoyama
    return search_command(yuki)
  end

  def search_command(yuki)
    loop do
      yuki.command get_search, "ret"
      yuki.clear
      break if yuki.select_result.kind_of?(String) && yuki.select_result == "ret"
      yuki.select_result.call(yuki) if yuki.is_scenario?(yuki.select_result)
    end
  end

  def wall(yuki)
    yuki.text "壁を調べてみた。"
    yuki.pause.cr
    yuki.text "何もないようだ。"
    yuki.pause.clear
  end

  def tv(yuki)
    yuki.text "テレビを調べてみた。"
    yuki.pause.cr
    yuki.text "テレビを点けてみた。"
    yuki.pause.cr
    yuki.text "・・・つまらんなぁ、この番組。"
    yuki.pause.clear
  end

  def tv_base(yuki)
    yuki.text "テレビ台を調べてみた。"
    yuki.pause.cr
    yuki.text "中にはビデオデッキとテレビゲーム機があるようだ。"
    yuki.pause.clear
    var[:look_video_base] = true
  end

  def video(yuki)
    yuki.text "ビデオデッキを調べてみた。"
    yuki.pause.cr
    yuki.text "いわゆるHDDビデオデッキだ。"
    yuki.pause.clear
    video2(yuki) if var[:get_bookmark]==false
  end

  def video2(yuki)
    yuki.text "・・・"
    yuki.wait 0.3
    yuki.text "ン！？　何か挟まってる。"
    yuki.pause.cr
    yuki.text "引っ張り出してみると、"
    yuki.color(:red){"真っ赤な栞"}
    yuki.text "だ。"
    yuki.pause.cr
    yuki.color(:red){"栞"}
    yuki.text "を見つけ出した！"
    yuki.pause.cr
    yuki.text "「良かったなぁ、見つかって。」"
    yuki.pause.clear
    var[:get_bookmark] = true
  end

  def tv_game(yuki)
    yuki.text "テレビゲーム機を調べてみた。"
    yuki.pause.cr
    yuki.text "・・・このゲーム機、対応ゲーム出てる？"
    yuki.pause.clear
  end

  def sofar(yuki)
    yuki.text "ソファーを調べてみた。"
    yuki.pause.cr
    yuki.text "ふかふかだ。"
    yuki.wait 0.5
    yuki.text "ここで寝そべりたい・・・。"
    yuki.pause.clear
  end

  def bed(yuki)
    yuki.text "ベッドを調べてみた。"
    yuki.pause.cr
    yuki.text "ソファーより固そうだ。"
    yuki.pause.clear
  end

  def final
    message_box.stop
    command_box.stop
  end

  def dispose
    @aoyama.dispose
    @room.dispose
  end
end
