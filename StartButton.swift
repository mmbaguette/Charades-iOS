/*
 The start button UI and its animation off the screen.
 */

import SwiftUI

struct StartButton: View {
    @Binding var words: [String]
    @Binding var startingGame: Bool
    @Binding var gameMode: Bool
    @Binding var showInstructions: Bool
    let changeOrientation: (UIInterfaceOrientation) -> ()
    let alertUser: (String) -> ()
    
    var body: some View {
        Button(action: {
            if words.count > 0 { // if words is not empty
                //animate the start button to go down
                withAnimation (.easeIn(duration: 0.5)) {
                    startingGame = true
                } completion: { //start the game when the button leaves the screen
                    changeOrientation(.landscapeLeft)
                    
                    //display the game screen after a second
                    gameMode = true
                    showInstructions = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showInstructions = false
                        startingGame = false
                    }
                } //end of withAnimation completion
            } else {
                alertUser("Will not start game because card deck is empty.")
            }
        }, label: { //end of button action
            VStack {
                Spacer()
                Text("Start!")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .offset(y: startingGame ? UIScreen.main.bounds.height : 0)
                Spacer()
            }
        }) //end of button
    }
}

#Preview {
    @State var words = ["Hi", "Hello"]
    @State var startingGame: Bool = false
    @State var gameMode = false
    @State var showInstructions = false
    
    ZStack {
        Color.purple.ignoresSafeArea()
        StartButton(words: $words, startingGame: $startingGame, gameMode: $gameMode, showInstructions: $showInstructions, changeOrientation: {_ in
            print("Changed orientation!")
        }, alertUser: {alertMsg in
            print(alertMsg)
        })
    }
}
