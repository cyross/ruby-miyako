# -*- encoding: utf-8 -*-
class MainScene
  include Story::Scene
  include MainComponent

  def init
    @yuki = Yuki.new(message_box, command_box){|box, cbox|
      select_textbox(box[:box], box)
      select_commandbox(cbox[:box], cbox)
    }
    @yuki.select_plot(plot)
    @yuki.load_bg :doors, "image/three_doors.png"
    @yuki.bgs[:doors].center!.bottom!

    var[:sekkaku] = true if var[:sekkaku] == nil
    var[:aikotoba] = false if var[:aikotoba] == nil

    @yuki.vars[:var] = var
    @yuki.vars[:tell_aikotoba] = tell_aikotoba
    @yuki.vars[:ending] = Ending
    @yuki.vars[:red]    = Red
    @yuki.vars[:blue]   = Blue
    @yuki.vars[:green]  = Green
    @yuki.vars[:now]    = @now
    @yuki.vars[:command]= get_command
  end

  def setup
    @yuki.setup
    @yuki.bg_show
    @yuki.textbox_all.start
    @yuki.commandbox_all.start
    @yuki.start_plot(plot)
  end

  def update
    return nil if Input.quit_or_escape?
    @yuki.textbox_all.update_animation
    @yuki.commandbox_all.update_animation
    @yuki.update
    r = @yuki.executing? ? @now : @yuki.result
    @yuki.start_plot(plot) if (@yuki.executing? == false && r == @now)
    return r
  end

  def get_command
    return [Yuki::Command.new("緑の扉から入る", nil, nil, true, nil, Green),
            Yuki::Command.new("赤の扉から入る", nil, nil, true, lambda{var[:sekkaku] == true }, red_sekkaku),
            Yuki::Command.new("赤の扉から入る", nil, nil, true, lambda{var[:sekkaku] == false}, Red),
            Yuki::Command.new("青の扉から入る", nil, nil, true, nil, Blue),
            Yuki::Command.new("合い言葉を言う", nil, nil, true, lambda{var[:aikotoba] == true}, tell_aikotoba)]
  end

  def plot
    yuki_plot{
      ret = vars[:now]
      text "目の前には緑、赤、青の３つの扉がある。"
      cr
      text "どうする？"
      cr
      command vars[:command]
      ret = select_result if is_scene?(select_result)
      ret = call_plot(select_result) if is_scenario?(select_result)
      clear
      vars[:var][:sekkaku] = false
      ret
    }
  end

  def main_command
  end

  def red_sekkaku
    yuki_plot{
      text "せっかくだから、赤の扉に入ってみよう"
      pause.clear
      vars[:red]
    }
  end

  def tell_aikotoba
    yuki_plot{
      text "「こんなゲーム、"
      wait 0.5
      text "まじになっちゃって　"
      wait 0.5
      text "どうするの！」"
      pause.clear
      vars[:ending]
    }
  end

  def render
    @yuki.bgs.render
    @yuki.textbox_all.render
    @yuki.commandbox_all.render
  end

  def final
    @yuki.textbox_all.stop
    @yuki.commandbox_all.stop
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