/*
 The full screen pop up that appears when a game session begins.
 */

import SwiftUI

struct GameScreen: View {
    
    @Environment(\.dismiss) var dismissScreen
    
    @Binding var showWordFeedback: Bool
    @Binding var lastWordWasCorrect: Bool
    @Binding var currentWord: String
    @Binding var wins: Int
    @Binding var skipped: Int
    @Binding var showInstructions: Bool
    let wordFeedbackAnimDuration: Double
    
    var body: some View {
        ZStack {
            Color.purple.ignoresSafeArea()
            VStack {
                CharadesTitle()
                Spacer()
                if (showWordFeedback) { //currently showing "Correct!" or "Skip!" label
                    GameWord(lastWordWasCorrect ? "Correct!" : "Skip!")
                        .opacity(showWordFeedback ? 1.0 : 0)
                        .zIndex(3.0)
                } else {
                    if (showInstructions) {
                        Text("Place phone on forehead.")
                            .font(.system(size: 70))
                            .minimumScaleFactor(0.01)
                            .lineLimit(1)
                            .foregroundStyle(.white)
                            .bold() //instructions for user at the beginning of the game
                            .padding()
                    } else { //show the Current word that needs to be guessed
                        GameWord(currentWord)
                            .shadow(color: .white, radius: 6, x: 5, y: 5)
                            .opacity(showWordFeedback ? 0 : 1.0)
                            .zIndex(2.0)
                    }
                }
                Spacer() //Display wins
                if !showInstructions {
                    Text("Correct: \(wins)   Skipped: \(skipped)")
                        .foregroundStyle(.white)
                        .bold()
                        .font(.title2)
                }
            }
            .animation(.easeInOut(duration: wordFeedbackAnimDuration), value: showWordFeedback)
            .zIndex(2.0)
        }
    }
}

struct GameWord: View {
    var word: String = ""
    
    init (_ word: String = "") { //_ underscore means no parameter name required when declaring this struct
        self.word = word
    }
    
    var body: some View {
        Text(word)
            .font(.system(size: 90))
            .minimumScaleFactor(0.01) //resizes text to fit view if it's too big
            .foregroundStyle(.white)
            .bold()
            .multilineTextAlignment(.center)
            .padding()
    }
}

struct CharadesTitle: View {
    var body: some View {
        Text("Charades!")
            .font(.title)
            .foregroundStyle(.white)
            .bold()
            .padding()
    }
}

#Preview {
    @State var showWordFeedback = false
    @State var lastWordWasCorrect = false
    @State var showInstructions = false
    @State var currentWord = WordListParsing().readDeckFromFile(deckFile: "decks", deckName: "Athletes", alertUser: {alertMsg in
        print(alertMsg)
    }).randomElement() ?? "Joe Biden" //chose random word to display in the given deck file and deck name
    @State var wins = 0
    @State var skipped = 0

    GameScreen(showWordFeedback: $showWordFeedback, lastWordWasCorrect: $lastWordWasCorrect, currentWord: $currentWord, wins: $wins, skipped: $skipped, showInstructions: $showInstructions, wordFeedbackAnimDuration: 0.5)
}
