# -*- encoding: utf-8 -*-
class MainScene
  include Story::Scene

  def init
    @cnt = 0
    @amt = 4
    @a = [0,0]
    @d = [0,1]

    @map = MapManager.new
    @size = @map.size
    @map.collision.amount.resize(@amt, @amt)
    @executing_flags = Array.new(@map.events.length){|n| false}

    # キャラクタの初期位置を指定([10,10]に位置)
    @chr = PChara.new("./chr1.png", @size)

    # マップの表示開始位置を移動させる
    # キャラクタのグラフィックを真ん中に表示させるため
    @map.margin.resize(*@chr.margin)
    @map.sync_margin
    # マップの実座標を設定する
    @map.move(@size[0] * 10, @size[1] * 10)
    
    @parts = CommonParts.instance
    #Yukiの初期化
    @yuki = Yuki.new
    @yuki.select_textbox(@parts.box[:box])
    @yuki.select_commandbox(@parts.cbox[:box])
  end
  
  def setup
    @map.start
    @chr.start
    @parts.start
  end

  def update
    return nil if Input.quit_or_escape?

    @parts.update_animation
    @map.update
    @chr.update

    # 移動量が残っているときは移動を優先
    if @cnt > 0
      # 移動後のマップの実座標を計算
      @map.move(*@a)
      @cnt = @cnt - @amt
    elsif @yuki.executing?
      @yuki.update
    elsif @executing_flags.none?
      if Input.pushed_any?(:btn1) || Input.click?(:left)
        #１ボタンを押したとき、イベントに重なっていればマップイベントを実行、
        #外れていれば、コマンドウィンドウを開く
        event_flags = @map.events.map{|e| e.met?(:collision => @map.collision)}
        if event_flags.none?
          @yuki.vars[:now] = @now
          @yuki.vars[:talk] = talk
          @yuki.vars[:check] = check
          @yuki.start_plot(command_plot)
        else
          @map.events.zip(event_flags){|ef| ef[0].start(@parts) if ef[1]}
        end
      elsif Input::trigger_any?(:down, :up, :left, :right)
            # 0:down 1:left 2:right 3:up
        @d = Input::trigger_amount
        @d[1] = 0 if @d[0] != 0 && @d[1] != 0 # 移動を横方向優先に
        # コリジョンの移動量を設定
        @map.collision.direction.move_to(*@d)
        #キャラクタの向きを変更
        @chr.turn(@d)
        #マップの移動量を求める
        @a = @map.get_amount(1, 0, @map.size, @map.collision).amount.to_a
        # 方向ボタンを押したときは、１チップサイズ単位で移動する
        # @cntはその移動量(幅と高さでサイズが違う場合アリ)
        @cnt = @a[0] > 0 ? @size[0] : @size[1]
      end
    else
    end

    @map.events.zip(@executing_flags){|ef|
      if ef[1]
        if Input.pushed_any?(:btn2)
          ef[0].stop
        else
          ef[0].update(nil, nil, nil)
        end
      end
    }
    @executing_flags = @map.events.map{|e| e.executing? }
   
    #コマンド選択の結果、イベントが実行されたときは、結果として@nowを返す
    return @now unless @yuki.is_scene?(@yuki.result)
    return @yuki.result || @now
  end

  def render
    @map.render
    @map.render_event
    @chr.render
    @map.render_event_box
    if @yuki.executing?
      @parts.box.render
      @parts.cbox.render if @yuki.selecting?
    end
  end

  def command_plot
    yuki_plot do
      command([Yuki::Command.new("話す", "話す", nil, vars[:talk]),
               Yuki::Command.new("調べる", "調べる", nil, vars[:check])], vars[:now])
      call_plot(select_result) if is_scenario?(select_result)
      vars[:now]
    end
  end
  #コマンドウィンドウの「調べる」を選んだときの処理
  def check
    yuki_plot do
      text "あなたは、足下を調べた。"
      pause
      text "しかし、何も無かった。"
      pause
      clear
    end
  end
  
  #コマンドウィンドウの「話す」を選んだときの処理
  def talk
    yuki_plot do
      text "話をしようとしたが"
      cr
      text "あなたの周りには誰もいない。"
      pause
      clear
    end
  end
  
  def final
    @parts.stop
    @map.stop
    @chr.stop
  end
  
  def dispose
    @map.dispose
    @chr.dispose
  end
end
