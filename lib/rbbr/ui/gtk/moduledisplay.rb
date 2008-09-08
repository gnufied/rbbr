=begin

  rbbr/ui/gtk/moduledisplay.rb 

  $Author: mutoh $
  $Date: 2004/01/28 17:42:57 $

  Copyright (C) 2002-2004 Ruby-GNOME2 Project

  Copyright (C) 2000-2002 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

module RBBR
module UI
module GTK

  class ModuleDisplay < Gtk::VPaned
    type_register

    include GetText
    include Undoable

    GetText.bindtextdomain("rbbr", nil, nil, "UTF-8")  

    attr_reader :docviewer, :notebook, :module_label

    def initialize(database, conf)
      super()

      @database = database
      @conf = conf

      @conf["moduledisplay.position"] ||= 200

      @docviewer = DocViewer.new(database)

      # create display paned
      @display_box = Gtk::VBox.new(false, 0)

      # create module label
      @module_label = ModuleLabel.new(database)
      @display_box.pack_start(@module_label, false, true, 2)

      # create notebook
      @notebook = Gtk::Notebook.new
      @notebook.set_tab_pos(Gtk::POS_TOP)
      @notebook.set_scrollable(true)
      @notebook.set_homogeneous(false)
      @notebook.set_show_tabs(true)
      @display_box.pack_start(@notebook, true, true, 0)

      # create lists
      @lists = [ 
        [MethodList.new, _("Methods")],
        [ConstantList.new, _("Constants")],
        [SignalList.new, _("Signals")],
        [PropertyList.new, _("Properties")],
        [ChildPropertyList.new, _("Child Properties")],
      ]

      @lists << [StyleList.new, _("Styles")] unless Gtk.check_version(2, 2, 0)

      @lists.each_with_index do |(list, label), index|
        scwin = Gtk::ScrolledWindow.new
        scwin.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)
        scwin.add(list)
        @notebook.append_page(scwin, Gtk::Label.new(label))
        list.signal_connect("unselect-all") do 
	  @docviewer.update(@name_space)
	end
        list.add_observer(@docviewer)
      end

      #main pane
      @mainpane = Gtk::ScrolledWindow.new 
      @mainpane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC)

      @mainpane.add(@docviewer)

      add1(@display_box)
      add2(@mainpane)

      set_position(@conf["moduledisplay.position"])
      @notebook.show_all
      @docviewer.show_all

      @first = :first
      @notebook.signal_connect("switch-page") do |notebook, page, pagenum|
	unless undo?
	  if @first == :first
	    @first = :second
	  else
	    if @first == :second
	      @first = nil
	      save_memento([:switch, 0])
	    end
	    save_memento([:switch, pagenum])
	  end
	end
      end

      @docviewer.signal_connect("link_clicked") do |w, text|
	search(*parse_target(text))
      end
      @module_label.signal_connect("link_clicked") do |w, text|
	search(*parse_target(text))
      end
    end

    def search(name_space, method_name, page)
      update(name_space) if name_space
      search_method(method_name) if method_name
    end

    def undo(data)
      undo_type = data[0]
      page = data[1]
      if undo_type == :switch
	if @notebook.page == page
	  false
	else
	  @notebook.page = page
	  true
	end
      else
	name_space = data[2]
	method_name = data[3]
	@notebook.page = page if page
	update(name_space) if name_space
	search_method(method_name) if method_name
	true
      end
    end

    def parse_target(text)
      modules = RBBR::MetaInfo.module_names
      case text
      when /(.*)\#(.*)/
	name_space, method_name = $1, $2
	klass = eval(name_space)
	return [nil, nil, nil] unless modules.include? name_space
	methods = klass.instance_methods + klass.private_instance_methods + 
	  klass.protected_instance_methods
	return [nil, nil, nil] unless methods.include? method_name
	return [klass, "^" + method_name + "$", 0]
      when /(.*)\.(.*)/
	name_space, method_name = $1, $2
	klass = eval(name_space)
	return [nil, nil, nil] unless modules.include? name_space
	return [nil, nil, nil] unless klass.methods.include? method_name
	return [klass, "^" + method_name + "$", 0]
      when /(.*)::(.*)/
	return [eval(text), nil, nil] if modules.include? text
	name_space, const_name = $1, $2
	klass = eval(name_space)
	return [nil, nil, nil] unless modules.include? name_space
	return [nil, nil, nil] unless klass.constants.include? const_name
	return [klass, "^" + const_name + "$", 1]
      else
	if modules.include? text
	  return [eval(text), nil, nil]
	else
	  if Object.constants.include? text
	    return [Object, "^" + const_name + "$", 1]
	  else
	    [nil, nil, nil]
	  end
	end
      end
      [nil, nil, nil]
    rescue NameError
      # never reach here
      STDERR.puts "*warning*:#{self.name}.parse_target(): `#{text}' caused NameError"
      p $!
      [nil, nil, nil]
    end

    def update(*args)
      @name_space = args[0]
      @module_label.update(*args)
      @lists.each do |list, label|
        list.update(*args)
      end
      @docviewer.update(*args)
    end

    def search_method(method_name, page = nil)
      save_memento([:search, @notebook.page, @name_space, @lists[@notebook.page][0].selected])
      @notebook.page = page if page
      @lists[@notebook.page][0].search(method_name)
    end

    def save_conf
      @conf["moduledisplay.position"] = position
    end
  end
end;end;end
