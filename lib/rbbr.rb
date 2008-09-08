=begin

  rbbr.rb - Ruby Meta-Level Information Browser

  $Author: mutoh $
  $Date: 2004/03/25 14:47:28 $

  Copyright (C) 2002,2003 Ruby-GNOME2 Project
  Copyright (C) 2000-2001 Hiroshi Igarashi <iga@ruby-lang.org>

  This program is free software.
  You can distribute/modify this program under
  the terms of the Ruby Distribute License.

=end

begin
  require 'gettext'
rescue LoadError
  module GetText
    module_function 
    def _(str)
      str
    end
    def bindtextdomain(domainname, path = nil, locale = nil, charset = nil)
    end
  end
end


module RBBR
  VERSION = "0.6.0"
end

require 'rbbr/ui/gtk'
