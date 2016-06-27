#!/usr/bin/env xcrun swift

import Foundation

print("This is a swift script!")
print("Arguments: \(Process.arguments)")
displaySyntaxError


func displaySyntaxError() {
	    print("videoDownloader")
        print("usage: videoDownloader.swift [-d directory] [-a] [-s SessionID1, SessionID2...] [-hd | -sd] [-pdf-only] [-nopdf] [-y Year]\n")
        print("usage: videoDownloader.swift [-d directory] [-a] [-s ] [-hd | -sd] [-pdf-only] [-nopdf] [-y Year]\n")
        exit(0)
}
