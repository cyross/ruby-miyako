# -*- encoding: utf-8 -*-
# テキスト表示・高橋メソッド形式サンプル
# 2009.4.12 Cyross Makoto

require 'Miyako/miyako'

include Miyako

# 高橋メソッド形式文字列の表示
shape1 = Shape.takahashi(:font=>Font.serif, :align=>:center, :valign=>:bottom, :size=>Screen.size){|v|
          size(20){ text "えーびーしー" }
					cr
					text "ABC"
					cr
					under_line{"でー"} . text("えーえふじー")
					cr
					text("DEFG")
        }

# 通常形式で表示
shape2 = Shape.text(:font=>Font.serif, :align=>:right){|v|
          size(24){
            text "えー"
            color(:yellow){ "びー" }
            text "しー"
          }
					cr
					text "ABC"
					cr
					under_line{"でー"} . text("えーえふじー")
					cr
					text("DEFG")
        }

# 自動描画配列にshape1、shape2を組み込み
Screen.auto_render_array << shape1
Screen.auto_render_array << shape2

Miyako.main_loop do
	break if Input.quit_or_escape?
  Drawing.fill(Screen, [100,100,100])
end
