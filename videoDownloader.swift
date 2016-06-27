#!/usr/bin/env xcrun swift

 /*
 © 2016 Paul Darcey
 
 */

import Foundation

enum Resolution {
	case HD, SD
}

// Default to get all HD videos from this year, no PDFs, and save to current directory
var resolution : Resolution = .HD
var getAll : Bool = true
var getVideo : Bool = true
var getPDF : Bool = false
var year : Int = 2016
var saveToDirectory : String = "" // TODO: set proper default
var sessionIDs : [String] = []
var message : String = ""

func processLaunchArguments() {
	// Processing launch arguments
	// http://ericasadun.com/2014/06/12/swift-at-the-command-line/
	let arguments = Process.arguments
	
	var i = 0

	for argument in arguments {
		i += 1
		if argument.hasPrefix("-") {   
			switch argument {
				case "-d":
					if i <= arguments.count {
						let saveToDirectory = arguments[i] as String
						message = message + "\nDownloading to directory: \(saveToDirectory)"
					} else {
						displaySyntaxError()
					}
	
				case "-a":
					getAll = true
					message = message + "\nGet all videos"

				case "-s":
					if i <= arguments.count {
						let sessions = arguments[i] as String
						sessionIDs = sessions.componentsSeparatedByString(",")
						getAll = false
						message = message + "\nDownloading for sessions: \(sessionIDs)"
					} else {
						displaySyntaxError()
					}
	
				case "-sd":
					resolution = .SD
					message = message + "\nGet SD resolution"
				
				case "-hd":
					resolution = .HD
					message = message + "\nGet HD resolution"
	
				case "-nopdf":
					getPDF = false
					message = message + "\nDon't get PDFs"
	
				case "-pdfonly":
					getPDF = true
					getVideo = false
					message = message + "\nOnly get PDFs"
	
				case "-y":
					if i <= arguments.count {
						let year = Int(arguments[i])
						message = message + "\nGet downloads from \(year)"

					} else {
						displaySyntaxError()
					}
		
				default:
					displaySyntaxError()
			}
		}
	}
	print(message)
}

func displaySyntaxError() {
	    print("videoDownloader")
        print("usage: videoDownloader.swift [-d directory] [-a] [-s SessionID1, SessionID2...] [-hd | -sd] [-pdf-only] [-nopdf] [-y Year]\n")
        print("usage: videoDownloader.swift [-d directory] [-a] [-s ] [-hd | -sd] [-pdf-only] [-nopdf] [-y Year]\n")
        exit(0)
}

func getDownloads() {

}

// Where the work is done

processLaunchArguments()
getDownloads()

