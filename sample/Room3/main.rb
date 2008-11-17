class MainScene
  include Story::Scene
  include Yuki
  include MainComponent
    
  def init
    init_yuki(message_box, command_box, :box)
    @doors = Sprite.new(:file=>"image/three_doors.png", :type=>:as)
    @doors.center.bottom
    @doors.dp = 0

    var[:sekkaku] = true if var[:sekkaku] == nil
    var[:aikotoba] = false if var[:aikotoba] == nil
  end

  def setup
    setup_yuki
    @doors.show
  end

  def get_command
    return [Command.new("緑の扉から入る", nil, Green),
            Command.new("赤の扉から入る", lambda{var[:sekkaku] == true }, scenario(:red_sekkaku)),
            Command.new("赤の扉から入る", lambda{var[:sekkaku] == false}, Red),
            Command.new("青の扉から入る", nil, Blue),
            Command.new("合い言葉を言う", lambda{var[:aikotoba] == true}, scenario(:tell_aikotoba))]
  end
  
  def plot
    ret = @now
    text "目の前には緑、赤、青の３つの扉がある。"
    cr
    text "どうする？"
    cr
    command get_command
    ret = result if result_is_scene?
    ret = result.call if result_is_scenario?
    var[:sekkaku] = false
    return ret
  end

  def main_command
  end
  
  def red_sekkaku
    text "せっかくだから、赤の扉に入ってみよう"
    pause.clear
    return Red
  end
  
  def tell_aikotoba
    text "「こんなゲーム、"
    wait 0.5
    text "まじになっちゃって　"
    wait 0.5
    text "どうするの！」"
    pause.clear
    return Ending
  end
  
  def final
    @doors.hide
  end
end
