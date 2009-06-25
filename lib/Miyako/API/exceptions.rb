# -*- encoding: utf-8 -*-
=begin
--
Miyako v2.1
Copyright (C) 2007-2009  Cyross Makoto

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
++
=end

# 例外クラス群
module Miyako

  #==Miyakoの汎用例外クラス
  class MiyakoError < Exception
  end

  #==Miyakoの入出力例外クラス
  class MiyakoIOError < MiyakoError
    #===ファイルが見つからなかったときの例外を生成する
    #「ファイルが見つからない」というエラーメッセージを発する
    #例外インスタンスを生成する
    #_path_:: 見つからなかったファイルパス
    #返却値:: 生成した例外インスタンス
    def MiyakoIOError.no_file(path)
      MiyakoIOError.exception("Not found file: #{path}")
    end
  end

  #==Miyakoのファイル形式例外クラス
  class MiyakoFileFormatError < MiyakoIOError
    #===ファイルが見つからなかったときの例外を生成する
    #「ファイルが見つからない」というエラーメッセージを発する
    #例外インスタンスを生成する
    #_path_:: 見つからなかったファイルパス
    #返却値:: 生成した例外インスタンス
    def MiyakoIOError.illegal_file_foramt(path)
      MiyakoIOError.exception("Illegal file format.: #{path}")
    end
  end

  #==Miyakoの不正値クラス
  class MiyakoValueError < MiyakoError
    #===不正な値が使われたときの例外を生成する
    #「不正な値が使われました」というエラーメッセージを発する
    #例外インスタンスを生成する
    #_value_:: 使用した値
    #返却値:: 生成した例外インスタンス
    def MiyakoValueError.illegal_value(value)
      MiyakoValueError.exception("Illegal value: #{value}")
    end

    #===範囲外の値が設定されたときの例外を生成する
    #「範囲外の値が参照しました」というエラーメッセージを発する
    #例外インスタンスを生成する
    #_value_:: 使用した値
    #_min_:: 範囲の下限値
    #_max_:: 範囲の上限値
    #返却値:: 生成した例外インスタンス
    def MiyakoValueError.over_range(value, min, max)
      min = "" unless min
      max = "" unless max
      MiyakoValueError.exception("Out of range: #{value} (range: #{min}..#{max})")
    end
  end
  
  #==Proc、ブロック関連エラー(ブロックが渡っていない、など)
  class MiyakoProcError < MiyakoError

    #===ブロックが必要なときの例外を生成する
    #返却値:: 生成した例外インスタンス
    def MiyakoProcError.need_block
      MiyakoProcError.exception("This method needs block!")
    end
  end
  
  #==クラス関連エラー
  class MiyakoTypeError < MiyakoError
  end
  
  #==コピーエラー(複写時に起きる例外(複写禁止なのに複写した、など))
  class MiyakoCopyError < MiyakoError

    #===複製不可のインスタンスを複製したときの例外を生成する
    #「このインスタンスは複製できません」というエラーメッセージを発する
    #例外インスタンスを生成する
    #_class_name_:: 複製しようとした値のクラス名
    #返却値:: 生成した例外インスタンス
    def MiyakoCopyError.not_copy(class_name)
      MiyakoCopyError.exception("#{class_name} class instance cannot allow dup/clone!")
    end
  end
end
