//
//  Utilities.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/24/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import Foundation

let entryPattern = "(?:,|^)(\"[^\"]*\"|[^\",]*)"

class CSVData {
    let headers: [String]
    let rows: [[String]]

    init(fileName: String, delimeter: String = ",") {
        var headers = [String]()
        var rows = [[String]]()

        if let fileURL = Bundle.main.url(forResource: fileName, withExtension: "csv") {
            if let csvString = try? String(contentsOf: fileURL, encoding: .utf8) {
                let csvLines = csvString.components(separatedBy: CharacterSet.newlines).filter { !$0.isEmpty }
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

    private class func splitLine(_ line: String) -> [String] {
        return matchedGroups(pattern: entryPattern, inString: line).map { (group: String) -> String in
            if group.hasPrefix("\"") {
                // Remove the quotes
                let left = group.index(after: group.startIndex)
                let right = group.index(before: group.endIndex)
                return String(group[left..<right])
            } else {
                return group
            }
        }
    }

    private class func matchedGroups(pattern: String, inString string: String) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: string.count)
        let matches = regex.matches(in: string, options: [], range: range)

        var groupMatches = [String]()
        for match in matches {
            let rangeCount = match.numberOfRanges

            // Ignore the group that is the match itself
            for group in 1..<rangeCount {
                groupMatches.append((string as NSString).substring(with: match.range(at: group)))
            }
        }

        return groupMatches
    }
}
