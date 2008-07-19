
puts "MAIN"

puts "H: #{java.lang.System.getProperty('jruby.home').inspect}"
puts "L: #{java.lang.System.getProperty('jruby.lib').inspect}"
puts "A: #{ARGV.inspect}"

puts *$:
