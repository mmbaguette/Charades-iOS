//
//  DeckSelection.swift
//  Charades
//
//  Created by Ali Mohammed-Ali on 2024-12-20.
//

import SwiftUI

struct DeckSelectionScreen: View {
    var globalVars: GameGlobalVariablesObject
    @Binding var showStartScreen: Bool
    let alertUser: (String) -> Void
    
    var body: some View {
        let deckList: [String] = WordListParsing().getDeckNames(deckFile: "decks", alertUser: alertUser)
        let deckSize = deckList.count
        let iterCount: Int = Int((Double(deckSize)/2).rounded(.up))
        
        VStack {
            Text("Choose a deck")
                .underline()
                .bold()
                .padding()
                .font(.largeTitle)
                .foregroundStyle(.white)
            ScrollView {
                LazyVStack {
                    ForEach (0..<iterCount) { index in
                        
                        let leftDeckIndex = index*2
                        let leftDeckName: String = deckList[leftDeckIndex]
                        let rightDeckIndex = leftDeckIndex+1
                        let rightDeckName: String = deckSize > rightDeckIndex ? deckList[rightDeckIndex] : ""
                        
                        HStack {
                            DeckSelectionBox(globalVars: globalVars, showStartScreen: $showStartScreen, deckName: leftDeckName, alertUser: alertUser)

                            if (rightDeckIndex < deckSize) { //if odd number of decks
                                DeckSelectionBox(globalVars: globalVars, showStartScreen: $showStartScreen, deckName: rightDeckName, alertUser: alertUser)
                            } else {
                                DeckSelectionBox(globalVars: globalVars, showStartScreen: $showStartScreen, deckName: "", alertUser: alertUser).opacity(0)
                            }
                        } //end of HStack
                        
                    } //end of ForEach loop
                } //end of LazyVStack
            } // end of ScrollView
        } //main VStack
    } //end of body: some View
}

struct DeckSelectionBox: View {
    var globalVars: GameGlobalVariablesObject
    @Binding var showStartScreen: Bool
    let deckName: String
    let alertUser: (String) -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(.white)
                .shadow(color: .white, radius: 5, x: 0, y: 1)
            Text(deckName)
                .font(.title2)
                .multilineTextAlignment(.center)
            
                .minimumScaleFactor(0.01)
                .lineLimit(2) //no hyphens splitting in long words. max 2 lines.
                .foregroundStyle(.black)
                .padding()
        }
        .onTapGesture {
            globalVars.words = WordListParsing().getDeck(deckFile: "decks", deckName: deckName, alertUser: alertUser)
            globalVars.chosenDeck = deckName
            showStartScreen = true
        }
        .frame(width: 150, height: 100) //fixed box size
        .padding()
    }
}

#Preview {
    @Previewable @StateObject var globalVars: GameGlobalVariablesObject = GameGlobalVariablesObject()
    @Previewable @State var showStartScreen: Bool = false
    
    BackgroundImageViewModel {
        DeckSelectionScreen(globalVars: globalVars, showStartScreen: $showStartScreen, alertUser: {alertMsg in print("Error: \(alertMsg)")})
    }
}
