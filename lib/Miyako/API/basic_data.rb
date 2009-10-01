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

#=begin rdoc
#==１個のインスタンスでイテレータを実装できるモジュール
#=end
module SingleEnumerable
  include Enumerable

  #===ブロックの処理を実行する
  #返却値:: 自分自身を返す
  def each
    yield self
    return self
  end

  #===sizeメソッドと同様
  #返却値:: sizeメソッドと同様
  def length
    return 1
  end
end
