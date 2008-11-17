class MainScene
  include Story::Scene
  include Yuki

  def init
    @cnt = 0
    @amt = 4
    @a = [0,0]
    @d = [0,1]

    @map = MapManager.new
    @size = @map.size
    @map.collision.pos = Point.new(@size[0] * 10, @size[1] * 10)
    @map.collision.amount = Size.new(@amt, @amt)

    # キャラクタの初期位置を指定([10,10]に位置)
    @chr = PChara.new("./chr1.png", @size)
    @chr.show

    # マップの表示開始位置を移動させる
    # キャラクタのグラフィックを真ん中に表示させるため
    @map.move(-@chr.x, -@chr.y, :view)
    # マップの実座標を設定する
    @map.move_to(*(@map.collision.pos.to_a))
    @map.show
    
    @parts = CommonParts.instance
    #Yukiの初期化
    init_yuki(@parts.box, @parts.cbox, :box)
  end

  def update
    return nil if Input.quit_or_escape?

    # 移動量が残っているときは移動を優先
    if @cnt > 0
      # 移動後のマップの実座標を計算
      @map.move(*@a)
      @cnt = @cnt - @amt
      return @now unless result_is_scene?
      return get_plot_result || @now
    end
    
    if plot_executing?
      update_plot_input
      return @now unless result_is_scene?
      return get_plot_result || @now
    end
    
    if Input::trigger_any?(:down, :up, :left, :right) # 0:down 1:left 2:right 3:up
      @d = Input::trigger_amount
      @d[1] = 0 if @d[0] != 0 && @d[1] != 0 # 移動を横方向優先に
      # コリジョンの移動量を設定
      @map.collision.direction = @d
      #キャラクタの向きを変更
      @chr.turn(@d)
      #マップの移動量を求める
      @a = @map.get_amount(0, @map.size, @map.collision).amount.to_a
      # 方向ボタンを押したときは、１チップサイズ単位で移動する
      # @cntはその移動量(幅と高さでサイズが違う場合アリ)
      @cnt = @a[0] > 0 ? @size[0] : @size[1]
      return @now unless result_is_scene?
      return get_plot_result || @now
    end

    #１ボタンを押したとき、イベントに重なっていればマップイベントを実行、
    #外れていれば、コマンドウィンドウを開く
    exec_plot(self.method(:command_plot)) if Input.pushed_any?(:btn1) && !(@map.events.inject(false){|s, e| s |= met_and_exec(e)})
    #コマンド選択の結果、イベントが実行されたときは、結果として@nowを返す
    return @now unless result_is_scene?
    return get_plot_result || @now
  end

  #マップ上のイベントとキャラクターが重なっていればイベントを実行
  def met_and_exec(event)
    return false unless event.met?({:collision=>@map.collision})
    event.execute(@parts)
    return true
  end

  def command_plot
      command([Command.new("話す", nil, scenario(:talk)),
               Command.new("調べる", nil, scenario(:check))])
      result.call if result_is_scenario?
      return @now
  end
  #コマンドウィンドウの「調べる」を選んだときの処理
  def check
    text "あなたは、足下を調べた。\n"
    pause
    text "しかし、何も無かった。"
    pause
    clear
  end
  
  #コマンドウィンドウの「話す」を選んだときの処理
  def talk
    text "話をしようとしたが"
    cr
    text "あなたの周りには誰もいない。"
    pause
    clear
  end
  
  def final
    @map.dispose
  end
end
