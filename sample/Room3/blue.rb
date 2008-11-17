class Blue
  include Story::Scene
  include Yuki
  include MainComponent

  def init
    init_yuki(message_box, command_box, :box)
    @aoyama = Sprite.new(:file => "image/aoyama.png", :type => :ck)
    @aoyama.center.bottom
    @aoyama.dp = 100

    @room = Sprite.new(:file => "image/room_blue.png", :type => :as)
    @room.center.bottom
    @room.dp = 0

    var[:aoyama_aisatsu]        = false if var[:aoyama_aisatsu]        == nil
    var[:release_aoyama_book]   = false if var[:release_aoyama_book]   == nil
    var[:search_bookmark]       = false if var[:search_bookmark]       == nil
    var[:look_video_base]       = false if var[:look_video_base]       == nil
    var[:get_bookmark]          = false if var[:get_bookmark]          == nil
    var[:release_akamatsu_book] = false if var[:release_akamatsu_book] == nil
  end

  def setup
    setup_yuki
    @room.show
  end
  
  def get_command
    return [Command.new("挨拶する", lambda{var[:aoyama_aisatsu]==false}, scenario(:blue2)),
            Command.new("辺りを見る", lambda{var[:aoyama_aisatsu]==true}, scenario(:look_blue)),
            Command.new("話す", lambda{var[:aoyama_aisatsu]==true}, scenario(:talk)),
            Command.new("渡す", lambda{var[:aoyama_aisatsu]==true && var[:release_aoyama_book]==true && var[:release_akamatsu_book]==false}, scenario(:send1)),
            Command.new("探す", lambda{var[:search_bookmark]==true && var[:get_bookmark]==false}, scenario(:search)),
            Command.new("戻る", lambda{var[:aoyama_aisatsu]==true}, MainScene)]
  end
  
  def get_search
    "どこを？"
    return [Command.new("壁", nil, scenario(:wall)),
            Command.new("テレビ", nil, scenario(:tv)),
            Command.new("テレビ台", nil, scenario(:tv_base)),
            Command.new("ビデオデッキ", lambda{var[:look_video_base] == true}, scenario(:video)),
            Command.new("テレビゲーム機", lambda{var[:look_video_base] == true}, scenario(:tv_game)),
            Command.new("ソファー", nil, scenario(:sofar)),
            Command.new("ベッド", nil, scenario(:bed)),
            Command.new("戻る", nil, "ret")]
  end
  
  def plot
    text "青の扉から中に入った。"
    pause.clear
    @aoyama.show
    text "目の前には"
    color(:cyan){var[:aoyama_aisatsu]==true ? "青山くん" : "男の子"}
    text "が居る。"
    cr
    return main_command
  end
  
  def main_command
    loop do
      @aoyama.show
      text "どうする？"
      command get_command
      clear
      return result if result_is_scene?
      result.call if result_is_scenario?
    end
  end

  def blue2
    text "「オレの名前は"
    color(:cyan){"青山"}
    text "。よろしくな」"
    pause.clear
    var[:aoyama_aisatsu]=true
  end

  def look_blue
    text "部屋の中は整然としている。"
    pause.cr
    text "中にはテレビとソファーがあり、"
    cr
    text "ゆったりとくつろげるようになっている。"
    pause.clear
  end

  def talk
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

  def send1
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
    pause.cr
    text "　赤松さんの本を受け取った。"
    pause.clear
    var[:release_akamatsu_book] = true
  end

  def search
    text "「どうぞ」"
    cr
    @aoyama.hide
    search_command
  end

  def search_command
    loop do
      command get_search, "ret"
      clear
      break if result.kind_of?(String) && result == "ret"
      result.call if result_is_scenario?
    end
  end

  def wall
    text "壁を調べてみた。"
    pause.cr
    text "何もないようだ。"
    pause.clear
  end

  def tv
    text "テレビを調べてみた。"
    pause.cr
    text "テレビを点けてみた。"
    pause.cr
    text "・・・つまらんなぁ、この番組。"
    pause.clear
  end

  def tv_base
    text "テレビ台を調べてみた。"
    pause.cr
    text "中にはビデオデッキとテレビゲーム機があるようだ。"
    pause.clear
    var[:look_video_base] = true
  end

  def video
    text "ビデオデッキを調べてみた。"
    pause.cr
    text "いわゆるHDDビデオデッキだ。"
    pause.clear
    video2 if var[:get_bookmark]==false
  end

  def video2
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
    var[:get_bookmark] = true
  end

  def tv_game
    text "テレビゲーム機を調べてみた。"
    pause.cr
    text "・・・このゲーム機、対応ゲーム出てる？"
    pause.clear
  end

  def sofar
    text "ソファーを調べてみた。"
    pause.cr
    text "ふかふかだ。"
    wait 0.5
    text "ここで寝そべりたい・・・。"
    pause.clear
  end

  def bed
    text "ベッドを調べてみた。"
    pause.cr
    text "ソファーより固そうだ。"
    pause.clear
  end

  def final
    @aoyama.hide
    @room.hide
  end
end
