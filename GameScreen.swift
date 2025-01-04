/*
 The full screen pop up that appears when a game session begins.
 */

import SwiftUI

struct GameScreen: View {
    @Environment(\.dismiss) var dismissScreen
    var globalVars: GameGlobalVariablesObject
    @Binding var gameMode: Bool
    let onGameEnded: (_ message: String) -> Void //call this when the game ends on its own (deck runs out, timer runs out)
    let changeOrientation: (_ to: UIInterfaceOrientation) -> Void
    let wordFeedbackAnimDuration: Double
    @State var isTimeUp: Bool = false
    
    var body: some View {
            VStack {
                ZStack { //X button, stop game
                    CharadesTitle()
                    HStack {
                        Button(action: {
                            globalVars.wins = 0
                            globalVars.skipped = 0 //reset scores before dismissing screen
                            gameMode = false
                            changeOrientation(.portrait)
                            globalVars.timer.upstream.connect().cancel()
                            dismissScreen()
                        }, label: {
                            Image(systemName: "x.circle.fill")
                                .resizable()
                                .foregroundStyle(.white)
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .padding()
                        })
                        
                        Spacer()
                    }
                } //end of X button
                
                Spacer()
                if (globalVars.showWordFeedback) { //currently showing "Correct!" or "Skip!" label
                    GameWord(globalVars.lastWordWasCorrect ? "Correct!" : "Skip!")
                        .opacity(globalVars.showWordFeedback ? 1.0 : 0)
                        .zIndex(3.0)
                } else {
                    if (globalVars.showInstructions) {
                        GameWord("Place phone on forehead.") //instructions for user at the beginning of the game
                    } else { //show the Current word that needs to be guessed
                        GameWord(globalVars.currentWord)
                            .shadow(color: .white, radius: 6, x: 5, y: 5)
                            .opacity(globalVars.showWordFeedback ? 0 : 1.0)
                            .zIndex(2.0)
                    }
                }
                Spacer()
                
                if !globalVars.showInstructions { //Display scores and timer when "Place on forehead" is not displayed
                    HStack {
                        if #available(iOS 18.0, *) {
                            Image(systemName: "deskclock.fill")
                            //.resizable()
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                                //.symbolEffect(.scale.up, options: .repeating, value: isTimeUp)
                                .symbolEffect(.wiggle.clockwise, options: .repeating.speed(1.5), value: isTimeUp)
                        } else {
                            Image(systemName: "deskclock.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                        Text("\( Duration.seconds(globalVars.timeRemaining).formatted(.time(pattern: .minuteSecond(padMinuteToLength: 1, fractionalSecondsLength: 0))) )")
                            .onReceive(globalVars.timer) { _ in //countdown, decrease timer every second
                                if globalVars.timeRemaining > 0 {
                                    globalVars.timeRemaining -= 1
                                } else {
                                    isTimeUp = true
                                    onGameEnded("Time's up!")
                                }
                            }
                            .foregroundStyle(.white)
                            .bold()
                            .font(.title2)
                        Text("| Correct: \(globalVars.wins)   Skipped: \(globalVars.skipped)")
                            .foregroundStyle(.white)
                            .bold()
                            .font(.title2)
                    }
                }
            }//end of main VStack
            .animation(.easeInOut(duration: wordFeedbackAnimDuration), value: globalVars.showWordFeedback)
            //.zIndex(2.0)
    }
}

struct GameWord: View {
    var word: String = ""
    
    init (_ word: String = "") { //_ underscore means no parameter name required when declaring this struct
        self.word = word
    }
    
    var body: some View {
        Text(word)
            .minimumScaleFactor(0.01)
            .lineLimit(1) //keep everything on one line. scale the text down if you have to
            .font(.system(size: 90))
             //resizes text to fit view if it's too big
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
    @Previewable @StateObject var globalVars: GameGlobalVariablesObject = GameGlobalVariablesObject()
    @Previewable @State var gameMode = false
    
    BackgroundImageViewModel(backgroundSwiftImage: Image("TestImage")) {
        GameScreen(globalVars: globalVars, gameMode: $gameMode, onGameEnded: {msg in print(msg)}, changeOrientation: {_ in print("virtually changing orientation"); globalVars.timer.upstream.connect().cancel()}, wordFeedbackAnimDuration: 0.5)
    }
    .onAppear(perform: {
        globalVars.timeRemaining = 3 //only in preview mode
    })
}
