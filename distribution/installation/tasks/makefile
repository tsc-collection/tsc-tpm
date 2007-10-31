
SUBDIRS = 

all: test spec

test::
	@ruby -I${PATH} -I.:../.. -rubygems -rtest/unit -e 'ARGV.each { |f| require f }' *.rb

test:: 
	@for f in $(SUBDIRS); do $(MAKE) -C $$f test; done

spec::
