=begin

  rbbr/ui/gtk/browselist.rb 

  $Author: mutoh $
  $Date: 2004/03/28 14:23:35 $

  Copyright (C) 2002-2004 Ruby-GNOME2 Project

  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK
  class MethodList < BrowseList
    include Observable
    include GetText
    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")

    def initialize
      super([_("Name")])
    end

    private
    def create_model(labels)
      Gtk::TreeStore.new(String, String, Integer, String)
    end

    def create_column(label, renderer, cnt)
      Gtk::TreeViewColumn.new(label, renderer, 
			      :text => cnt, :foreground => 3)
    end

    public
    def update(modul)
      freeze_notify
      @model.clear

      pmethods = modul.private_instance_methods(false)
      smethods = singleton_methods(modul) 
      smethods -= singleton_methods(modul.superclass) if modul.kind_of? Class
      unless modul == Object
        if pmethods.reject!{|val| val == "initialize"}
          smethods << "new" unless smethods.include? "new"
        end
      end

      create_children(_("Class Methods / Module Functions"), smethods, ".") do |name|
        if name == "new" 
	  #Foo.new returns -1 usually. So we use "initialize" method arity instead.
          if modul.instance_methods(true).include? "initialize"
            modul.instance_method("initialize").arity
          elsif modul.kind_of?(Class)
	    modul.method("new").arity
	  else
            #Do nothing. This may be a bug of the selected class.
            0
          end
        else
          modul.method(name).arity
        end
      end

      create_children(_("Public Instance Methods"), 
                      modul.public_instance_methods(false)) do |name|
        modul.instance_method(name).arity
      end
      create_children(_("Protected Instance Methods"), 
                      modul.protected_instance_methods(false)) do |name|
        modul.instance_method(name).arity
      end
      create_children(_("Private Instance Methods"), pmethods) do |name|
        modul.instance_method(name).arity
      end
      thaw_notify
      @modul = modul
    end

    def create_children(title, methods, type = "#")
      return if methods.size == 0
      iter = append(nil, title)
      iter[3] = "darkblue"
      methods.sort.each do |name|
        append(iter, name, type, yield(name))
      end
      expand_row(iter.path, false)
    end
   

    def append(parent_iter, name, ptype = "", argnum = 0)
      iter = @model.append(parent_iter)
      iter[0] = name
      iter[1] = ptype
      iter[2] = argnum
      iter
    end
    
    def notify_selection(modul, iter)
      ptype = iter[1]
      args = []
      if ptype.size > 0
        method_name = iter[0]

        argnum = iter[2]
        if argnum > 1
          (0...argnum).each do |i|
            args << "arg#{i + 1}"
          end
        elsif argnum == 1
          args = ["arg"]
        elsif argnum < 0
          args = ["..."]
        end
        spec = [method_name, ptype]
      else
        modul, spec = nil, nil
      end
      notify_observers(modul, spec, args)
    end

    def singleton_methods(modul)
      if RUBY_VERSION < "1.8.0"
        modul.singleton_methods
      else
        modul.singleton_methods(false) 
      end
    end
  end
end;end;end
