#encoding: utf-8
#テキストボックス サンプル
#2009 Cyross Makoto

require 'Miyako/miyako'

include Miyako

TEXTBOX_MARGIN = 16

# pause用カーソルの用意
ws = Sprite.new(:file=>"../img/wait_cursor.png", :type=>:ac)
ws.oh = ws.ow
@ws = SpriteAnimation.new(:sprite=>ws, :wait=>0.2, :pattern_list=>[0,1,2,3,2,1])

# 選択用カーソルの用意
cs = Sprite.new(:file=>"../img/cursor.png", :type=>:ac)
cs.oh = cs.ow
@cs = SpriteAnimation.new(:sprite=>cs, :wait=>0.2, :pattern_list=>[0,1,2,3,2,1])

# フォントの用意
font = Font.sans_serif
font.color = Color[:white]
font.size = 16

# テキストボックスの用意
box = TextBox.new(:size=>[32,20], :wait_cursor => @ws, :select_cursor => @cs, :font => font)

# テキストボックス背景の用意
box_bg = Sprite.new(:size => box.size.to_a.map{|v| v + TEXTBOX_MARGIN}, :type => :ac)
box_bg.fill([128,0,64,128])

# Partsをまとめて一つのボックスにする
@parts = Parts.new(box.size)
@parts[:box_bg] = box_bg
@parts[:box] = box
@parts[:box_bg].centering!
@parts[:box].centering!
@parts.centering!

# 選択肢の作成
list = [
        ["選択肢１", "選択肢１", "選択肢１", true,  1],
        ["選択肢２", "選択肢２", "選択肢２", true,  2],
        ["選択肢３", "選択肢３", "選択肢３", true,  3],
        ["選択肢４", "選択肢４", "選択肢４", false, 4]
       ]
@choices = @parts[:box].create_choices_chain(list)
#@choices[0][1].visible = false
#@choices[0][2].enable = false

# カーソルのアニメーションの開始
@parts[:box].start

# 実行させる処理をテキストボックスに登録
@parts[:box].execute(@choices){|box, params|
  box.draw_text "やあ。"
  box.pause.cr

  box.draw_text "Miyakoのテキストボックスサンプルにようこそ。"
  box.pause.cr

  box.draw_text "ここでは、テキストボックスの機能をいくつか例示してみます。"
  box.pause.clear

  box.draw_text "まず、"
  box.pause.cr

  box.font_size_during(24){ box.draw_text "文字の大きさを変えます。" }
  box.pause.cr

  box.draw_text "変わりましたね？"
  box.pause.clear

  box.draw_text "次に、"
  box.pause.cr

  box.color_during(:blue){ box.draw_text "文字の色を変えてみます。" }
  box.pause.cr

  box.draw_text "変わりましたね？"
  box.pause.clear

  box.draw_text "続いて、"
  box.pause.cr

  box.font_size_during(24){
    box.color_during(:blue){
      box.draw_text "文字の大きさを変えながら"
      box.cr
      box.draw_text "色を変えてみます。"
    }
  }
  box.pause.cr

  box.draw_text "ほら、簡単でしょ？"
  box.pause.clear

  box.draw_text "文字の修飾も出来ます。"
  box.pause.cr

  box.font_bold{ box.draw_text "ボールド体でも" }
  box.pause.cr

  box.font_italic{ box.draw_text "イタリック体でも(フォントによって可・不可あるかも)" }
  box.pause.cr

  box.font_under_line{ box.draw_text "下線付きでも" }
  box.pause.cr

  box.draw_text "OKです"
  box.pause.clear

  box.draw_text "文字の位置を変更してみましょう。"
  box.pause.cr

  box.draw_text "一番左に表示しています"
  box.cr

  text = "真ん中に表示しています"
  # 文字列の長さ(ピクセル単位)を取得
  len = box.font.text_size(text)[0]
  # x座標の位置を変更
  box.locate.x = (box.size.w-len)/2
  box.draw_text text
  box.cr

  text = "右に表示しています"
  # 文字列の長さ(ピクセル単位)を取得
  len = box.font.text_size(text)[0]
  # x座標の位置を変更
  box.locate.x = (box.size.w-len)
  box.draw_text text
  box.cr

  text = "一番下の真ん中に表示しています"
  # 文字列の長さ(ピクセル単位)を取得
  len = box.font.text_size(text)
  # x座標の位置を変更
  box.locate.x = (box.size.w-len[0])/2
  box.locate.y = (box.size.h-len[1])
  box.draw_text text
  box.cr

  box.pause.clear

  box.draw_text "最後に、選択肢を表示させてみます"
  box.pause.cr

  # params[0] == @choices
  box.command params[0]

  box.draw_text "選択結果は#{box.result}ですね。"
  box.pause.cr.cr

  box.draw_text "だいたい、テキストボックスの使い方が"
  box.cr

  box.draw_text "おわかりになりましたでしょうか？"
  box.pause.cr

  box.draw_text "それでは、そろそろ失礼いたします・・・。"
  box.pause.cr
}

# テキストボックスのまとめ処理
def process_textbox
  @parts.update_animation
  @parts.render
end

Miyako.main_loop do
  break if Input.quit_or_escape? || !@parts[:box].execute?
  # テキストボックスはポーズ中？
  # ポーズ中はupdateを呼んではいけないので、ポーズ中は直前で回避している
  if @parts[:box].pause?
    # １ボタンを押したとき、ポーズを解除する
    @parts[:box].release if Input.pushed_any?(:btn1)
    process_textbox
    next
  end
  # テキストボックスはコマンド選択中？
  if @parts[:box].selecting?
    # カーソルの移動
    @parts[:box].move_cursor(*Input.pushed_amount)
    # １ボタンを押したとき、選択状態を解除する
    @parts[:box].finish_command if (Input.pushed_any?(:btn1) && @parts[:box].enable_choice?)
    process_textbox
    next
  end
  @parts[:box].update
  process_textbox
end