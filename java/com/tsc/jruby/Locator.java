/*  Copyright (c) 2008, Gennady Bystritsky <bystr@mac.com>
 *  
 *  Distributed under the MIT Licence.
 *  This is free software. See 'LICENSE' for details.
 *  You must read and accept the license prior to use.
 *  
 *  Author: Gennady Bystritsky (gennady.bystritsky@quest.com)
*/

package com.tsc.jruby;

public class Locator {
    public String figureJar() {
        String origin = figureOrigin();
        String header = "jar:file:";

        if(origin != null) {
            if(origin.startsWith(header)) {
                int tail = origin.indexOf('!', header.length());
                if(tail != -1) {
                    return origin.substring(header.length(), tail);
                }
            }
        }
        throw new IllegalStateException(figureResource() + ": not from a jar");
    }

    public String figureResource() {
        return getClass().getName().replace('.', '/') + ".class";
    }
    
    public String figureOrigin() {
        java.net.URL url = getClass().getClassLoader().getResource(figureResource());
        return unescape(url.toString());
    }

    private String unescape(final String path) {
        try {
            return java.net.URLDecoder.decode(path.toString(), System.getProperty("file.encoding"));
        }
        catch(java.io.UnsupportedEncodingException exception) {
            return path;
        }
    }
}
