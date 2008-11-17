class Red
  include Story::Scene
  include Yuki
  include MainComponent

  def init
    init_yuki(message_box, command_box, :box)
    @akamatsu = Sprite.new(:file => "image/akamatsu.png", :type => :ck)
    @akamatsu.center.bottom
    @akamatsu.dp = 100

    @room = Sprite.new(:file=>"image/room_red.png", :type=>:as)
    @room.center.bottom
    @room.dp = 0

    var[:akamatsu_aisatsu]      = false if var[:akamatsu_aisatsu]      == nil
    var[:release_akamatsu_book] = false if var[:release_akamatsu_book] == nil
    var[:search_bookmark]       = false if var[:search_bookmark]       == nil
    var[:get_bookmark]          = false if var[:get_bookmark]          == nil
  end

  def setup
    setup_yuki
    @room.show
  end

  def get_command
    return [Command.new("挨拶する",   lambda{var[:akamatsu_aisatsu] == false}, scenario(:red2)),
            Command.new("辺りを見る", lambda{var[:akamatsu_aisatsu]==true }, scenario(:look)),
            Command.new("話す",       lambda{var[:akamatsu_aisatsu]==true }, scenario(:talk)),
            Command.new("渡す",       lambda{var[:akamatsu_aisatsu] && var[:release_akamatsu_book] && var[:search_bookmark]==false}, scenario(:send1)),
            Command.new("渡す",       lambda{var[:search_bookmark] && var[:get_bookmark] && var[:aikotoba]==false}, scenario(:send2)),
            Command.new("戻る",       lambda{var[:akamatsu_aisatsu]==true}, MainScene)]
  end
  
  def plot
    text "赤の扉から中に入った。"
    pause.clear
    @akamatsu.show
    text "目の前には"
    color(:red){var[:akamatsu_aisatsu] ? "赤松さん" : "男の人"}
    text "が居る。"
    cr
    return main_loop
  end
  
  def main_loop
    loop do
      text "どうする？"
      command get_command
      return result if result_is_scene?
      result.call if result_is_scenario?
    end
  end

  def red2
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
    var[:akamatsu_aisatsu] = true
  end

  def look
    clear
    text "部屋を見回すと、勉強家らしく、"
    cr
    text "机と数々の本が本棚にしまってある。"
    pause.clear
  end

  def talk
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

  def send1
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
    var[:search_bookmark]=true
  end

  def send2
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
    var[:aikotoba]=true
  end
    
  def text_wait(txt, w = 0.3)
    text txt
    wait w
  end
    
  def final
    @akamatsu.hide
    @room.hide
  end
end
