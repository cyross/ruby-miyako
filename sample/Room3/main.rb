# -*- encoding: utf-8 -*-
class MainScene
  include Story::Scene
  include MainComponent
    
  def init
    @yuki = Yuki.new
    @yuki.select_textbox(message_box[:box])
    @yuki.select_commandbox(command_box[:box])
    @doors = Sprite.new(:file=>"image/three_doors.png", :type=>:as)
    @doors.center.bottom

    var[:sekkaku] = true if var[:sekkaku] == nil
    var[:aikotoba] = false if var[:aikotoba] == nil
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
    @yuki.start_plot(@yuki.to_plot(self, :plot)) if (@yuki.executing? == false && r == @now)
    return r
  end
  
  def get_command
    return [Yuki::Command.new("緑の扉から入る", nil, nil, Green),
             Yuki::Command.new("赤の扉から入る", nil, lambda{var[:sekkaku] == true }, @yuki.to_plot(self, :red_sekkaku)),
             Yuki::Command.new("赤の扉から入る", nil, lambda{var[:sekkaku] == false}, Red),
             Yuki::Command.new("青の扉から入る", nil, nil, Blue),
             Yuki::Command.new("合い言葉を言う", nil, lambda{var[:aikotoba] == true}, @yuki.to_plot(self, :tell_aikotoba))]
  end
  
  def plot(yuki)
    ret = @now
    yuki.text "目の前には緑、赤、青の３つの扉がある。"
    yuki.cr
    yuki.text "どうする？"
    yuki.cr
    yuki.command get_command
    ret = yuki.select_result if yuki.is_scene?(yuki.select_result)
    ret = yuki.select_result.call(yuki) if yuki.is_scenario?(yuki.select_result)
    yuki.clear
    var[:sekkaku] = false
    return ret
  end

  def main_command
  end
  
  def red_sekkaku(yuki)
    yuki.text "せっかくだから、赤の扉に入ってみよう"
    yuki.pause.clear
    return Red
  end
  
  def tell_aikotoba(yuki)
    yuki.text "「こんなゲーム、"
    yuki.wait 0.5
    yuki.text "まじになっちゃって　"
    yuki.wait 0.5
    yuki.text "どうするの！」"
    yuki.pause.clear
    return Ending
  end
  
  def render
    @doors.render
    message_box.render
    command_box.render if @yuki.selecting?
  end

  def final
    message_box.stop
    command_box.stop
  end
end

class Blue
  include Story::Scene

  def update
    return nil if Input.quit_or_escape?
    return @now
  end
end

class Green
  include Story::Scene

  def update
    return nil if Input.quit_or_escape?
    return @now
  end
end