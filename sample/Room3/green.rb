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

    @talks = Array.new(6){|i| self.method("talk#{i}".to_sym)}
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
    return [Yuki::Command.new("挨拶する",   nil, lambda{var[:midori_aisatsu]==false}, @yuki.to_plot(self, :green2)),
             Yuki::Command.new("辺りを見る", nil, lambda{var[:midori_aisatsu]==true},  @yuki.to_plot(self, :look_green)),
             Yuki::Command.new("話す",       nil, lambda{var[:midori_aisatsu]==true},  @yuki.to_plot(self, :talk)),
             Yuki::Command.new("戻る",       nil, lambda{var[:midori_aisatsu]==true},  MainScene)]
  end
  
  def plot(yuki) 
    yuki.text "緑の扉から中に入った。"
    yuki.pause.clear
    yuki.show :midori
    yuki.text "目の前には"
    yuki.color(:green){var[:midori_aisatsu]==true ? "みどりさん" : "女の人"}
    yuki.text "が居る。"
    yuki.cr
    return self.method(:main_command)
  end
  
  def main_command(yuki)
    loop do
      yuki.text "どうする？"
      yuki.command get_command
      yuki.clear
      return yuki.select_result if yuki.is_scene?(yuki.select_result)
      yuki.select_result.call(yuki) if yuki.is_scenario?(yuki.select_result)
    end
  end

  def green2(yuki)
    yuki.text "「私の名前はみどり。よろしくぅ」"
    yuki.pause.clear
    var[:midori_aisatsu]=true
  end

  def look_green(yuki)
    yuki.text "部屋の中は、いたってシンプルだ。"
    yuki.pause.cr
    yuki.text "女の子らしく、鏡台がある。"
    yuki.pause.clear
  end

  def talk(yuki)
    @talks[var[:midori_talk]].call(yuki)
  end

  def talk0(yuki)
    yuki.text "「普通の大学生よぉ。」"
    yuki.pause.clear
    var[:midori_talk] += 1
  end

  def talk1(yuki)
    yuki.text "「最近はぁ、"
    yuki.wait 0.3
    yuki.cr
    yuki.text "　お菓子作りにぃ、"
    yuki.wait 0.3
    yuki.cr
    yuki.text "　凝ってる、"
    yuki.wait 0.3
    yuki.text "みたいな？」"
    yuki.pause.clear
    var[:midori_talk] += 1
  end

  def talk2(yuki)
    yuki.text "「・・・え、"
    yuki.wait 0.3
    yuki.text "流行らないってぇ？"
    yuki.wait 0.3
    yuki.cr
    yuki.text "　駄目よぉ。流行に流されてちゃ。」"
    yuki.pause.clear
    var[:midori_talk] += 1
  end

  def talk3(yuki)
    yuki.text "「何事もぉ、"
    yuki.wait 0.3
    yuki.cr
    yuki.text "　ゴーイングマイウェイってやっていかないとぉ、"
    yuki.wait 0.3
    yuki.cr
    yuki.text "　体持たないよっ！？」"
    yuki.pause.clear
    var[:midori_talk] += 1
  end

  def talk4(yuki)
    yuki.text "「・・・ああ、そうそう！"
    yuki.wait 0.3
    yuki.cr
    yuki.text "　この本、"
    yuki.wait 0.3
    yuki.text "隣の青山くんのところから"
    yuki.cr
    yuki.text "　借りてきてたんだけどぉ、"
    yuki.cr
    yuki.text "　返しといてくれないかなぁ？"
    yuki.wait 1.0
    yuki.text "・"
    yuki.wait 0.5
    yuki.text "・"
    yuki.wait 0.5
    yuki.text "・"
    yuki.wait 1.0
    yuki.clear
    yuki.size(32){
      yuki.color(:red){
        yuki.text "　さっさと"
        yuki.wait 0.5
        yuki.cr
        yuki.text "　持って行け"
        yuki.wait 0.5
        yuki.cr
        yuki.text "　っつてんだろぉ！"
      }
    }
    yuki.text "」"
    yuki.pause.clear
    yuki.text "ひゃあ。"
    yuki.wait 0.5
    yuki.text "　結局、本を無理矢理渡された。"
    yuki.pause.clear
    var[:release_aoyama_book] = true
    var[:midori_talk] += 1
  end

  def talk5(yuki)
    yuki.text "「ちゃんと本渡してくれたぁ？」"
    yuki.pause.clear
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
