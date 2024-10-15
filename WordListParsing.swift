/*
 Swift class providing read/write functions for a given text file that stores card decks.
 */

import SwiftUI

class WordListParsing {
    //scans the given deck with the file name and deck name, returns new wordlist
    func readDeckFromFile(deckFile: String, deckName: String, alertUser: (String) -> Void) -> [String] {
        var wordlist: [String] = []
        
            guard (deckName != "") else {
                alertUser("No deck chosen.")
                return wordlist
            }
            let path = Bundle.main.path(forResource: deckFile, ofType: "txt") //find the file given the file path
            
            if (path != nil) {
                do {
                    let fileContents: String = try String(contentsOfFile: path!, encoding: .utf8) //try to read the file
                    if let i = fileContents.range(of: deckName+":") { //if chosenDeck found in file
                        var nextDeckIndex: Substring.Index? = fileContents[i.upperBound...].firstIndex(of: ":")
                        
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
                        
                        print("Word list: ", terminator: "")
                        print(wordlist)
                    } else {
                        alertUser("The given deck \"\(deckName)\" cannot be found!")
                    } //end of if let i
                } catch {
                    alertUser("Error: \(error)")
                }
            } else {
                alertUser("The given file path \(deckFile) is not found!")
            } //end of if (path check)
        return wordlist //success
    } //end of parsing function
} //end of class
