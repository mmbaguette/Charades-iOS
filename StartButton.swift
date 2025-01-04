/*
 The start button UI and its animation off the screen.
 */

import SwiftUI

struct StartButton: View {
    @Environment(\.dismiss) var dismissScreen
    var globalVars: GameGlobalVariablesObject
    @Binding var gameMode: Bool
    let checkMotions: () -> ()
    let changeOrientation: (UIInterfaceOrientation) -> ()
    let alertUser: (String) -> ()
    
    var body: some View {
        VStack {
            HStack { //X button, dismiss screen
                Button(action: {
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
            } //end of HStack, X-button
            Spacer()
            Text(globalVars.chosenDeck)
                .bold()
                .minimumScaleFactor(0.01)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .foregroundStyle(.white)
                .padding()
            Text("\(globalVars.words.count) cards")
                .foregroundStyle(.white)
                .font(.title)
            Button(action: {
                if globalVars.words.count > 0 { // if words is not empty
                    //animate the start button to go down
                    withAnimation (.easeIn(duration: 0.5)) {
                        globalVars.startingGame = true
                    } completion: { //start the game when the button leaves the screen
                        changeOrientation(.landscapeLeft)
                        
                        //display the game screen after a second of waiting for the Start button animation to finish; show intructions
                        gameMode = true
                        globalVars.showInstructions = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { //Show the first word after 3 seconds of intructions
                            globalVars.showInstructions = false
                            globalVars.startingGame = false
                            globalVars.timeRemaining = globalVars.defaultGameLength
                            
                            checkMotions()
                        }
                    } //end of withAnimation completion
                } else {
                    alertUser("Will not start game because card deck is empty.")
                }
            }, label: { //end of button action
                    Text("Let's Play!")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .offset(y: globalVars.startingGame ? UIScreen.main.bounds.height : 0)
            }) //end of button
            Spacer()
        }
    }
}

#Preview {
    @Previewable @StateObject var globalVars: GameGlobalVariablesObject = GameGlobalVariablesObject()
    @Previewable @State var gameMode: Bool = false
    
    BackgroundImageViewModel {
        StartButton(globalVars: globalVars, gameMode: $gameMode, checkMotions: {print("motion readings started")}, changeOrientation: {_ in
            print("Changed orientation!")
        }, alertUser: {alertMsg in
            print(alertMsg)
        })
    }
}
