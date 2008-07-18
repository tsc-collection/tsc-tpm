
package com.tsc.jruby;

public class Launcher {
    public static void main(final String[] args) {
        com.tsc.jruby.Locator locator = new com.tsc.jruby.Locator();
        String top = (new java.io.File(locator.figureJar())).getParentFile().getParent();

        System.setProperty("jruby.home", top);
        System.setProperty("jruby.lib", top + '/' + "lib");

        java.util.ArrayList<String> arguments = new java.util.ArrayList<String>();
        arguments.add("-e");
        arguments.add("require 'ruby/init'");
        arguments.addAll(java.util.Arrays.asList(args));

        org.jruby.Main.main(arguments.toArray(new String[0]));
    }
}
