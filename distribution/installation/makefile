
SUBDIRS = tasks

all: test spec

test::
	@ruby -I${PATH} -I.:.. -rubygems -rtest/unit -e 'ARGV.each { |f| require f }' *.rb

test spec:: 
	@for f in $(SUBDIRS); do $(MAKE) -C $$f $@; done 

spec::
	@ls -1 SPECS/* | ruby -I${PATH} -I.:.. -rubygems -e 'load $$_.chomp, true while STDIN.gets' -- -rs
