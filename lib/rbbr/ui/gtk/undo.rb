=begin

  rbbr/ui/gtk/undo.rb 

  $Author: mutoh $
  $Date: 2004/03/28 14:23:35 $

  Copyright (C) 2004 Ruby-GNOME2 Project

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK

  # Improved CareTaker. It's inclued by Originators.
  module Undoable
    @@undo = Array.new
    @@redo = Array.new
    @@observer = Array.new
    @undo_state = false

    #An Originator can set any object as a memento.
    def save_memento(memento)
      @@redo.clear
      @@undo.push([self, memento])
      @@observer.each do |obj|
	obj.update([self, memento])
      end
    end

    def add_undo_observer(obj)
      @@observer.push(obj)
    end

    def set_undo(val)
      @undo_state = val
    end

    def undo?
      @undo_state
    end

    def undoable?
      @@undo.size > 0
    end

    def redoable?
      @@redo.size > 0
    end

    #
    # for Overridden
    #

    # Return false if undo was fault and undo next. 
    def undo(data)
      $stderr.puts "#{self.class}#undo is not implemented yet"
      true
    end

    # Usually this is same as undo().
    def redo(data)
      undo(data)
    end

    def push_undo_data(data)
      @@undo.push(data)
    end
    def pop_undo_data
      @@undo.pop
    end
    def push_redo_data(data)
      @@redo.push(data)
    end
    def pop_redo_data
      @@redo.pop
    end
  end

  class UndoManager < GLib::Object
    include Undoable

    type_register

    signal_new("changed", GLib::Signal::ACTION,
               nil,
               GLib::Type["void"],
               GLib::Type["VALUE"], GLib::Type["VALUE"])    

    def initialize
      super()
      add_undo_observer(self)
    end

    def update(data = nil)
      signal_emit("changed", undoable?, redoable?)
    end
    
    def undo
      while ret = pop_undo_data
	ret[0].set_undo(true)
	push_redo_data(ret)
	if ret[0].undo(ret[1])
	  ret[0].set_undo(false)
	  break
	end
	ret[0].set_undo(false)
      end
      update
      self
    end

    def redo
      while ret = pop_redo_data
	ret[0].set_undo(true)
	push_undo_data(ret)
	if ret[0].redo(ret[1])
	  ret[0].set_undo(false)
	  break
	end
	ret[0].set_undo(false)
      end
      update
      self
    end
  end

end;end;end
