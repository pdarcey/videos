#!/usr/bin/env xcrun swift

 /*
 © 2016 Paul Darcey
 
 */

import Foundation

setDefaults()
processLaunchArguments()
getDownloads()

func setDefaults {
	// Default to get all HD videos from this year, no PDFs, and save to current directory
	var resolution = .HD
	var getAll = true
	var getVideo = true
	var getPDF = false
	var year = 2016
	var saveToDirectory = "" // TODO: set proper default
}

func processLaunchArguments() {
	// MARK: Launch Arguments
	// Processing launch arguments
	// http://ericasadun.com/2014/06/12/swift-at-the-command-line/
	let arguments = Process.arguments

	for argument in arguments {    
		switch argument {
			case "-d":
				if let directory = valueString {
					directoryToSaveTo = directory
				}
	
			case "-f" where valueString == "HD":
				resolution = .HD
	
			case "--nopdf":
				getPDF = false
	
			case "--pdfonly":
				getPDF = true
				getVideo = false
	
			case "-a":
				getAll = true

			case "-s"
				sessionIDs = (valueString?.componentsSeparatedByString(","))!
				getAll = false
				print("Downloading for sessions: \(sessionIds)")
	
			case "-y":
				if let yearString = valueString {
					year = yearString
				}
		
			default:
				displaySyntaxError()
		}
	}
}

func displaySyntaxError() {
	    print("videoDownloader")
        print("usage: videoDownloader.swift [-d directory] [-a] [-s ] [-pdf-only] [-help]\n")
        exit(0)
}

