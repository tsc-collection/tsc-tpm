@echo off
jruby.bat -e "script=File.join(File.dirname('%~f0'), 'distributor.rbx')" -e "eval(IO.readlines(script).join, binding, script, 1)" %*
