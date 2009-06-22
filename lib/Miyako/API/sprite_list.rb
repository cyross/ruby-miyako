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

# �X�v���C�g�֘A�N���X�Q
module Miyako
  #==�����X�v���C�g�Ǘ�(���X�g)�N���X
  #�����̃X�v���C�g���A[���O,�C���X�^���X]�̈�Έ�̃��X�g�Ƃ��Ď����Ă����B
  #�l�̕��т̊�́A���O�̕��т�z��ɂ����Ƃ��̂���(SpriteList#values�̒l)�ɑΉ�����
  #Enumerable����mixin���ꂽ���\�b�h�AArray�EHash�N���X�Ŏg�p����Ă���ꕔ���\�b�h�A
  #swap�Ȃǂ̓Ǝ����\�b�h��ǉ����Ă���
  #(Enumerable����mixin���ꂽ���\�b�h�ł́A�u���b�N������[���O,�C���X�^���X]�̔z��Ƃ��ēn�����)
  #render�Arender_to��p�ӂ��A��C�ɕ`�悪�\�B
  #���O�͔z��Ƃ��ĊǗ����Ă���Brender���ɂ́A���O�̏��Ԃɕ`�悳���B
  #�e�v�f�̃��C�A�E�g�͊֗^���Ă��Ȃ�(������Parts�Ƃ̈Ⴂ)
  #�܂��A���̃N���X�C���X�^���X��dup�Aclone�̓f�B�[�v�R�s�[(�z��̗v�f������)�ƂȂ��Ă��邱�Ƃɒ��ӁB
  class SpriteList
    include SpriteBase
    include Animation
    include Enumerable

    attr_accessor :visible
    
    #===�n�b�V��������SpriteList�𐶐�����
    #�n�b�V���̃L�[���X�v���C�g���ɂ��Đ�������
    #_hash_:: �������̃n�b�V��
    #�ԋp�l:: ���������C���X�^���X
    def SpriteList.[](hash)
      body = SpriteList.new
      hash.each{|k, v| body.push(k ,v)}
    end
    
    #===�n�b�V��������SpriteList�𐶐�����
    #�������ȗ�����Ƌ��SpriteList�𐶐�����B
    #�v�f��[�X�v���C�g��,�X�v���C�g]�̔z��ƂȂ�z��������Ƃ��ēn�����Ƃ��ł���B
    #�n�b�V���������Ƃ��ēn���ƁA�L�[���X�v���C�g���Ƃ���SpriteList�𐶐�����B
    #_pairs_:: �������̃C���X�^���X
    #�ԋp�l:: ���������C���X�^���X
    def initialize(pairs = nil)
      @names = []
      @n2v   = {}
      if pairs.is_a?(Array)
        pairs.each{|pair|
          @names << pair[0]
          @n2v[pair[0]] = pair[1]
        }
      elsif pairs.is_a?(Hash)
        pairs.each{|key, value|
          @names << key
          @n2v[key] = value
        }
      end
      @visible = true
    end
    
    #===�����Ŏg�p���Ă���z��Ȃǂ�V�����C���X�^���X�ɒu��������
    #initialize_copy�p�Ō��E�V�C���X�^���X�Ŕz��Ȃǂ����p���Ă���ꍇ�ɑΉ�
    def reflesh
      @names = []
      @n2v = {}
    end
    
    def initialize_copy(obj) #:nodoc:
      reflesh
      obj.names.each{|name|
        self.push(name, obj[name].deep_dup)
      }
      @visible = obj.visible
    end
    
    #==nil��X�v���C�g�ȊO�̃C���X�^���X���폜����SpriteList�𐶐�����
    #�V����SpriteList���쐬���A�{�̂�nil��ASpriteBase��������SpritArray���W���[����mixin���Ă��Ȃ��΂��폜����B
    #�ԋp�l:: �V�������������C���X�^���X
    def sprite_only
      ret = self.dup
      ret.names.each{|name|
        ret.delete(name) if !ret[name].class.include?(SpriteBase) && !ret[name].class.include?(SpriteArray)
      }
      return ret
    end

    #==nil��X�v���C�g�ȊO�̃C���X�^���X��j��I�ɍ폜����
    #�������g����A�{�̂�nil��ASpriteBase��������SpritArray���W���[����mixin���Ă��Ȃ��΂��폜����B
    #�ԋp�l:: �������g���A��
    def sprite_only!
      @names.each{|name|
        if !@n2v[name].class.include?(SpriteBase) && !ret[name].class.include?(SpriteArray)
          @n2v.delete(name)
          @names.delete(name)
        end
      }
      return self
    end

    #==�u���b�N���󂯎��A���X�g�̊e�v�f�ɂ������ď������s��
    #�u���b�N�����ɂ́A|[�X�v���C�g��,�X�v���C�g�{��]|���n���Ă���
    #���O���o�^����Ă��鏇�ɓn���Ă���
    #�ԋp�l:: �������g���A��
    def each
      self.to_a.each{|pair| yield pair}
    end
    
    #==�u���b�N���󂯎��A�X�v���C�g�����X�g�̊e�v�f�ɂ������ď������s��
    #�u���b�N�����ɂ́A|�X�v���C�g��,�X�v���C�g�{��|���n���Ă���
    #���O���o�^����Ă��鏇�ɓn���Ă���
    #�ԋp�l:: �������g���A��
    def each_pair
      @names.each{|name| yield name, @n2v[name]}
    end
    
    #==�u���b�N���󂯎��A���O���X�g�̊e�v�f�ɂ������ď������s��
    #�u���b�N�����ɂ́A|�X�v���C�g��|���n���Ă���
    #���O���o�^����Ă��鏇�ɓn���Ă���
    #�ԋp�l:: �������g���A��
    def each_name
      @names.each{|name| yield name}
    end
    
    #==�u���b�N���󂯎��A�l���X�g�̊e�v�f�ɂ������ď������s��
    #�u���b�N�����ɂ́A|�X�v���C�g�{��|�̔z��Ƃ��ēn���Ă���
    #���O���o�^����Ă��鏇�ɓn���Ă���
    #�ԋp�l:: �������g���A��
    def each_value
      @names.each{|name| yield @n2v[name]}
    end
    
    #==�u���b�N���󂯎��A�z��C���f�b�N�X�ɂ������ď������s��
    #�u���b�N�����ɂ́A|�X�v���C�g���ɑΉ�����z��C���f�b�N�X|�̔z��Ƃ��ēn���Ă���
    #0,1,2,...�̏��ɓn���Ă���
    #�ԋp�l:: �������g���A��
    def each_index
      @names.length.times{|idx| yield idx}
    end
    
    #==�X�v���C�g���z����擾����
    #���O���o�^����Ă��鏇�ɓn���Ă���
    #�ԋp�l:: �X�v���C�g���z��
    def names
      @names
    end
    
    #==�X�v���C�g�z����擾����
    #���O���o�^����Ă��鏇�ɓn���Ă���
    #�ԋp�l:: �X�v���C�g�{�̔z��
    def values
      @names.map{|name| @n2v[name]}
    end
    
    #==���X�g������ۂ��ǂ����m���߂�
    #���X�g�ɉ����o�^����Ă��Ȃ����ǂ����m���߂�
    #�ԋp�l:: ����ۂ̎���true�A�Ȃɂ��o�^����Ă���Ƃ���false
    def empty?
      @names.empty?
    end

    def eql?(other)
      @names.eql?(other.names) && @n2v.values.eql?(other.values)
    end
    
    def has_name?(name)
      @n2v.has_key?(name)
    end
    
    def include?(name)
      @names.has_key?(name)
    end
    
    def has_value?(value)
      @n2v.has_value?(value)
    end

    def length
      @names.length
    end

    def size
      @names.size
    end

    def assoc(name)
      @n2v.assoc(name)
    end
    
    def rassoc(val)
      @n2v.rassoc(name)
    end
    
    def name(value)
      @n2v.key(value)
    end
    
    def index(name)
      @names.index(name)
    end
    
    def first(n=1)
      @names.length < n ? nil : @names.first(n).map{|name| [name, @n2v[name]]}
    end
    
    def last(n=1)
      @names.length < n ? nil : @names.last(n).map{|name| [name, @n2v[name]]}
    end
    
    def <<(pair)
      self.push(*pair)
    end
    
    def +(other)
      list = self.dup
      other.to_a.each{|pair| list.add(pair)}
      list
    end
    
    def *(other)
      list = SpriteList.new
      self.to_a.each{|pair| list.add(pair) if other.has_key?(pair[0])}
      list
    end
    
    def -(other)
      list = SpriteList.new
      self.to_a.each{|pair| list.add(pair) unless other.has_key?(pair[0])}
      list
    end
    
    def &(other)
      self * other
    end
    
    def |(other)
      self + other
    end
    
    def ==(other)
      self.eql?(other)
    end

    def add(pair)
      self.push(*pair)
    end
    
    def push(name, sprite)
      @names.delete(name) if @names.include?(name)
      @names << name
      @n2v[name] = sprite
      return self
    end

    def pop
      return nil if @names.empty?
      name = @names.pop
      [name, @n2v.delete(name)]
    end
    
    def unshift(name, sprite)
      @names.delete(name) if @names.include?(name)
      @names.unshift(name)
      @n2v[name] = sprite
      return self
    end
    
    def slice(*names)
      list = self.to_a
      names.map{|name| [name, @n2v[name]]}
    end
    
    def slice!(*names)
      self.delete_if!{|name, sprite| !names.include?(name)}
    end
    
    def shift(n = nil)
      return nil if @names.empty?
      if n
        names = @names.shift(n)
        return names.map{|name| [name, @n2v.delete(name)]}
      else
        name = @names.shift
        return [name, @n2v.delete(name)]
      end
    end

    def delete(name)
      return nil unless @names.include?(name)
      [@names.delete(name), @n2v.delete(name)]
    end

    def delete_at(idx)
      self.delete(@names[idx])
    end

    def delete_if
      ret = self.dup
      ret.each{|pair| ret.delete(pair[0]) if yield(*pair)}
      ret
    end

    def reject
      ret = self.dup
      ret.each{|pair| ret.delete(pair[0]) if yield(*pair)}
      ret
    end

    def delete_if!
      self.each{|pair| self.delete(pair[0]) if yield(*pair)}
      self
    end

    def reject!
      self.each{|pair| self.delete(pair[0]) if yield(*pair)}
      self
    end
    
    def compact
      ret.delete_if{|pair| pair[1].nil?}
    end

    def compact!
      ret.delete_if!{|pair| pair[1].nil?}
    end

    def concat(other)
      other.to_a.each{|pair| self.add(pair)}
    end
    
    def merge(other)
      ret = other.dup + self
      ret.names.each{|name| yield name, self[name], other[name] } if block_given?
      ret
    end
    
    def merge!(other)
      self.replace(other+self)
      self.names.each{|name| yield name, self[name], other[name] } if block_given?
      self
    end
    
    def cycle(&block)
      self.to_a.cycle(&block)
    end

    def shuffle
      self.to_a.shuffle
    end

    def sample(n=nil)
      n ? self.to_a.sample(n) : self.to_a.sample
    end

    def combination(n)
      self.to_a.combination(n)
    end

    def permutation(n, &block)
      self.to_a.permutation(n, &block)
    end
    
    private :reflesh
    
    def replace(other)
      self.clear
      other.to_a.each{|pair| self.add(*pair)}
      self
    end

    #===���O�̏��Ԃ𔽓]����
    #���O�̏��Ԃ𔽓]�����A�������g�̃R�s�[�𐶐�����
    #�ԋp�l:: ���O�𔽓]�������������g�̕�����Ԃ�
    def reverse
      ret = self.dup
      ret.reverse!
      return ret
    end
    
    #===���O�̏��Ԃ�j��I�ɔ��]����
    #�ԋp�l:: �������g���A��
    def reverse!
      @names.reverse!
      return self
    end
    
    def [](name)
      return @n2v[name]
    end

    def []=(name, sprite)
      return self.push(name, sprite) unless @names.include?(name)
      @n2v[name] = sprite
      return self
    end
    
    def sort(&block)
      @n2v.sort(&block)
    end
    
    def pairs_at(*names)
      names.map{|name| [name, @n2v[name]]}
    end
    
    def values_at(*names)
      names.map{|name| @n2v[name]}
    end
    
    def zip(*lists, &block)
      lists = lists.map{|list| list.to_a}
      self.to_a.zip(*lists, &block)
    end

    #===���X�g��z�񉻂���
    #�C���X�^���X�̓��e�����ɁA�z��𐶐�����B
    #�e�v�f�́A[�X�v���C�g��,�X�v���C�g�{��]�Ƃ����\���B
    #�ԋp�l:: ���������n�b�V��
    def to_a
      @names.map{|name| [name, @n2v[name]]}
    end
    
    #===�X�v���C�g���ƃX�v���C�g�{�̂Ƃ̃n�b�V�����擾����
    #�X�v���C�g���ƃX�v���C�g�{�̂��΂ɂȂ����n�b�V�����쐬���ĕԂ�
    #�ԋp�l:: ���������n�b�V��
    def to_hash
      @n2v.dup
    end
    
    #===���X�g�̒��g����������
    #���X�g�ɓo�^����Ă���X�v���C�g���E�X�v���C�g�{�̂ւ̓o�^����������
    def clear
      @names.clear
      @n2v.clear
    end
    
    #===�I�u�W�F�N�g���������
    def dispose
      @names.clear
      @names = nil
      @n2v.clear
      @n2v = nil
    end
    
    #===���O�ɑ΂��Ēl��n��
    #�d�l��Hash#fetch�Ɠ���
    def fetch(name, default = nil, &block)
      @n2v.fetch(name, default, &block)
    end
    
    #===�w��̖��O�̒��O�ɖ��O��}������
    #�z���ŁA�X�v���C�g���z��̎w��̖��O�̑O�ɂȂ�悤�ɖ��O��}������
    #_key_:: �}����̖��O�B���̖��O�̒��O�ɑ}������
    #_name_:: �}������X�v���C�g�̖��O
    #_value_:: (���O�����o�^�̎���)�X�v���C�g�{�̏ȗ�����nil
    #�ԋp�l�F�������g��Ԃ�
    def insert(key, name, value = nil)
      raise MiyakoValueError, "Illegal key! : #{key}" unless @names.include?(key)
      return self if key == name
      if value
        @n2v[name] = value 
      else
        raise MiyakoValueError, "name is not regist! : #{name}" unless @names.include?(name)
      end
      @names.delete(name) if @names.include?(name)
      @names.insert(@names.index(key), name)
      self
    end
    
    #===�w��̖��O�̒���ɖ��O��}������
    #�z���ŁA�X�v���C�g���z��̎w��̖��O�̎��̖��O�ɂȂ�悤�ɖ��O��}������
    #_key_:: �}����̖��O�B���̖��O�̒���ɑ}������
    #_name_:: �}������X�v���C�g�̖��O
    #_value_:: (���O�����o�^�̎���)�X�v���C�g�{�̏ȗ�����nil
    #�ԋp�l�F�������g��Ԃ�
    def insert_after(key, name, value = nil)
      raise MiyakoValueError, "Illegal key! : #{key}" unless @names.include?(key)
      return self if key == name
      if value
        @n2v[name] = value 
      else
        raise MiyakoValueError, "name is not regist! : #{name}" unless @names.include?(name)
      end
      @names.delete(name) if @names.include?(name)
      @names.insert(@parts_list.index(key)-@parts_list.length, name)
      self
    end
    
    #===�w�肵���v�f�̓��e�����ւ���
    #�z��̐擪���珇��render���\�b�h���Ăяo���B
    #�`�悷��C���X�^���X�́A�������[����render���\�b�h�������Ă�����̂̂�(�����Ă��Ȃ��Ƃ��͌Ăяo���Ȃ�)
    #_name1,name_:: ����ւ��Ώۂ̖��O
    #�ԋp�l:: �������g���A��
    def swap(name1, name2)
      raise MiyakoValueError, "Illegal name! : idx1:#{name1}" unless @names.include?(name1)
      raise MiyakoValueError, "Illegal name! : idx2:#{name2}" unless @names.include?(name2)
      idx1 = @names.index(name1)
      idx2 = @names.index(name2)
      @names[idx1], @names[idx2] = @names[idx2], @names[idx1]
      return self
    end
    
    #===�`���摜�̃A�j���[�V�������J�n����
    #�e�v�f��start���\�b�h���Ăяo��
    #�ԋp�l:: �������g��Ԃ�
    def start
      self.sprite_only.each{|pair| pair[1].start }
      return self
    end
    
    #===�`���摜�̃A�j���[�V�������~����
    #�e�v�f��stop���\�b�h���Ăяo��
    #�ԋp�l:: �������g��Ԃ�
    def stop
      self.sprite_only.each{|pair| pair[1].stop }
      return self
    end
    
    #===�`���摜�̃A�j���[�V������擪�p�^�[���ɖ߂�
    #�e�v�f��reset���\�b�h���Ăяo��
    #�ԋp�l:: �������g��Ԃ�
    def reset
      self.sprite_only.each{|pair| pair[1].reset }
      return self
    end
    
    #===�`���摜�̃A�j���[�V�������X�V����
    #�e�v�f��update_animation���\�b�h���Ăяo��
    #�ԋp�l:: �`���摜��update_sprite���\�b�h���Ăяo�������ʂ�z��ŕԂ�
    def update_animation
      self.sprite_only.map{|pair|
        pair[1].update_animation
      }
    end
    
    #===�z��̗v�f����ʂɕ`�悷��
    #�z��̐擪���珇��render���\�b�h���Ăяo���B
    #�`�悷��C���X�^���X�́A�������[����render���\�b�h�������Ă�����̂̂�(�����Ă��Ȃ��Ƃ��͌Ăяo���Ȃ�)
    #�ԋp�l:: �������g���A��
    def render
      return self unless @visible
      @names.each{|e|
        v = @n2v[e]
        next unless v.class.method_defined?(:render)
        v.render if (-1..0).include?(v.method(:render).arity)
      }
      return self
    end
    
    #===�z��̗v�f��Ώۂ̉摜�ɕ`�悷��
    #�z��̐擪���珇��render_to���\�b�h���Ăяo���B
    #�`�悷��C���X�^���X�́A�������P��render_to���\�b�h�������Ă�����̂̂�(�����Ă��Ȃ��Ƃ��͌Ăяo���Ȃ�)
    #_dst_:: �`��Ώۂ̉摜�C���X�^���X
    #�ԋp�l:: �������g���A��
    def render_to(dst)
      return self unless @visible
      @names.each{|e|
        v = @n2v[e]
        next unless v.class.method_defined?(:render_to)
        v.render_to(dst) if [-2,-1,1].include?(v.method(:render_to).arity)
      }
      return self
    end
    
    #===�I�u�W�F�N�g�𕶎���ɕϊ�����
    #��������A���O�ƃX�v���C�g�Ƃ̑΂̔z��ɕϊ����Ato_s���\�b�h�ŕ����񉻂���B
    #(��)[[name1, sprite1], [name2, sprite2],...]
    #�ԋp�l:: �ϊ�����������
    def to_s
      self.to_a.to_s
    end
  end
end
