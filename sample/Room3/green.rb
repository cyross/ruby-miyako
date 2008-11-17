class Green
  include Story::Scene
  include Yuki
  include MainComponent

  def init
    init_yuki(message_box, command_box, :box)
    @midori = Sprite.new(:file => "image/midori.png", :type => :ck)
    @midori.center.bottom
    @midori.dp = 100

    @room = Sprite.new(:file => "image/room_green.png", :type => :as)
    @room.center.bottom
    @room.dp = 0

    var[:midori_aisatsu]      = false if var[:midori_aisatsu]      == nil
    var[:release_aoyama_book] = false if var[:release_aoyama_book] == nil
    var[:midori_talk]         = 0     if var[:midori_talk]         == nil

    @talks = Array.new(6){|i| scenario("talk#{i}".to_sym)}
  end

  def setup
    setup_yuki
    @room.show
  end

  def get_command
    return [Command.new("挨拶する",   lambda{var[:midori_aisatsu]==false}, scenario(:green2)),
            Command.new("辺りを見る", lambda{var[:midori_aisatsu]==true},  scenario(:look_green)),
            Command.new("話す",       lambda{var[:midori_aisatsu]==true},  scenario(:talk)),
            Command.new("戻る",       lambda{var[:midori_aisatsu]==true},  MainScene)]
  end
  
  def plot 
    text "緑の扉から中に入った。"
    pause.clear
    @midori.show
    text "目の前には"
    color(:green){var[:midori_aisatsu]==true ? "みどりさん" : "女の人"}
    text "が居る。"
    cr
    main_command
  end
  
  def main_command
    loop do
      text "どうする？"
      command get_command
      clear
      return result if result_is_scene?
      result.call if result_is_scenario?
    end
  end

  def green2
    text "「私の名前はみどり。よろしくぅ」"
    pause.clear
    var[:midori_aisatsu]=true
  end

  def look_green
    text "部屋の中は、いたってシンプルだ。"
    pause.cr
    text "女の子らしく、鏡台がある。"
    pause.clear
  end

  def talk
    @talks[var[:midori_talk]].call
  end

  def talk0
    text "「普通の大学生よぉ。」"
    pause.clear
    var[:midori_talk] += 1
  end

  def talk1
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
    var[:midori_talk] += 1
  end

  def talk2
    text "「・・・え、"
    wait 0.3
    text "流行らないってぇ？"
    wait 0.3
    cr
    text "　駄目よぉ。流行に流されてちゃ。」"
    pause.clear
    var[:midori_talk] += 1
  end

  def talk3
    text "「何事もぉ、"
    wait 0.3
    cr
    text "　ゴーイングマイウェイってやっていかないとぉ、"
    wait 0.3
    cr
    text "　体持たないよっ！？」"
    pause.clear
    var[:midori_talk] += 1
  end

  def talk4
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
    var[:release_aoyama_book] = true
    var[:midori_talk] += 1
  end

  def talk5
    text "「ちゃんと本渡してくれたぁ？」"
    pause.clear
  end

  def final
    @midori.hide
    @room.hide
  end
end
