//
//  BeauchampPersistence.swift
//  BeauchampPersistence
//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 JamieScanlon
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import Beauchamp

// MARK: - BeauchampFilePersistence

public class BeauchampFilePersistence {
    
    public static let sharedInstance = BeauchampFilePersistence()
    public var saveDirectory: URL?
    public private(set) var lastSaveFailed: Bool = false
    
    convenience public init(saveDirectory: URL) {
        self.init()
        self.saveDirectory = saveDirectory
    }
    
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(BeauchampFilePersistence.handaleChangeNotification(_:)), name: BeauchampStudyChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: BeauchampStudyChangeNotification, object: nil)
    }
    
    // MARK: Methods
    
    public func reconstituteStudies() -> [Study]? {
        
        guard let saveDirectory = saveDirectory,
              let directoryPath = saveDirectory.path else {
            return nil
        }
        
        var directoryContent: [String] = []
        do {
            directoryContent = try FileManager.default.contentsOfDirectory(atPath: directoryPath)
        } catch {
            return nil
        }
        
        var studies: [Study] = []
        for filename in directoryContent {
            if filename.hasPrefix("study"),
               let filePath = try! saveDirectory.appendingPathComponent(filename, isDirectory: false).path,
               let encodableStudy = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? EncodableStudy,
               let study = encodableStudy.study {
                studies.append(study)
            }
        }
        
        return studies
        
    }
    
    // MARK: Notification Handler
    
    @objc func handaleChangeNotification(_ notif:Notification) {
        
        guard let saveDirectory = saveDirectory else {
            return
        }
        
        var isDir: ObjCBool = true
        if !FileManager.default.fileExists(atPath: saveDirectory.path!, isDirectory: &isDir) {
            do {
                try FileManager.default.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                lastSaveFailed = true
                return
            }
        }
        
        guard let userInfo = (notif as NSNotification).userInfo,
              let payload = userInfo["payload"] as? BeauchampNotificationPayload,
              let studyOptions = payload.options,
              let studyDescription = payload.studyDescription else {
                return
        }
        
        let encodableStudy = EncodableStudy(study: Study(description: studyDescription, options: studyOptions))
        let fullPath = try! saveDirectory.appendingPathComponent("study\(studyDescription.hashValue)")
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(encodableStudy, toFile: fullPath.path!)
        if !isSuccessfulSave {
            lastSaveFailed = true
        } else {
            lastSaveFailed = false
        }
        
    }
    
}

// MARK: - BeauchampUserDefaultsPersistence

public class BeauchampUserDefaultsPersistence {
    
    public static let sharedInstance = BeauchampUserDefaultsPersistence()
    public var defaults: UserDefaults?
    public var defaultsKey: String?
    
    convenience public init(defaults: UserDefaults, key: String) {
        self.init()
        self.defaults = defaults
        self.defaultsKey = key
    }
    
    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(BeauchampFilePersistence.handaleChangeNotification(_:)), name: BeauchampStudyChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: BeauchampStudyChangeNotification, object: nil)
    }
    
    // MARK: Methods
    
    public func reconstituteStudies() -> [Study]? {
        
        guard let defaults = defaults,
              let defaultsKey = defaultsKey else {
                return nil
        }
        
        let studyListKey = "\(defaultsKey).studyList"
        
        guard let studyListData = defaults.data(forKey: studyListKey),
              let studyList = NSKeyedUnarchiver.unarchiveObject(with: studyListData) as? [String] else {
            return nil
        }
        
        var studies: [Study] = []
        for studyKey in studyList {
            
            let fullStudyKey = "\(defaultsKey).\(studyKey)"
            
            if let studyData = defaults.data(forKey: fullStudyKey),
               let encodableStudy = NSKeyedUnarchiver.unarchiveObject(with: studyData) as? EncodableStudy,
               let study = encodableStudy.study {
                studies.append(study)
            }
            
        }
        
        return studies
        
    }
    
    // MARK: Notification Handler
    
    @objc func handaleChangeNotification(_ notif:Notification) {
        
        guard let defaults = defaults,
              let defaultsKey = defaultsKey else {
                return
        }
        
        guard let userInfo = (notif as NSNotification).userInfo,
            let payload = userInfo["payload"] as? BeauchampNotificationPayload,
            let studyOptions = payload.options,
            let studyDescription = payload.studyDescription else {
                return
        }
        
        let encodableStudy = EncodableStudy(study: Study(description: studyDescription, options: studyOptions))
        let studyKey = "study\(studyDescription.hashValue)"
        let fullStudyKey = "\(defaultsKey).\(studyKey)"
        let studyData = NSKeyedArchiver.archivedData(withRootObject: encodableStudy)
        defaults.set(studyData, forKey: fullStudyKey)
        
        let studyListKey = "\(defaultsKey).studyList"
        if let studyListData = defaults.data(forKey: studyListKey),
           let studyList = NSKeyedUnarchiver.unarchiveObject(with: studyListData) as? [String] {
            if !studyList.contains(studyKey) {
                var mutableStudyList = studyList
                mutableStudyList.append(studyKey)
                let newStudyListData = NSKeyedArchiver.archivedData(withRootObject: mutableStudyList)
                defaults.set(newStudyListData, forKey: studyListKey)
            }
        } else {
            let newStudyList = [studyKey]
            let newStudyListData = NSKeyedArchiver.archivedData(withRootObject: newStudyList)
            defaults.set(newStudyListData, forKey: studyListKey)
        }
        
    }
    
}

// MARK: - EncodableStudy

struct EncodableStudyPropertyKey {
    static let descriptionKey = "description"
    static let optionsKey = "options"
}

class EncodableStudy: NSObject, NSCoding {
    
    var study: Study?
    
    init(study:Study) {
        self.study = study
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        
        guard let description = aDecoder.decodeObject(forKey: EncodableStudyPropertyKey.descriptionKey) as? String else {
            return nil
        }
        
        guard let optionDicts = aDecoder.decodeObject(forKey: EncodableStudyPropertyKey.optionsKey) as? [[String: AnyObject]] else {
            return nil
        }
        
        var options: Set<Option> = []
        for optionDict in optionDicts {
            if let optionDescription = optionDict["description"] as? String,
               let optionsTimesTaken = optionDict["timesTaken"] as? Int,
                let optionsTimesEncountered = optionDict["timesEncountered"] as? Int {
                options.insert(Option(description: optionDescription, timesTaken: optionsTimesTaken, timesEncountered: optionsTimesEncountered))
            }
        }
        
        self.init(study: Study(description: description, options: options))
        
    }
    
    func encode(with aCoder: NSCoder) {
        
        guard let study = study else {
            return
        }
        
        aCoder.encode(study.description, forKey: EncodableStudyPropertyKey.descriptionKey)
        
        var options: [[String: AnyObject]] = []
        for option in study.options {
            options.append(["description": option.description, "timesTaken": option.timesTaken, "timesEncountered": option.timesEncountered])
        }
        aCoder.encode(options, forKey: EncodableStudyPropertyKey.optionsKey)
        
    }
    
}
