#!/usr/bin/env xcrun swift

 /*
 © 2016 Paul Darcey
 
 */

import Foundation

enum Resolution {
	case HD, SD
}

// Set default values
// Default to get all HD videos from this year, no PDFs, and save to current directory
var resolution : Resolution = .HD
var getAll : Bool = true
var getVideo : Bool = true
var getPDF : Bool = false
var year : Int = 2016
var saveToDirectory : String = "" // TODO: set proper default
var sessionIDs : [String] = []
var message : String = ""
var userSetGetAll = false
var userSetSessionList = false


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
					userSetGetAll = true
					if userSetSessionList {
						displaySyntaxError("*** You have set both the -a and -s options. These are mutually exclusive ***")
					} else {
						getAll = true
						message = message + "\nGet all videos"
					}

				case "-s":
					userSetSessionList = true
					if userSetGetAll {
						displaySyntaxError("*** You have set both the -a and -s options. These are mutually exclusive ***")
					} else {
						if i <= arguments.count {
							var sessions = ""
							var j = i
							while j < arguments.count && !arguments[j].hasPrefix("-") {
								sessions = sessions + arguments[j] as String
								j += 1
							}
							sessionIDs = sessions.componentsSeparatedByString(",")
							getAll = false
							message = message + "Downloading \(sessionIDs.count) sessions: \(sessionIDs)"
						} else {
							displaySyntaxError()
						}
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

func displaySyntaxError(additionalMessage: String? = nil) {
        print("usage: videoDownloader.swift [-d directory] [-a] [-s SessionID1, SessionID2...] [-hd | -sd] [-pdf-only] [-nopdf] [-y Year]\n")
        if let message = additionalMessage {
        	print("\(message)\n")
        }
        print("OPTIONS\n")
        print("-d        A directory to download the videos to. By default, the download goes in the current working directory")
        print("-a        Download all the session videos (the default)")
        print("-s        A list of one or more session IDs, separated by commas (e.g -s 100, 101, 102 etc)")
        print("-hd | -sd Choose -hd for HD videos (the default) or -sd for SD videos")
        print("-pdf-only Only get PDFs, i.e. do not download the videos")
        print("-nopdf    Do not download the related PDFs")
        print("-y        The year to use. The default is 2016. Use a four-digit year")
        exit(0)
}

func getHTMLPage(url: NSURL) -> String {
    do {
        let rawHTML = try String(contentsOfURL: url)
        
        return rawHTML
    } catch let error as NSError {
        print("Error: \(error)")
        exit(0)
    }
}

func getListOfAllSessions() -> Array {
	let baseString = "https://developer.apple.com/videos/wwdc\(year)/"
	guard let baseURL = NSURL(string: baseString)
	else {
		print("Error: \(baseString) doesn't seem to be a valid URL")
		exit(0)
    }
    
	let htmlPage = getHTMLPage(baseURL)
	let regexString = "/videos/play/wwdc\(year)/([0-9]*)/"
	
	return extractRegex(htmlPage, regexString)
    
}


func extractRegex(htmlPage : String, regexString : String) -> Array {
    do {
		let regex = try NSRegularExpression(pattern: regexString, options: [])
		let nsHTMLPage = htmlPage as NSString
		let results = regex.matchesInString(htmlPage, options: [], range: NSMakeRange(0, nsHTMLPage.length))
		var sessionArray : [String] = []
        for result in results {
			let matchedRange = result.rangeAtIndex(1)
			let matchedString = nsHTMLPage.substringWithRange(matchedRange)
			sessionArray.append(matchedString)
       }
        
        let uniqueIDs = Array(Set(sessionArray))
        return uniqueIDs.sort { $0 < $1 }
        print("Getting all \(sessionIDs.count) sessions: \(sessionIDs)")
    } catch let error as NSError {
        print("Regex error: \(error.localizedDescription)")
    }
}

func downloadSession(downloadURL : String) {

}

func getDownloads() {
	if getAll {
		sessionIDs = getListOfAllSessions()
	}
	if getVideo {
		for session in sessionIDs {
			let baseString = "https://developer.apple.com/videos/play/wwdc\(year)/\(session)/"
			guard let baseURL = NSURL(string: baseString)
			else {
				print("Error: \(baseString) doesn't seem to be a valid URL")
				exit(0)
			}
	
			let htmlPage = getHTMLPage(baseURL)
			let regexString = "<a\ href=\"(.+)\?dl=1\">\(resolution.RawValue) Video")
			let downloadURL = extractRegex(htmlPage, regexString)
			
			downloadSession(downloadURL)
		}
	}
}

// Where the work is done

processLaunchArguments()
getDownloads()

