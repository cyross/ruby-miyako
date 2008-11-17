*******************************************************************************
【   作者名   】　サイロス誠
【  ソフト名  】　Miyako v1.5サンプル(マップ移動)
【 バージョン 】　1.0.2
【   作成日   】　2008/06/06
【    種別    】　フリーウェア
【  開発言語  】　Ruby 1.8.6-p114
【 ランタイム 】　Miyako v1.5
【  対応機種  】　Windows 2000/XP/Vista、Linux
【   再配布   】　修正BSDライセンスによる
【    転載    】　修正BSDライセンスによる
【ホームページ】　http://www.twin.ne.jp/~cyross/Miyako/
【   連絡先   】　cyross@po.twin.ne.jp
*******************************************************************************

・概要

　このプログラムは、Miyako v1.5以降に対応する、Miyakoサンプルプログラムです。
　フィールドマップ上を移動します。
　ボタンを押すことで、道しるべ、街などに対するメッセージが表示されたり、
　コマンドが表示されるようになっています。

・Miyakoについて

　Miyakoに関しては、以下のURLを参考にしてください。
  (メインサイト)
  http://www.twin.ne.jp/~cyross/Miyako/
  (Wiki)
  http://wiki.fdiary.net/MiyakoDevSrc/

　Miyako(Ruby、Ruby/SDL含む)のインストールに関しましては、
上記URLを辿って得られるアーカイブされたMiyakoライブラリを
展開すると、readme.txtが得られますので、そちらをご参照下さい。

　本サンプルでは、MiyakoがWindows上で動作することを前提にしています。
（インストールしたRuby実行環境がActiveRubyであることも前提に
　しています）

・起動方法

　エクスプローラーを開き、本サンプルのフォルダ内で、「map_test.rb」を
ダブルクリックします。
　もしくは、コマンドライン上で動かす場合は、本サンプルのディレクトリに
移動して、以下のコマンドを入力します。

　ruby map_test.rb

・免責事項

　本サンプルは無保証です。もし本サンプルを使用することによる不具合・トラブル
が起こったとしても、いかなるトラブルに対する責任を負わないことをご了承下さい。

　本サンプルは、修正BSDライセンスに基づいた転載・再配布を許可します。

・修正履歴

　(1.0.1)
　・移動キーを押したときに、横方向を優先するように修正
　・斜め方向を押したときに、キャラクタが消える不具合を修正
　・コリジョンをMapManagerクラスに移動(マップ実座標の存在を強調)
　・スクリプトを複数ファイルに分割
　(1.0.2)
　・1.5RC3に対応

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
