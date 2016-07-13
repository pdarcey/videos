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

extension Double {
    // Based on a solution at http://stackoverflow.com/questions/24102814/how-to-use-println-in-swift-to-format-number by Daniel Howard
    var percentage : String {
        get {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            numberFormatter.maximumSignificantDigits = 3
            numberFormatter.minimumSignificantDigits = 3
            
            return numberFormatter.string(from: self)!
        }
    }
}

extension Int64 {
    // Based on a solution at http://stackoverflow.com/questions/3263892/format-file-size-as-mb-gb-etc?noredirect=1&lq=1 by Willem Van Onsem
    var iso : String {
        get {
            let units = [ "B", "kB", "MB", "GB", "TB" ]
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            numberFormatter.maximumSignificantDigits = 3
            numberFormatter.minimumSignificantDigits = 3
            
            let magnitude = Int(log10(Double(self))/log10(1024))
            let number = Double(self) / pow(1024.0, Double(magnitude))
            
            return "\(numberFormatter.string(from: number)!) \(units[magnitude])"
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
                            self.sessionIDs = sessions.components(separatedBy: ",")
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
    func displaySyntaxError(_ additionalMessage: String? = nil) {
        print("usage: videoDownloader.swift [-d directory] [-a] [-s SessionID1, SessionID2...] [-hd | -sd] [-y Year]\n")
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
    func validateURL(_ url : String) -> URL {
        guard let baseURL = URL(string: url)
            else {
                print("Error: \(url) doesn't seem to be a valid URL")
                exit(0)
        }
        
        return baseURL
    }
    
    func getHTML(_ url: URL) -> String {
        do {
            let rawHTML = try String(contentsOf: url, encoding: .utf8)
            
            return rawHTML
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
            exit(0)
        }
    }
    
    func getListOfAllSessions(_ setup : Setup) -> [String] {
        let urlName = "https://developer.apple.com/videos/wwdc\(setup.year)/"
        let url = validateURL(urlName)
        
        let html = getHTML(url)
        let regex = "/videos/play/wwdc\(setup.year)/([0-9]*)/"
        
        do {
            let result = try extract(regex, from: html)
            
            return result
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
            exit(0)
        }
    }
    
    func getDownloads(_ setup : Setup) {
        if setup.getAll {
            setup.sessionIDs = getListOfAllSessions(setup)
        }
        for session in setup.sessionIDs {
            let urlName = "https://developer.apple.com/videos/play/wwdc\(setup.year)/\(session)/"
            let url = validateURL(urlName)
            
            let html = getHTML(url)
            let regex = "<a\\ href=\\\"(.+)\\?dl=1\\\">\(setup.resolution.rawValue)\\ Video"
            do {
                let urls = try extract(regex, from: html)
                let videoURL = validateURL(urls[0])
                
                let fileLocation = setup.saveToDirectory
                
                Downloader().download(videoURL, to: fileLocation)
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
                exit(0)
            }
        }
    }
}

extension Web {
    func extract(_ regularExpression: String, from text: String) throws -> [String] {
        var sortedUniqueMatches : [String] = []
        do {
            let regex = try RegularExpression(pattern: regularExpression, options: [])
            let matches = regex.matches(in: text, options: [], range: NSMakeRange(0, text.characters.count))
            var matchingResults : [String] = []
            for match in matches {
                if !NSEqualRanges(match.range, NSMakeRange(NSNotFound, 0)) {
                    let captureGroup = match.range(at: 1)
                    let nsText = NSString.init(string: text)
                    let matchedString = String.init(nsText.substring(with: captureGroup))
                    matchingResults.append(matchedString)
                }
            }
            
            let uniqueMatchess = Array(Set(matchingResults))
            sortedUniqueMatches = uniqueMatchess.sorted { $0 < $1 }
            
        } catch let error as NSError {
            print("Regex error: \(error.localizedDescription)")
        }
        
        return sortedUniqueMatches
    }
}

class Downloader : NSObject, URLSessionDownloadDelegate {
    var url : URL?
    var fileName : String?
    
    override init()
    {
        super.init()
    }
    
    // Simple download - use for small downloads
    func simpleDownload(_ url: URL, to fileName: String) {
        let downloadData = try? Data(contentsOf: url)
        if(downloadData != nil) {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let filePath="\(documentsPath)/\(fileName)/\(url.lastPathComponent!)"
            if (try? downloadData!.write(to: URL(fileURLWithPath: filePath), options: [.atomic])) != nil {
                print("File is saved!")
            } else {
                print("Problem saving downloaded file")
            }
        }
    }
    
    // Download method - use for *large* downloads
    func download(_ url: URL, to fileName: String) {
        self.url = url
        self.fileName = fileName
        
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: url.absoluteString!)
        sessionConfig.isDiscretionary = true
        let session = Foundation.URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    // *** Delegate callbacks ***
    // Completion handler
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Completion handler called Data downloaded to \(location.absoluteString)")
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath="\(documentsPath)/\(fileName!)/\(url!.lastPathComponent!)"
        let file = URL(string: filePath)!
        
        print("\(location)")
        
        do {
            let downloadData = try Data.init(contentsOf: location, options: [])
            do {
                try downloadData.write(to: file, options: .atomic)
                print("File is saved!")
                
                // Delete temp file
                let fileManager = FileManager.default
                do {
                    try fileManager.removeItem(at: url!)
                    print("Temp file \(url!.path) was removed")
                } catch {
                    print("Error")
                }
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    // Progress
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let percentage = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        print("Downloading \(session.configuration.identifier): \(totalBytesWritten.iso) of \(totalBytesExpectedToWrite.iso) (\(percentage.percentage)%) \r")
        fflush(__stdoutp)			// This, plus the /r in the string, should overwrite the progress on the one line time after time
    }
    
    // Error handling
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        if(error != nil) {
            //handle the error
            print("Download interrupted with error: \(error!.localizedDescription)");
        }
    }
}

// MARK: Where the work is done
let app = Setup()
Web().getDownloads(app)

