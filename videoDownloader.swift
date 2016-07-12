#!/usr/bin/env xcrun swift

/*
 Script to download all (or some) WWDC session videos, using Swift as a scripting language
 
 © 2016 Paul Darcey
 */

import Cocoa

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

extension Double {
    var percentage : String {
        get {
            let numberFormatter = NSNumberFormatter()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            numberFormatter.maximumSignificantDigits = 2
            return numberFormatter.stringFromNumber(self)!
        }
    }
}

extension Int64 {
    var iso : String {
        get {
            let units = [ "B", "kB", "MB", "GB", "TB" ]
            let magnitude = Int(log10(Double(self))/log10(1024))
            let numberFormatter = NSNumberFormatter()
            let number = Double(self)/pow(1024.0, Double(magnitude))
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            numberFormatter.maximumSignificantDigits = 2
            return "\(numberFormatter.stringFromNumber(number)!) \(units[magnitude])"
        }
    }
}

class Setup {
    // Set default values
    // Default to get all HD videos from this year, and save to current directory
    var resolution : Resolution = .hd
    var getAll : Bool = true
    var year : Int = 2016
    var saveToDirectory : String = "WWDCVideos"
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
                case "-d":										// Nominate the directory to save downloads to. Default is ~/WWDCVideos
                    if i <= arguments.count {
                        self.saveToDirectory = arguments[i] as String
                        self.message = self.message + "\nDownloading to directory: ~/\(self.saveToDirectory)"
                    } else {
                        displaySyntaxError()
                    }
                    
                case "-a":										// Get all sessions
                    self.userSetGetAll = true
                    if self.userSetSessionList {
                        displaySyntaxError("*** You have set both the -a and -s options. These are mutually exclusive ***")
                    } else {
                        self.getAll = true
                        self.message = self.message + "\nGet all videos"
                    }
                    
                case "-s":										// Nominate which sessions to download
                    self.userSetSessionList = true
                    if self.userSetGetAll {
                        displaySyntaxError("*** You have set both the -a and -s options. These are mutually exclusive ***")
                    } else {
                        if i <= arguments.count {
                            var sessions = ""
                            var j = i
                            while j < arguments.count && !arguments[j].hasPrefix("-") {
                                sessions = sessions + arguments[j] as String
                                j += 1
                            }
                            self.sessionIDs = sessions.componentsSeparatedByString(",")
                            self.getAll = false
                            self.message = self.message + "Downloading \(self.sessionIDs.count) sessions: \(self.sessionIDs)"
                        } else {
                            displaySyntaxError()
                        }
                    }
                    
                case "-sd":										// Get SD videos
                    self.resolution = .sd
                    self.message = self.message + "\nGet SD resolution"
                    
                case "-hd":										// Get HD videos
                    self.resolution = .hd
                    self.message = self.message + "\nGet HD resolution"
                    
                case "-y":										// Nominate the year
                    if i <= arguments.count {
                        self.year = Int(arguments[i])!
                        self.message = self.message + "\nGet downloads from \(self.year)"
                        
                    } else {
                        displaySyntaxError()
                    }
                    
                default:
                    displaySyntaxError()
                }
            }
        }
        print(self.message)
    }
}

extension Setup {
    func displaySyntaxError(additionalMessage: String? = nil) {
        print("usage: videoDownloader.swift [-d directory] [-a] [-s SessionID1, SessionID2...] [-hd | -sd] [-pdf-only] [-nopdf] [-y Year]\n")
        if let message = additionalMessage {
            print("\(message)\n")
        }
        print("OPTIONS\n")
        print("-d        A directory to download the videos to. By default, the download goes in WWDCVideos in the user's documents directory")
        print("-a        Download all the session videos (the default)")
        print("-s        A list of one or more session IDs, separated by commas (e.g -s 100, 101, 102 etc)")
        print("-hd | -sd Choose -hd for HD videos (the default) or -sd for SD videos")
        print("-y        The year to use. The default is 2016. Use a four-digit year")
        exit(0)
    }
}

struct Web {
    func validateURL(url : String) -> NSURL {
        guard let baseURL = NSURL(string: url)
            else {
                print("Error: \(url) doesn't seem to be a valid URL")
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
    
    func getListOfAllSessions(setup : Setup) -> [String] {
        let baseString = "https://developer.apple.com/videos/wwdc\(setup.year)/"
        let baseURL = validateURL(baseString)
        
        let htmlPage = getHTMLPage(baseURL)
        let regexString = "/videos/play/wwdc\(setup.year)/([0-9]*)/"
        
        let result = extract(regexString, from: htmlPage)
        print("Getting all \(result.count) sessions: \(result)")
        return result
    }
    
    func getDownloads(setup : Setup) {
        if setup.getAll {
            setup.sessionIDs = getListOfAllSessions(setup)
        }
        for session in setup.sessionIDs {
            let baseString = "https://developer.apple.com/videos/play/wwdc\(setup.year)/\(session)/"
            let baseURL = validateURL(baseString)
            
            let htmlPage = getHTMLPage(baseURL)
            let regexString = "<a\\ href=\\\"(.+)\\?dl=1\\\">\(setup.resolution.rawValue)\\ Video"
            let urlString = extract(regexString, from: htmlPage)
            let videoURL = validateURL(urlString[0])
            
            let fileLocation = setup.saveToDirectory
            
            _ = Downloader().download(videoURL, to: fileLocation)
        }
    }
}

extension Web {
    func extract(regularExpression: String, from text: String) -> [String] {
        var returnArray : [String] = []
        do {
            let regex = try NSRegularExpression(pattern: regularExpression, options: [])
            let matches = regex.matchesInString(text, options: [], range: NSMakeRange(0, text.characters.count))
            var matchingResults : [String] = []
            for match in matches {
                if !NSEqualRanges(match.range, NSMakeRange(NSNotFound, 0)) {
                    let captureGroup = match.rangeAtIndex(1)
                    let matchedRange = text.rangeFromNSRange(captureGroup)
                    let matchedString = text.substringWithRange(matchedRange!)
                    matchingResults.append(matchedString)
                }
            }
            
            let uniqueIDs = Array(Set(matchingResults))
            returnArray = uniqueIDs.sort { $0 < $1 }
            return returnArray
        } catch let error as NSError {
            print("Regex error: \(error.localizedDescription)")
        }
        return returnArray
    }
}

class Downloader : NSObject, NSURLSessionDownloadDelegate {
    var url : NSURL?
    var fileName : String?
    
    override init()
    {
        super.init()
    }
    
    // Download method
    func download(url: NSURL, to fileName: String) {
        self.url = url
        self.fileName = fileName
        
        let sessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(url.absoluteString)
        let session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.downloadTaskWithURL(url)
        task.resume()
    }
    
    // *** Delegate callbacks ***
    // Completion handler
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        //copy downloaded data to your documents directory with same names as source file
        let documentsURL =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let destination = documentsURL!.URLByAppendingPathComponent(fileName!)
        let destinationUrl = destination.URLByAppendingPathComponent(url!.lastPathComponent!)
        let dataFromURL = NSData(contentsOfURL: location)
        dataFromURL!.writeToURL(destinationUrl, atomically: true)
    }
    
    // Progress
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let percentage = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        print("Downloaded \(totalBytesWritten.iso) of \(totalBytesExpectedToWrite.iso) (\(percentage.percentage)%)")
    }
    
    // Error handling
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil) {
            //handle the error
            print("Download interrupted with error: \(error!.localizedDescription)");
        }
    }    
}

// MARK: Where the work is done
let app = Setup()
Web().getDownloads(app)

