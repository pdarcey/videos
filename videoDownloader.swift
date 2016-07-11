#!/usr/bin/env xcrun swift

/*
 Script to download all (or some) WWDC session videos, using Swift as a scripting language
 
 © 2016 Paul Darcey
 */

import Foundation

enum Resolution : String {
    case hd = "HD"
    case sd = "SD"
}

extension String {
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsRange.length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
            return from ..< to
        }
        return nil
    }
}

// Set default values
// Default to get all HD videos from this year, no PDFs, and save to current directory
var resolution : Resolution = .hd
var getAll : Bool = true
var getVideo : Bool = true
var getPDF : Bool = false
var year : Int = 2016
var saveToDirectory : String = "~/Downloads"
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
            case "-d":										// Nominate the directory to save downloads to. Default is ~/Downloads
                if i <= arguments.count {
                    let saveToDirectory = arguments[i] as String
                    message = message + "\nDownloading to directory: \(saveToDirectory)"
                } else {
                    displaySyntaxError()
                }
                
            case "-a":										// Get all sessions
                userSetGetAll = true
                if userSetSessionList {
                    displaySyntaxError("*** You have set both the -a and -s options. These are mutually exclusive ***")
                } else {
                    getAll = true
                    message = message + "\nGet all videos"
                }
                
            case "-s":										// Nominate which sessions to download
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
                
            case "-sd":										// Get SD videos
                resolution = .sd
                message = message + "\nGet SD resolution"
                
            case "-hd":										// Get HD videos
                resolution = .hd
                message = message + "\nGet HD resolution"
                
            case "-nopdf":									// Don't get the associated PDFs
                getPDF = false
                message = message + "\nDon't get PDFs"
                
            case "-pdfonly":								// Only download the PDFs (and not the videos)
                getPDF = true
                getVideo = false
                message = message + "\nOnly get PDFs"
                
            case "-y":										// Nominate the year
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

func validateURL(url : String) -> NSURL {
	guard let baseURL = NSURL(string: url)
	else {
		print("Error: \(baseString) doesn't seem to be a valid URL")
		exit(0)
	}
	return baseURL
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
	let baseURL = validateURL(baseString)
    
	let htmlPage = getHTMLPage(baseURL)
	let regexString = "/videos/play/wwdc\(year)/([0-9]*)/"
	
	return extractRegex(htmlPage, regexString)
    
}

// TODO: remove nsHTMLPage methods and replace with htmlPage functions
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

func downloadSession(downloadURL : NSURL, toURL : NSURL) {
        guard let dataFromURL = NSData(contentsOfURL: downloadURL)
        else {
            let error = NSError(domain:"Error downloading file", code:800, userInfo:nil)
            completion(path: destinationUrl.path!, error: error)
            return
        }
        
        if dataFromURL.writeToURL(toURL, atomically: true) {
            completion(path: destinationUrl.path!, error:nil)
        } else {
            let error = NSError(domain:"Error saving file", code:800, userInfo:nil)
            completion(path: destinationUrl.path!, error:error)
        }
}

func getDownloads() {
	if getAll {
		sessionIDs = getListOfAllSessions()
	}
	if getVideo {
		for session in sessionIDs {
			let baseString = "https://developer.apple.com/videos/play/wwdc\(year)/\(session)/"
			let baseURL = validateURL(baseString)
	
			let htmlPage = getHTMLPage(baseURL)
			let regexString = "<a\ href=\"(.+)\?dl=1\">\(resolution.RawValue) Video")
			let urlString = extractRegex(htmlPage, regexString)
			let downloadURL = validateURL(urlString)
			
			downloadSession(downloadURL)
		}
	}
}

// MARK: Where the work is done

processLaunchArguments()
getDownloads()

