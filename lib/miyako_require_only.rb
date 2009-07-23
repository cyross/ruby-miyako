# -*- encoding: utf-8 -*-
#
#=コンテンツ作成ライブラリMiyako2.1
#
#Authors:: サイロス誠
#Version:: 2.1.0
#Copyright:: 2007-2009 Cyross Makoto
#License:: LGPL2.1
#
=begin
Miyako v2.1
Copyright (C) 2007-2008  Cyross Makoto

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
=end

# 初期化を行わずにrequire 'Miyako/miyako'のみ行う

$miyako_auto_open = false

require 'Miyako/miyako'

$miyako_auto_open = nil
