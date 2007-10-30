
SUBDIRS = installation

all:: 
	@echo Nothing to make here. Try '"make test"' to run unit tests.

test::  # Preloading tsc/launch.rb here as otherwise its tests fail somehow.
	ruby -I${PATH} -rubygems -rtsc/launch -rtest/unit -e 'ARGV.each { |f| require f }' *.rb

test:: 
	@for f in $(SUBDIRS); do $(MAKE) -C $$f test; done
