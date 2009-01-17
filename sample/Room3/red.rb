# -*- encoding: utf-8 -*-
class Red
  include Story::Scene
  include MainComponent

  def init
    @yuki = Yuki.new
    @yuki.select_textbox(message_box[:box])
    @yuki.select_commandbox(command_box[:box])
    @akamatsu = Sprite.new(:file => "image/akamatsu.png", :type => :ck)
    @akamatsu.center.bottom
    @yuki.regist_parts(:akamatsu, @akamatsu)

    @room = Sprite.new(:file=>"image/room_red.png", :type=>:as)
    @room.center.bottom

    var[:akamatsu_aisatsu]      = false if var[:akamatsu_aisatsu]      == nil
    var[:release_akamatsu_book] = false if var[:release_akamatsu_book] == nil
    var[:search_bookmark]       = false if var[:search_bookmark]       == nil
    var[:get_bookmark]          = false if var[:get_bookmark]          == nil
  end

  def setup
    @yuki.setup
    message_box.start
    command_box.start
    @yuki.start_plot(@yuki.to_plot(self, :plot))
  end
  
  def get_command
    return [Yuki::Command.new("挨拶する",   nil, lambda{var[:akamatsu_aisatsu] == false}, @yuki.to_plot(self, :red2)),
             Yuki::Command.new("辺りを見る", nil, lambda{var[:akamatsu_aisatsu]==true }, @yuki.to_plot(self, :look)),
             Yuki::Command.new("話す",       nil, lambda{var[:akamatsu_aisatsu]==true }, @yuki.to_plot(self, :talk)),
             Yuki::Command.new("渡す",       nil, lambda{var[:akamatsu_aisatsu] && var[:release_akamatsu_book] && var[:search_bookmark]==false}, @yuki.to_plot(self, :send1)),
             Yuki::Command.new("渡す",       nil, lambda{var[:search_bookmark] && var[:get_bookmark] && var[:aikotoba]==false}, @yuki.to_plot(self, :send2)),
             Yuki::Command.new("戻る",       nil, lambda{var[:akamatsu_aisatsu]==true}, MainScene)]
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
  
  def plot(yuki)
    yuki.text "赤の扉から中に入った。"
    yuki.pause.clear
    yuki.show :akamatsu
    yuki.text "目の前には"
    yuki.color(:red){var[:akamatsu_aisatsu] ? "赤松さん" : "男の人"}
    yuki.text "が居る。"
    yuki.cr
    return self.method(:main_loop)
  end
  
  def main_loop(yuki)
    loop do
      yuki.text "どうする？"
      yuki.command get_command
      return yuki.select_result if yuki.is_scene?(yuki.select_result)
      yuki.select_result.call(@yuki) if yuki.is_scenario?(yuki.select_result)
    end
  end

  def red2(yuki)
    yuki.clear
    text_wait "「はっ、"
    text_wait "私の、"
    text_wait "名前は、"
    text_wait "赤松と、"
    text_wait "申します！"
    yuki.cr
    text_wait "　よろしく、"
    yuki.text "お願いします！」"
    yuki.pause.clear
    var[:akamatsu_aisatsu] = true
  end

  def look(yuki)
    yuki.clear
    yuki.text "部屋を見回すと、勉強家らしく、"
    yuki.cr
    yuki.text "机と数々の本が本棚にしまってある。"
    yuki.pause.clear
  end

  def talk(yuki)
    yuki.clear
    text_wait "「はっ、"
    text_wait "私は、"
    text_wait "某大学の、"
    text_wait "はっ、"
    yuki.text "８年生です！"
    yuki.pause.cr
    text_wait "　今年こそ、"
    text_wait "無事、"
    text_wait "卒業、"
    text_wait "できるよう！"
    yuki.cr
    text_wait "　精進する、"
    text_wait "所存で、"
    text_wait "ございます！」"
    yuki.pause.clear
  end

  def send1(yuki)
    yuki.clear
    yuki.text "あなたは、青山君から受け取っていた本を返した。"
    yuki.pause.clear
    text_wait "「あっ、"
    text_wait "青山くんから、"
    yuki.text "本を受け取って頂いたのですね！"
    yuki.pause.cr
    text_wait "　あ、"
    text_wait "ありがとうございます！"
    yuki.pause.clear
    text_wait "　あ、"
    text_wait "あのひと、"
    yuki.text "ちょっとビビるでしょ？"
    yuki.pause.cr
    text_wait "　・・・おっとと、"
    text_wait "聞こえてちゃ、"
    yuki.text "困るな。」"
    yuki.pause.clear
    yuki.text "　それでは・・・・・。"
    yuki.pause.clear
    yuki.text "　・・・・・。"
    yuki.pause.clear
    text_wait "　おや、"
    text_wait "栞が、"
    text_wait "入って、"
    yuki.text "ないですね。"
    yuki.pause.cr
    text_wait "　あれは、"
    text_wait "僕の、"
    text_wait "大事な、"
    yuki.text "宝物なんです！"
    yuki.pause.cr
    text_wait "　青山君の、"
    text_wait "部屋に、"
    text_wait "戻って、"
    yuki.cr
    text_wait "　栞を、"
    text_wait "探して、"
    text_wait "きてください！」"
    yuki.pause.clear
    var[:search_bookmark]=true
  end

  def send2(yuki)
    yuki.clear
    text_wait "「あっ、"
    text_wait "これは、"
    yuki.text "無くなっていた栞！"
    yuki.pause.cr
    text_wait "　ありがとうございます！"
    yuki.cr
    text_wait "　あの、"
    text_wait "お礼といっては、"
    yuki.text "何ですが、"
    yuki.pause.cr
    text_wait "　合言葉を、"
    text_wait "教えて、"
    yuki.text "差し上げます！」"
    yuki.pause.clear
    text_wait "「『こんなゲーム", 0.5
    text_wait "　まじになっちゃって", 0.5
    yuki.cr
    text_wait "　　どうするの』", 0.5
    yuki.cr
    text_wait "　これが、"
    text_wait "合い言葉です！"
    yuki.cr
    text_wait "　それでは、"
    yuki.text "お元気で！」"
    yuki.pause.clear
    var[:aikotoba]=true
  end
    
  def text_wait(txt, w = 0.3)
    @yuki.text txt
    @yuki.wait w
  end

  def final
    message_box.stop
    command_box.stop
  end
    
  def dispose
    @akamatsu.dispose
    @room.dispose
  end
end
