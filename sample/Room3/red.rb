# -*- encoding: utf-8 -*-
class Red
  include Story::Scene
  include MainComponent

  def init
    @yuki = Yuki.new(message_box[:box], command_box[:box]) do |box, cbox|
      select_textbox(box)
      select_commandbox(cbox)
    end
    def @yuki.text_wait(txt, w = 0.3)
      text txt
      wait w
    end

    @akamatsu = Sprite.new(:file => "image/akamatsu.png", :type => :ck)
    @akamatsu.center.bottom
    @yuki.regist_parts(:akamatsu, @akamatsu)

    @room = Sprite.new(:file=>"image/room_red.png", :type=>:as)
    @room.center.bottom

    var[:akamatsu_aisatsu]      = false if var[:akamatsu_aisatsu]      == nil
    var[:release_akamatsu_book] = false if var[:release_akamatsu_book] == nil
    var[:search_bookmark]       = false if var[:search_bookmark]       == nil
    var[:get_bookmark]          = false if var[:get_bookmark]          == nil
    
    @yuki.vars[:var] = var
    @yuki.vars[:command] = get_command
    @yuki.vars[:main_loop] = main_loop
  end

  def setup
    @yuki.setup
    message_box.start
    command_box.start
    @yuki.start_plot(plot)
  end
  
  def get_command
    return [Yuki::Command.new("挨拶する",   nil, lambda{var[:akamatsu_aisatsu] == false}, red2),
             Yuki::Command.new("辺りを見る", nil, lambda{var[:akamatsu_aisatsu]==true }, look),
             Yuki::Command.new("話す",       nil, lambda{var[:akamatsu_aisatsu]==true }, talk),
             Yuki::Command.new("渡す",       nil, lambda{var[:akamatsu_aisatsu] && var[:release_akamatsu_book] && var[:search_bookmark]==false}, send1),
             Yuki::Command.new("渡す",       nil, lambda{var[:search_bookmark] && var[:get_bookmark] && var[:aikotoba]==false}, send2),
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
  
  def plot
    yuki_plot do
      text "赤の扉から中に入った。"
      pause.clear
      show :akamatsu
      text "目の前には"
      color(:red){vars[:var][:akamatsu_aisatsu] ? "赤松さん" : "男の人"}
      text "が居る。"
      cr
      vars[:main_loop]
    end
  end
  
  def main_loop
    yuki_plot do
      loop do
        text "どうする？"
        command vars[:command]
        break select_result if is_scene?(select_result)
        call_plot(select_result) if is_scenario?(select_result)
      end
    end
  end

  def red2
    yuki_plot do
      clear
      text_wait "「はっ、"
      text_wait "私の、"
      text_wait "名前は、"
      text_wait "赤松と、"
      text_wait "申します！"
      cr
      text_wait "　よろしく、"
      text "お願いします！」"
      pause.clear
      vars[:var][:akamatsu_aisatsu] = true
    end
  end

  def look
    yuki_plot do
      clear
      text "部屋を見回すと、勉強家らしく、"
      cr
      text "机と数々の本が本棚にしまってある。"
      pause.clear
    end
  end

  def talk
    yuki_plot do
      clear
      text_wait "「はっ、"
      text_wait "私は、"
      text_wait "某大学の、"
      text_wait "はっ、"
      text "８年生です！"
      pause.cr
      text_wait "　今年こそ、"
      text_wait "無事、"
      text_wait "卒業、"
      text_wait "できるよう！"
      cr
      text_wait "　精進する、"
      text_wait "所存で、"
      text_wait "ございます！」"
      pause.clear
    end
  end

  def send1
    yuki_plot do
      clear
      text "あなたは、青山君から受け取っていた本を返した。"
      pause.clear
      text_wait "「あっ、"
      text_wait "青山くんから、"
      text "本を受け取って頂いたのですね！"
      pause.cr
      text_wait "　あ、"
      text_wait "ありがとうございます！"
      pause.clear
      text_wait "　あ、"
      text_wait "あのひと、"
      text "ちょっとビビるでしょ？"
      pause.cr
      text_wait "　・・・おっとと、"
      text_wait "聞こえてちゃ、"
      text "困るな。」"
      pause.clear
      text "　それでは・・・・・。"
      pause.clear
      text "　・・・・・。"
      pause.clear
      text_wait "　おや、"
      text_wait "栞が、"
      text_wait "入って、"
      text "ないですね。"
      pause.cr
      text_wait "　あれは、"
      text_wait "僕の、"
      text_wait "大事な、"
      text "宝物なんです！"
      pause.cr
      text_wait "　青山君の、"
      text_wait "部屋に、"
      text_wait "戻って、"
      cr
      text_wait "　栞を、"
      text_wait "探して、"
      text_wait "きてください！」"
      pause.clear
      vars[:var][:search_bookmark]=true
    end
  end

  def send2
    yuki_plot do
      clear
      text_wait "「あっ、"
      text_wait "これは、"
      text "無くなっていた栞！"
      pause.cr
      text_wait "　ありがとうございます！"
      cr
      text_wait "　あの、"
      text_wait "お礼といっては、"
      text "何ですが、"
      pause.cr
      text_wait "　合言葉を、"
      text_wait "教えて、"
      text "差し上げます！」"
      pause.clear
      text_wait "「『こんなゲーム", 0.5
      text_wait "　まじになっちゃって", 0.5
      cr
      text_wait "　　どうするの』", 0.5
      cr
      text_wait "　これが、"
      text_wait "合い言葉です！"
      cr
      text_wait "　それでは、"
      text "お元気で！」"
      pause.clear
      vars[:var][:aikotoba]=true
    end
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
