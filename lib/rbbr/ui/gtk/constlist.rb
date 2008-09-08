=begin

  rbbr/ui/gtk/constlist.rb 

  $Author: mutoh $
  $Date: 2004/01/10 18:30:16 $

  Copyright (C) 2002,2003 Ruby-GNOME2 Project

  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.
=end

module RBBR
module UI
module GTK
  class ConstantList < BrowseList
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def initialize
      super([_("Name"), _("Value")])
    end
    
    def update_list(modul)
      modul.constants_at.sort.each{|name|
        const = modul.const_get(name)
        if const.kind_of? GLib::Enum or const.kind_of? GLib::Flags
          if modul < GLib::Enum or modul < GLib::Flags
            append([name, const.nick])
          end
        else
          if const.class == Class
            if const < GLib::Enum or const < GLib::Flags
              iter = append([name, ""])
              modul.constants_at.sort.each{|child_name|
                child_const = modul.const_get(child_name)
                if child_const.kind_of? const
                  append([child_name, child_const.nick], iter)
                end
              }
              expand_row(iter.path, true)
            end
          elsif not const.is_a? Module
            append([name, const.inspect])
          end
        end
      }
    end

    def append(data, parent_iter = nil)
      iter = @model.append(parent_iter)
      data.each_index do |cnt|
        iter.set_value(cnt, data[cnt])
      end
      iter
    end

    def notify_selection(modul, iter)
      notify_observers(modul, [iter.get_value(0), '::'])
    end

    private
    def create_model(labels)
      Gtk::TreeStore.new(*labels.collect{|label| label.class})
    end
  end
    
end;end;end
