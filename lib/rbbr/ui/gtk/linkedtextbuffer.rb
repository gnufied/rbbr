=begin

  rbbr/ui/gtk/linkedtextbuffer.rb - 

  $Author: mutoh $
  $Date: 2004/01/14 18:18:44 $

  Copyright (C) 2004 Ruby-GNOME2 Project
  Copyright (C) 2003 Kenichi Komiya <kom@mail1.accsnet.ne.jp>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end
module RBBR
module UI
module GTK
  class LinkedTextBuffer < Gtk::TextBuffer
    attr_accessor :link_pattern

    def initialize(link_pattern=nil)
      super()
      @link_pattern = link_pattern
      create_tag("link", :underline => Pango::AttrUnderline::SINGLE)
    end

    def insert_linked(iter, text, *tags)
      split_text(text).each do |span|
	case span[0]
	when :plain
	  insert(iter, span[1], *tags)
	when :link
	  insert(iter, span[1], "link", *tags)
	else
	  STDERR.puts "unknown span type #{span[0].inspect}"
	  insert(iter, span[1], *tags)
	end
      end
      self
    end

    def get_link_at_iter(iter)
      link_tag = tag_table.lookup("link")
      tags = iter.tags
      return unless tags.include? link_tag
      link_start = iter
      unless link_start.begins_tag?(link_tag)
        link_start.backward_to_tag_toggle(link_tag)
      end
      link_end = link_start.dup
      link_end.forward_to_tag_toggle(link_tag)
      get_text(link_start, link_end)
    end

    private
    def split_text(text)
      return [[:plain, text]] if @link_pattern.nil?
      result = []
      text.split(@link_pattern).each do |span|
        unless span.empty?
          span_type = @link_pattern =~ span ? :link : :plain
          result << [span_type, span] 

        end
      end
      result
    end
  end
end;end;end
