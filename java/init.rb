# vim: set sw=2:

require 'java'

home = java.lang.System.getProperty("jruby.home")
lib = java.lang.System.getProperty("jruby.lib")

TSC_JRUBY_TOP = home

$:.replace $:.map { |_path|
  case
    when _path[0, lib.size] == lib
      [ _path[home.size.next..-1], _path ]

    when _path == '.'
      nil

    else _path
  end
}.flatten.compact

$:.concat [ lib, home, 'ruby' ]

require 'application/main'
exit 0
