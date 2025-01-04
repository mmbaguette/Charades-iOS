/*
 Swift class providing read/write functions for a given text file that stores card decks.
 */

import SwiftUI

class WordListParsing {
    //returns a list of strings in argument regex that appear in argument text
    func matches(regex: String, text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(String(text[Range($0.range, in: text)!]).dropLast().dropLast())
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    //returns a list of deck names from a given file, otherwise alerts user if file doesn't exist
    func getDeckNames(deckFile: String, alertUser: (String) -> Void) -> [String] {
        let path = Bundle.main.path(forResource: deckFile, ofType: "txt") //find the file given the file path
        if (path != nil) {
            do {
                let fileContents: String = try String(contentsOfFile: path!, encoding: .utf8) //try to read the file
                return matches(regex: "(.+)\\:\\n", text: fileContents) //search for deck name titles in fileContents, return this list
            } catch {
                alertUser("File read error: \(error)")
            }
        } else {
            alertUser("The given file path \(deckFile) is not found!")
        } //end of if (path check)
        return []
    }
    
    //scans the given deck with the file name and deck name, returns new wordlist, otherwise alerts user that given deck or file doesn't exist
    func getDeck(deckFile: String, deckName: String, alertUser: (String) -> Void) -> [String] {
        var wordlist: [String] = []
        
            guard (deckName != "") else {
                alertUser("No deck chosen.")
                return wordlist
            }
            let path = Bundle.main.path(forResource: deckFile, ofType: "txt") //find the file given the file path
            
            if (path != nil) {
                do {
                    let fileContents: String = try String(contentsOfFile: path!, encoding: .utf8) //try to read the file
                    if let i = fileContents.range(of: deckName+":\n") { //if chosenDeck found in file
                        var nextDeckIndex: Substring.Index? = fileContents[i.upperBound...].ranges(of: ":\n").first?.lowerBound //look for next occurence of a deck name (ends with :\n)
                        
                        if nextDeckIndex == nil { //if there's no more decks after this, then just set it to the index at the end of the file
                            nextDeckIndex = fileContents.index(before: fileContents.endIndex) //this is the last index of the file string (.endIndex is actually the index after the last character, so we have to go one index before)
                        }

//                        print(nextDeckIndex!.utf16Offset(in: fileContents)) //displays substring an int index
//                        print(fileContents.distance(from: fileContents.startIndex, to: fileContents.index(before: fileContents.endIndex))) //displays index or range (of fileContents)
                        
                        let deckStringContents = fileContents[i.upperBound...nextDeckIndex!]
                        
                        for cardSubstring in deckStringContents.split(separator: "\n") {
                            let cardString = String(cardSubstring)
                            if (!cardString.hasSuffix(":") && !cardString.isEmpty) { //remove any deck names we might have accidendatly included (ex: "Animals:" or "Athletes:")
                                wordlist.append(cardString)
                            }
                        }
                    } else {
                        alertUser("The given deck \"\(deckName)\" cannot be found!")
                    } //end of if chosenDesk exists in file
                } catch {
                    alertUser("File read error: \(error)")
                }
            } else {
                alertUser("The given file path \(deckFile) is not found!")
            } //end of if (path check)
        print(wordlist)
        return wordlist //success
    } //end of wordlist parsing function
    
    
} //end of class

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
