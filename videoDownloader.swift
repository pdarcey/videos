#!/usr/bin/env xcrun swift

 /*
 © 2016 Paul Darcey
 
 */

import Foundation

MARK: Launch Arguments
// Processing launch arguments
// http://ericasadun.com/2014/06/12/swift-at-the-command-line/

let arguments = Process.arguments as [String]
let dashedArguments = arguments.filter({$0.hasPrefix("-")})

for argument : NSString in dashedArguments {
    let key = argument.substringFromIndex(1)
    let value : AnyObject? = NSUserDefaults.standardUserDefaults().valueForKey(key)
    let valueString = value as? String
    // print("    \(argument) \(value)")
    
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


