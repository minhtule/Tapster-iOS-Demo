//
//  Utilities.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/24/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import Foundation

let EntryPattern = "(?:,|^)(\"[^\"]*\"|[^\",]*)"

class CSVData {
    let headers: [String]
    let rows: [[String]]
    
    init(fileName: String, delimeter: String = ",") {
        var error: NSError?
        var headers = [String]()
        var rows = [[String]]()
        
        if let fileURL = NSBundle.mainBundle().URLForResource(fileName, withExtension: "csv") {
            if let csvString = String(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding, error: &error) {
                let csvLines = csvString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()).filter { count($0) > 0 }
                var lines = [[String]]()
                
                for line in csvLines {
                    lines.append(CSVData.splitLine(line))
                }
                
                headers = lines[0]
                rows = [[String]](lines[1..<lines.count])
            }
        }
        
        self.headers = headers
        self.rows = rows
    }
    
    func uniqueEntries(column: Int) -> [String] {
        var uniqueEntries = [String: Bool]()
        
        for row in rows {
            uniqueEntries[row[column]] = true
        }
        
        return Array(uniqueEntries.keys)
    }
    
    private class func splitLine(line: String) -> [String] {
        return matchedGroups(EntryPattern, inString: line).map { (group: String) -> String in
            if group.hasPrefix("\"") {
                // Remove the quotes
                return group.substringWithRange(Range<String.Index>(start: advance(group.startIndex, 1), end: advance(group.endIndex, -1)))
            } else {
                return group
            }
        }
    }
    
    private class func matchedGroups(pattern: String, inString string: String) -> [String] {
        let regex = NSRegularExpression(pattern: pattern, options: .allZeros, error: nil)
        let range = NSMakeRange(0, count(string))
        let matches = regex?.matchesInString(string, options: .allZeros, range: range) as! [NSTextCheckingResult]
        
        var groupMatches = [String]()
        for match in matches {
            let rangeCount = match.numberOfRanges
            
            // Ignore the group that is the match itself
            for group in 1..<rangeCount {
                groupMatches.append((string as NSString).substringWithRange(match.rangeAtIndex(group)))
            }
        }
        
        return groupMatches
    }
}
