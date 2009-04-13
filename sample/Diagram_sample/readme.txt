*******************************************************************************
【   作者名   】　サイロス誠
【  ソフト名  】　Miyako v2.0サンプル(遷移図形式)
【 バージョン 】　2.0
【   作成日   】　2009/04/13
【    種別    】　フリーウェア
【  開発言語  】　Ruby 1.9.1-p0
【 ランタイム 】　Miyako v2.0
【  対応機種  】　Windows 2000/XP/Vista、Linux
【   再配布   】　修正BSDライセンスによる
【    転載    】　修正BSDライセンスによる
【ホームページ】　http://www.twin.ne.jp/~cyross/Miyako/
【   連絡先   】　cyross@po.twin.ne.jp
*******************************************************************************

・概要

　このプログラムは、Miyako 2.0以降に対応する、Miyakoサンプルプログラムです。
　キャラクタの多重スクロールを行います(それだけですが・・・)

・Miyakoについて

　Miyakoに関しては、以下のURLを参考にしてください。
http://www.twin.ne.jp/~cyross/Miyako/

　Miyako(Ruby、Ruby/SDL含む)のインストールに関しましては、
上記URLを辿って得られるアーカイブされたMiyakoライブラリを
展開すると、readme.txtが得られますので、そちらをご参照下さい。

　本サンプルでは、MiyakoがWindows上で動作することを前提にしています。
（インストールしたRuby実行環境がActiveRubyであることも前提に
　しています）

・起動方法

　エクスプローラーを開き、本サンプルのフォルダ内で、「diagram_sample.rb」を
ダブルクリックします。
　もしくは、コマンドライン上で動かす場合は、本サンプルのディレクトリに
移動して、以下のコマンドを入力します。

　ruby diagram_sample.rb

・免責事項

　本サンプルは無保証です。もし本サンプルを使用することによる不具合・トラブル
が起こったとしても、いかなるトラブルに対する責任を負わないことをご了承下さい。

　本サンプルは、修正BSDライセンスに基づいた転載・再配布を許可します。

　また、本サンプルでは、背景画像に、背景画像素材集「凡界彩景」の教室画像を使用しています。
　http://naox.cool.ne.jp/bonkai1/

・更新履歴

　(1.1)
　・処理全体を一つの遷移図形式にまとめる(入れ子の遷移図ができるサンプル)
　・Yukiによるメッセージ表示を追加

　(1.2)
　・遷移図形式クラス名の修正

　(1.2.1)
　・RC3で追加したYuki::Yuki2クラス対応のdiagram_sample_yuki2.rbを追加

　(2.0)
　・Miyako2.0に対応

・BSDライセンス文

Copyright (c) 2008, Cyross Makoto

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

・Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
・Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
・Neither the name of the Cyross Makoto nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
