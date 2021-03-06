//
//  ViewController.swift
//  IPA Builder
//
//  Created by Ghorpade, Krupal on 3/27/18.
//  Copyright © 2018 Ghorpade, Krupal. All rights reserved.
//

import Cocoa
import SSZipArchive

let htmlContent = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"><html xmlns=\"http://www.w3.org/1999/xhtml\"><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0\"><title>Identity Check - Beta Release</title><style type=\"text/css\">body {background:#fff;margin:0;padding:0;font-family:arial,helvetica,sans-serif;text-align:center;padding:10px;color:#333;font-size:16px;}#container {width:300px;margin:0 auto;}h1 {margin:0;padding:0;font-size:14px;}p {font-size:13px;}.link {background:#46b5f4;border-top:2px solid #fff;border:2px solid #dfebf8;margin-top:.5em;padding:.3em;}.link a {text-decoration:none;font-size:15px;display:block;color:#fff;}</style></head><body><p/><div id=\"container\"><h1>For iOS Users Only</h1><p/><div class=\"link\"><a href=\"itms-services://?action=download-manifest&url=PLIST_LINK\">Tap to Install<br/>APP_NAME</a></div><p class=\"last_updated\">UPDATE_DATE</p></br><p/><p><strong>Link didn't work?</strong><br />Make sure you're visiting this page on your device, not your computer.</p></div></body></html>"

let plistContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>items</key><array><dict><key>assets</key><array><dict><key>kind</key><string>software-package</string><key>url</key><string>LINK.IPA</string></dict></array><key>metadata</key><dict><key>bundle-identifier</key><string>BUNDLE_ID</string><key>bundle-version</key><string>BUNDLE_VERSION</string><key>kind</key><string>software</string><key>title</key><string>BUNDLE_NAME</string></dict></dict></array></dict></plist>"

class ViewController: NSViewController {
    
    @IBOutlet var textField:NSTextField?
    @IBOutlet var selectButton:NSButton?
    @IBOutlet var generateButton:NSButton?
    @IBOutlet var progressIndicator:NSProgressIndicator?
    @IBOutlet var checkMark:NSButton?
    
    
    @IBOutlet var baseURLField:NSTextField?
    @IBOutlet var bundleIDTextField:NSTextField?
    @IBOutlet var appNameTextField:NSTextField?
    @IBOutlet var versionNumberTextField:NSTextField?
    
    var actualIPAPath:String?
    var tempDirPath:String?
    var appPath:String?
    var baseURL: String?
    var ipaName:String?
    var bundleID:String?
    var appName: String?
    var versionNumber:String?
    var toRename : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.progressIndicator?.isHidden = true
        self.progressIndicator?.startAnimation(self)
        self.generateButton?.isEnabled = false
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "IPA Builder"
        self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
    }
    
    @IBAction func loadIPA(_ sender: Any) {
        
        let panel = NSOpenPanel(contentRect: NSRect(x: 0, y: 0, width: 100, height: 80), styleMask: NSWindow.StyleMask.fullScreen, backing: NSWindow.BackingStoreType.retained, defer: true)
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.allowedFileTypes = ["ipa"]  // to allow only ipa, just comment out this line to allow any file type to be selected
        
        let clickedIndex = panel.runModal()
        
        if clickedIndex.rawValue == NSFileHandlingPanelOKButton{
            
            for url in panel.urls{
                print(url.absoluteString.replacingOccurrences(of: "file://", with: ""))
                self.actualIPAPath = url.path
                self.textField?.isEnabled = true
                self.textField?.isEditable = false
                self.textField?.stringValue = url.absoluteString.replacingOccurrences(of: "file://", with: "")
                self.generateButton?.isHidden = true
                self.progressIndicator?.isHidden = false
                
                self.appNameTextField?.stringValue = "App Name:"
                self.bundleIDTextField?.stringValue = "Bundle ID:"
                self.versionNumberTextField?.stringValue = "Version No:"
                
                DispatchQueue.global(qos: .background).async {
                    self.populateDetails()
                }
            }
        }
    }
    
    internal func populateDetails() {
        
        let fileManager = FileManager.default
        
        let ipaSourceURL = URL.init(fileURLWithPath: self.actualIPAPath!)
        
        let ipaDestinationPathString = "\(NSTemporaryDirectory())/\(ipaSourceURL.lastPathComponent)"
        
        let ipaDestinationURL = URL.init(fileURLWithPath:ipaDestinationPathString)
        
        try? fileManager.removeItem(at: ipaDestinationURL)
        try? fileManager.copyItem(at: ipaDestinationURL, to: ipaSourceURL)
        
        let unzippedFolderPath = NSTemporaryDirectory().appending("unzippedFolder")
        
        try? fileManager.removeItem(at: URL.init(fileURLWithPath: unzippedFolderPath))
        
        SSZipArchive.unzipFile(atPath: ipaSourceURL.path, toDestination: URL.init(fileURLWithPath: unzippedFolderPath).path)
        
        self.tempDirPath = unzippedFolderPath
        
        self.fetchBundleInfo()
    }

    
    @IBAction func generateFiles(_ sender: Any){
        
        if self.checkMark?.state == .on{
            
            if self.inputPrompt(){
                
                if self.toRename != nil {
                    
                    let ipaSourceURL = URL.init(fileURLWithPath: self.actualIPAPath!)
                    
                    let ipaName = URL(fileURLWithPath: self.actualIPAPath!).lastPathComponent
                    let newIpaName = self.actualIPAPath?.replacingOccurrences(of: ipaName, with: "\(self.toRename!).ipa")
                    let fileManager = FileManager.default
                    
                    try? fileManager.moveItem(at: ipaSourceURL, to: URL.init(fileURLWithPath: newIpaName!))
                    self.actualIPAPath = newIpaName!
                    self.ipaName = URL.init(fileURLWithPath: self.actualIPAPath!).deletingPathExtension().lastPathComponent
                    
                    self.createFiles()
                    
                }else{
                    let alert = NSAlert()
                    alert.addButton(withTitle: "OK")
                    alert.messageText = "Please enter the new IPA name"
                    alert.alertStyle = .critical
                    alert.runModal()
                }
            }
        }else{
            self.createFiles()
        }
    }
    
    internal func createFiles(){
        
        self.baseURL = self.baseURLField?.stringValue
        
        let manager = FileManager()
        if manager.fileExists(atPath: (self.actualIPAPath)!){
            
            self.generateButton?.isHidden = true
            self.progressIndicator?.isHidden = false
            
            DispatchQueue.global(qos: .background).async {
                self.createHTML()
                self.createPlist()
                self.deleteTempFiles()
            }
            
        }else{
            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.messageText = "File doesn't exist at selected location"
            alert.informativeText = "Please select appropriate path"
            alert.alertStyle = .critical
            alert.runModal()
        }
    }
    internal func fetchBundleInfo(){
        
        let manager = FileManager()
        let stringsArray:[String]? = try? manager.contentsOfDirectory(atPath: "\(self.tempDirPath!)/Payload")
        
        for dirName in stringsArray! {
            if NSURL(fileURLWithPath:dirName).pathExtension == "app"{
                self.appPath = "\(self.tempDirPath!)/Payload/\(dirName)"
            }
        }
        
        if self.appPath != nil{
            let plistPath = self.appPath!.appending("/Info.plist")
            let bundlePlistDict:NSDictionary = NSDictionary(contentsOfFile: plistPath)!
            
            self.versionNumber = bundlePlistDict.value(forKey: "CFBundleShortVersionString") as? String
            let buildNo = bundlePlistDict.value(forKey: "CFBundleVersion") as! String
            self.bundleID = bundlePlistDict.value(forKey: "CFBundleIdentifier") as? String
            self.appName = bundlePlistDict.value(forKey: "CFBundleDisplayName") as? String
            self.ipaName = URL.init(fileURLWithPath: self.actualIPAPath!).deletingPathExtension().lastPathComponent
            // Display Values
            DispatchQueue.main.async {
                
                self.versionNumberTextField?.stringValue =  "Version No: \(self.versionNumber!) (\(buildNo))"
                self.bundleIDTextField?.stringValue = "Bundle ID: \(self.bundleID!)"
                
                if (bundlePlistDict.value(forKey: "CFBundleDisplayName") != nil){
                    self.appNameTextField?.stringValue = "App Name: \(self.appName!)"
                }
                self.progressIndicator?.isHidden = true
                self.generateButton?.isHidden = false
                self.generateButton?.isEnabled = true
                
            }
        }
        
    }
    
    internal func createHTML(){
        
        let plistLink = "\(baseURL!)/\(self.ipaName!).plist"
        
        var html = htmlContent.replacingOccurrences(of: "PLIST_LINK", with: plistLink)
        
        
        if self.appName != nil{
            html = html.replacingOccurrences(of: "APP_NAME", with: self.appName!)
        }else{
            html = html.replacingOccurrences(of: "APP_NAME", with: "iOS App")
        }
        

        // Set Date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyy HH:mm"
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        let myStringDate = formatter.string(from: NSDate() as Date)

        
        html = html.replacingOccurrences(of: "UPDATE_DATE", with: "Last Updated: \(myStringDate) \(NSTimeZone.default.abbreviation()!)")
        
        let manager = FileManager()
        
        let htmlPath = "\(URL(fileURLWithPath: self.actualIPAPath!).deletingLastPathComponent().path)/\(self.ipaName!).html"
        
        if manager.fileExists(atPath: htmlPath){
            try? manager.removeItem(atPath: htmlPath)
        }
        manager.createFile(atPath: htmlPath, contents: html.data(using: String.Encoding.utf8), attributes: nil)
    }
    
    internal func createPlist(){
        
        let ipaLink = "\(baseURL!)/\(self.ipaName!).ipa"
        
        var plist = plistContent.replacingOccurrences(of: "LINK.IPA", with: ipaLink)
        plist = plist.replacingOccurrences(of: "BUNDLE_ID", with: self.bundleID!)
        plist = plist.replacingOccurrences(of: "BUNDLE_VERSION", with: self.versionNumber!)
        if self.appName != nil{
            plist = plist.replacingOccurrences(of: "BUNDLE_NAME", with: self.appName!)
        }else{
            plist = plist.replacingOccurrences(of: "BUNDLE_NAME", with: "iOS App")
        }
        
        
        let manager = FileManager()
        
        
        let plistPath = "\(URL(fileURLWithPath: self.actualIPAPath!).deletingLastPathComponent().path)/\(self.ipaName!).plist"
        
        if manager.fileExists(atPath: plistPath){
            try? manager.removeItem(atPath: plistPath)
        }
        manager.createFile(atPath: plistPath, contents: plist.data(using: String.Encoding.utf8), attributes: nil)
        
    }
    
    internal func deleteTempFiles(){
        let manager = FileManager()
        try? manager.removeItem(atPath: self.tempDirPath!)
        
        DispatchQueue.main.async {
            
            self.generateButton?.isHidden = false
            self.progressIndicator?.isHidden = !(self.generateButton?.isHidden)!
            
            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.messageText = "Files created successfully!"
            alert.alertStyle = .informational
            let response: NSApplication.ModalResponse = alert.runModal()

            if response.rawValue == 1000{
                //Open Finder
                NSWorkspace.shared.openFile(URL(fileURLWithPath: self.actualIPAPath!).deletingLastPathComponent().path)
            }

            
            self.actualIPAPath = nil
            self.appNameTextField?.stringValue = "App Name:"
            self.bundleIDTextField?.stringValue = "Bundle ID:"
            self.versionNumberTextField?.stringValue = "Version No:"
            self.textField?.stringValue = ""
            self.generateButton?.isEnabled = false
            
            
        }
    }
    
    internal func inputPrompt()->Bool{
        
        let alert = NSAlert()
        alert.addButton(withTitle: "Submit")
        alert.messageText = "Enter the new IPA name to rename."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = input
        input.becomeFirstResponder()
        let clickedIndex = alert.runModal()
        
        if clickedIndex.rawValue == 1000 {
            if input.stringValue != ""{
                self.toRename = input.stringValue.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
                return true
            }
        }
        return false
    }
}
