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

    @yuki.vars[:var] = var
    @yuki.vars[:main_command] = main_command
    @yuki.vars[:search_command] = search_command
    @yuki.vars[:command] = get_command
    @yuki.vars[:search]  = get_search
    @yuki.vars[:video2]  = video2
  end

  def setup
    @yuki.setup
    message_box.start
    command_box.start
    @yuki.start_plot(plot)
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
    return [Yuki::Command.new("挨拶する", nil, lambda{var[:aoyama_aisatsu]==false}, blue2),
             Yuki::Command.new("辺りを見る", nil, lambda{var[:aoyama_aisatsu]==true}, look_blue),
             Yuki::Command.new("話す", nil, lambda{var[:aoyama_aisatsu]==true}, talk),
             Yuki::Command.new("渡す", nil, lambda{var[:aoyama_aisatsu]==true && var[:release_aoyama_book]==true && var[:release_akamatsu_book]==false}, send1),
             Yuki::Command.new("探す", nil, lambda{var[:search_bookmark]==true && var[:get_bookmark]==false}, search),
             Yuki::Command.new("戻る", nil, lambda{var[:aoyama_aisatsu]==true}, MainScene)]
  end
  
  def get_search
    return [Yuki::Command.new("壁", nil, nil, wall),
             Yuki::Command.new("テレビ", nil, nil, tv),
             Yuki::Command.new("テレビ台", nil, nil, tv_base),
             Yuki::Command.new("ビデオデッキ", nil, lambda{var[:look_video_base] == true}, video),
             Yuki::Command.new("テレビゲーム機", nil, lambda{var[:look_video_base] == true}, tv_game),
             Yuki::Command.new("ソファー", nil, nil, sofar),
             Yuki::Command.new("ベッド", nil, nil, bed),
             Yuki::Command.new("戻る", nil, nil, "ret")]
  end
  
  def plot
    yuki_plot do
      text "青の扉から中に入った。"
      pause.clear
      show :aoyama
      text "目の前には"
      color(:cyan){vars[:var][:aoyama_aisatsu]==true ? "青山くん" : "男の子"}
      text "が居る。"
      cr
      vars[:main_command]
    end
  end
  
  def main_command
    yuki_plot do
      loop do
        show :aoyama
        text "どうする？"
        command vars[:command]
        clear
        break select_result if is_scene?(select_result)
        call_plot(select_result) if is_scenario?(select_result)
      end
    end
  end

  def blue2
    yuki_plot do
      text "「オレの名前は"
      color(:cyan){"青山"}
      text "。よろしくな」"
      pause.clear
      vars[:var][:aoyama_aisatsu]=true
    end
  end

  def look_blue
    yuki_plot do
      text "部屋の中は整然としている。"
      pause.cr
      text "中にはテレビとソファーがあり、"
      cr
      text "ゆったりとくつろげるようになっている。"
      pause.clear
    end
  end

  def talk
    yuki_plot do
      text "「まぁ、オレはこうやってのんびりするのが"
      cr
      text "　好きなんだな。"
      pause.cr
      text "　とはいえども、いわゆるニートってやつじゃない。"
      pause.clear
      text "　ここには無いが、パソコン使って"
      cr
      text "　株の取引やってるわけさ。」"
      pause.clear
    end
  end

  def send1
    yuki_plot do
      text "あなたは、みどりさんから受け取っていた本を返した。"
      pause.clear
      text "「おお、サンキュ。"
      pause.cr
      text "　みどりから受け取ったのか。"
      pause.cr
      text "　じゃああんたも、"
      color(:red){"ブチギレみどり"}
      text "を見たってわけか。」"
      pause.clear
      text "そのとき、どこからともなく声が聞こえた。"
      wait 0.5
      cr
      color(:red){
        text "『なあぁぁぁんですってぇぇぇぇ"
        wait 0.5
        cr
        text "私のどこがブチ切れてるってぇぇぇ！？』"
      }
      pause.cr
      text "「・・・ほらね。」"
      pause.clear
      text "「じゃあ、ついでにオレからも、"
      pause.cr
      text "　隣りの赤松さんところへ行って、"
      pause.cr
      text "　この本を返してきてくれないかなぁ？"
      pause.cr
      text "　頼むよ。」"
      pause.clear
      text "　赤松さんの本を受け取った。"
      pause.clear
      vars[:var][:release_akamatsu_book] = true
    end
  end

  def search
    yuki_plot do
      text "「どうぞ」"
      cr
      hide :aoyama
      call_plot(vars[:search_command])
    end
  end

  def search_command
    yuki_plot do
      loop do
        text "どこを？"
        command vars[:search], "ret"
        clear
        break if select_result.kind_of?(String) && select_result == "ret"
        call_plot(select_result) if is_scenario?(select_result)
      end
    end
  end

  def wall
    yuki_plot do
      text "壁を調べてみた。"
      pause.cr
      text "何もないようだ。"
      pause.clear
    end
  end

  def tv
    yuki_plot do
      text "テレビを調べてみた。"
      pause.cr
      text "テレビを点けてみた。"
      pause.cr
      text "・・・つまらんなぁ、この番組。"
      pause.clear
    end
  end

  def tv_base
    yuki_plot do
      text "テレビ台を調べてみた。"
      pause.cr
      text "中にはビデオデッキとテレビゲーム機があるようだ。"
      pause.clear
      vars[:var][:look_video_base] = true
    end
  end

  def video
    yuki_plot do
      text "ビデオデッキを調べてみた。"
      pause.cr
      text "いわゆるHDDビデオデッキだ。"
      pause.clear
      call_plot(vars[:video2]) if vars[:var][:get_bookmark]==false
    end
  end

  def video2
    yuki_plot do
      text "・・・"
      wait 0.3
      text "ン！？　何か挟まってる。"
      pause.cr
      text "引っ張り出してみると、"
      color(:red){"真っ赤な栞"}
      text "だ。"
      pause.cr
      color(:red){"栞"}
      text "を見つけ出した！"
      pause.cr
      text "「良かったなぁ、見つかって。」"
      pause.clear
      vars[:var][:get_bookmark] = true
    end
  end

  def tv_game
    yuki_plot do
      text "テレビゲーム機を調べてみた。"
      pause.cr
      text "・・・このゲーム機、対応ゲーム出てる？"
      pause.clear
    end
  end

  def sofar
    yuki_plot do
      text "ソファーを調べてみた。"
      pause.cr
      text "ふかふかだ。"
      wait 0.5
      text "ここで寝そべりたい・・・。"
      pause.clear
    end
  end

  def bed
    yuki_plot do
      text "ベッドを調べてみた。"
      pause.cr
      text "ソファーより固そうだ。"
      pause.clear
    end
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
