
SUBDIRS = installation

all:: test spec

test::  # Preloading tsc/launch.rb here as otherwise its tests fail somehow.
	@ruby -I${PATH} -rubygems -rtsc/launch -rtest/unit -e 'ARGV.each { |f| require f }' *.rb

test spec:: 
	@for f in $(SUBDIRS); do $(MAKE) -C $$f $@; done
