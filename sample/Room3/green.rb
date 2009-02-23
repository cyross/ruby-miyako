# -*- encoding: utf-8 -*-
class Green
  include Story::Scene
  include MainComponent

  def init
    @yuki = Yuki.new
    @yuki.select_textbox(message_box[:box])
    @yuki.select_commandbox(command_box[:box])
    @midori = Sprite.new(:file => "image/midori.png", :type => :ck)
    @midori.center.bottom
    @yuki.regist_parts(:midori, @midori)

    @room = Sprite.new(:file => "image/room_green.png", :type => :as)
    @room.center.bottom

    var[:midori_aisatsu]      = false if var[:midori_aisatsu]      == nil
    var[:release_aoyama_book] = false if var[:release_aoyama_book] == nil
    var[:midori_talk]         = 0     if var[:midori_talk]         == nil

    @talks = Array.new(6){|i| self.method("talk#{i}".to_sym).call}
    
    @yuki.vars[:var] = var
    @yuki.vars[:main_command] = main_command
    @yuki.vars[:command] = get_command
    @yuki.vars[:talks] = @talks
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
    return [Yuki::Command.new("挨拶する",   nil, lambda{var[:midori_aisatsu]==false}, green2),
            Yuki::Command.new("辺りを見る", nil, lambda{var[:midori_aisatsu]==true}, look_green),
            Yuki::Command.new("話す",       nil, lambda{var[:midori_aisatsu]==true}, talk),
            Yuki::Command.new("戻る",       nil, lambda{var[:midori_aisatsu]==true}, MainScene)]
  end
  
  def plot
    yuki_plot do
      text "緑の扉から中に入った。"
      pause.clear
      show :midori
      text "目の前には"
      color(:green){vars[:var][:midori_aisatsu]==true ? "みどりさん" : "女の人"}
      text "が居る。"
      cr
      vars[:main_command]
    end
  end
  
  def main_command
    yuki_plot do
    loop do
      text "どうする？"
      command vars[:command]
      clear
      break select_result if is_scene?(select_result)
      call_plot(select_result) if is_scenario?(select_result)
    end
    end
  end

  def green2
    yuki_plot do
      text "「私の名前はみどり。よろしくぅ」"
      pause.clear
      vars[:var][:midori_aisatsu]=true
    end
  end

  def look_green
    yuki_plot do
      text "部屋の中は、いたってシンプルだ。"
      pause.cr
      text "女の子らしく、鏡台がある。"
      pause.clear
    end
  end

  def talk
    yuki_plot do
      call_plot(vars[:talks][vars[:var][:midori_talk]])
    end
  end

  def talk0
    yuki_plot do
      text "「普通の大学生よぉ。」"
      pause.clear
      vars[:var][:midori_talk] += 1
    end
  end

  def talk1
    yuki_plot do
      text "「最近はぁ、"
      wait 0.3
      cr
      text "　お菓子作りにぃ、"
      wait 0.3
      cr
      text "　凝ってる、"
      wait 0.3
      text "みたいな？」"
      pause.clear
      vars[:var][:midori_talk] += 1
    end
  end

  def talk2
    yuki_plot do
      text "「・・・え、"
      wait 0.3
      text "流行らないってぇ？"
      wait 0.3
      cr
      text "　駄目よぉ。流行に流されてちゃ。」"
      pause.clear
      vars[:var][:midori_talk] += 1
    end
  end

  def talk3
    yuki_plot do
      text "「何事もぉ、"
      wait 0.3
      cr
      text "　ゴーイングマイウェイってやっていかないとぉ、"
      wait 0.3
      cr
      text "　体持たないよっ！？」"
      pause.clear
      vars[:var][:midori_talk] += 1
    end
  end

  def talk4
    yuki_plot do
      text "「・・・ああ、そうそう！"
      wait 0.3
      cr
      text "　この本、"
      wait 0.3
      text "隣の青山くんのところから"
      cr
      text "　借りてきてたんだけどぉ、"
      cr
      text "　返しといてくれないかなぁ？"
      wait 1.0
      text "・"
      wait 0.5
      text "・"
      wait 0.5
      text "・"
      wait 1.0
      clear
      size(32){
        color(:red){
          text "　さっさと"
          wait 0.5
          cr
          text "　持って行け"
          wait 0.5
          cr
          text "　っつてんだろぉ！"
        }
      }
      text "」"
      pause.clear
      text "ひゃあ。"
      wait 0.5
      text "　結局、本を無理矢理渡された。"
      pause.clear
      vars[:var][:release_aoyama_book] = true
      vars[:var][:midori_talk] += 1
    end
  end

  def talk5
    yuki_plot do
      text "「ちゃんと本渡してくれたぁ？」"
      pause.clear
    end
  end

  def final
    message_box.stop
    command_box.stop
  end

  def dispose
    @midori.dispose
    @room.dispose
  end
end
