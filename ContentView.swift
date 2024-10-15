/*
 This is an interactive party game where the objective is for everyone around you to help you guess the word on the screen before the timer runs out by giving you hints while you hold the phone above your head.
 */

import SwiftUI
import CoreMotion
import _PhotosUI_SwiftUI //PhotoPicker.swift

//import AudioToolbox

/*
TODO:
 - FIX showWordFeedback NOT SHOWING
 - Lock the screen in orientation mode
 - Countdown in game
 - countdown before starting game
 - Winning screen, and go back to main screen
- Then fix the issue where some elements are shown twice in the same game. If the deck is finished then show the winning screen
 - deck selection screen
 - high score, store on phone
 - add custom decks
 */

struct ContentView: View {
    @StateObject private var viewModel = PhotoPickerViewModel()
    
    let manager = CMMotionManager()
    let queue = OperationQueue()
    let wordDisplayQueue = OperationQueue() //queue that decides whether the current word, "Correct!", or "Skip!", or the next word is shown during a game
    
    private let rotationChangePublisher = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
    
    //background vars that the game controls
    @State var gameMode: Bool = false //whether a game is in sessions and the game fullScreenPopup is showing
    @State var pitchIsReset = false //whether the user has held their phone back up straight
    @State var lastWordWasCorrect = true //whether the last word held up by the user was guessed correctly or skipped
    @State var showWordFeedback = false //whether we're displaying the current word or "Correct!" or "Skip!" to be used in withAnimation
    @State var startingGame = false //whether we're starting a new game (user clicked start). this triggers the Start button animation
    @State var showCountdown = false
    @State var chosenDeck: String = "Athletes" //the name of the deck in the decks.txt file
    @State var words: [String] = []
    @State var showInstructions = false //whether we're still showing pre-game instructions before the round starts ("Place on forehead")
    
    //values that the user sees
    @State var currentWord: String = "" //current displayed word
    @State var wins: Int = 0 //# of correctly guseed words
    @State var skipped: Int = 0 //# of skipped word
    //@State var displayText = "" //large text to display on screen during game
    
    @State var showUserAlert: Bool = false
    @State var errorMessage: String = ""
    @State var errorTitle: String = ""
    
    //constants
    let deckFileName = "decks" //do NOT include .txt extension
    let wordFeedbackAnimDuration: Double = 0.5 //0.2
    
    var body: some View {
        ZStack { //home page
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable() //without .scaledToFill or Fit, the image just fills the whole frame on its own, distorted
                    .ignoresSafeArea()
                    .zIndex(0)
            } else {
                Color.purple.ignoresSafeArea()
            }
            
            VStack {
                CharadesTitle()
                Spacer()
                StartButton(words: $words, startingGame: $startingGame, gameMode: $gameMode, showInstructions: $showInstructions, changeOrientation: changeOrientation, alertUser: alertUser)
                .alert(errorTitle, isPresented: $showUserAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
                .fullScreenCover(isPresented: $gameMode, content: {
                    GameScreen(showWordFeedback: $showWordFeedback, lastWordWasCorrect: $lastWordWasCorrect, currentWord: $currentWord, wins: $wins, skipped: $skipped, showInstructions: $showInstructions, wordFeedbackAnimDuration: wordFeedbackAnimDuration)
                })
                
                HStack { //bottom PhotosPicker bar
                    PhotosPicker(selection: $viewModel.imageSelection, matching: .images) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundStyle(.white)
                            .font(.largeTitle)
                    }
                    .padding()
                    Spacer()
                }
            } //end of VStack
            .zIndex(1.0)
        } //end of ZStack
        .onAppear(perform: onMainScreenAppear)
    } //end of var body: some View
     
    func onMainScreenAppear() {
        changeOrientation(to: .portrait) //make sure phone is in portrait mode in the beginning
        words = WordListParsing().readDeckFromFile(deckFile: deckFileName, deckName: chosenDeck, alertUser: alertUser)
        if words.isEmpty {return} //make sure the program can actually fetch the deck from the local file storage, or the game can't function at all!
        
        currentWord = chooseRandomWord() //set first word
        
        manager.startDeviceMotionUpdates(to: self.queue) { (data: CMDeviceMotion?, error: Error?) in
            let attitude = data!.attitude
            
            if gameMode && !showInstructions {
                if Double(attitude.roll) >= (3*Double.pi/4) && pitchIsReset { // 3/4 of pi, rolled phone forwards to indicate "Correct!"
                    wins = wins + 1 //add to wins score
                    lastWordWasCorrect = true //helps identify whether to display "Correct!" or "Skip!" as feedback when phone is titlted
                    resetPitch()
                } else if Double(attitude.roll) <= (1*Double.pi/4) && Double(attitude.roll) > 0 && pitchIsReset { //rolled phone backwards to Skip!
                    skipped = skipped + 1
                    lastWordWasCorrect = false
                    resetPitch()
                }
                else if Double(attitude.roll) < (3*Double.pi/4) && Double(attitude.roll) > (1*Double.pi/4) { //user rolled phone back up after rolling it down (between 1/4 and 3/4 of pi)
                    pitchIsReset = true
                }
            } //end of if gameMode
        } //end of startDeviceMotionUpdates
    }
    
    func resetPitch() {
        currentWord = chooseRandomWord()
        pitchIsReset = false
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibrate phone
        
        //display "Correct!" or "Skip!" then make it fade out
        showWordFeedback = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + wordFeedbackAnimDuration) { //0.6 is animation delay.
            showWordFeedback = false //take away Skip! or Correct! messages
        }
    }
    
    func alertUser(message: String) { //this function updates a value in the struct
        print(message)
        errorMessage = message
        showUserAlert = true
    }
    
    func changeOrientation(to orientation: UIInterfaceOrientation) {
        // tell the app to change the orientation
        
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientation.isPortrait ? .portrait : .landscapeLeft))
        
        //print("Changing to", orientation.isPortrait ? "Portrait" : "Landscape")
    }
        
    func chooseRandomWord() -> String {
        return words.randomElement()!
    }
} //end of struct

#Preview {
//    @State var showWordFeedback = false
//    @State var lastWordWasCorrect = false
//    @State var showInstructions = false
//    @State var currentWord = "Joe Biden"
//    @State var wins = 0
//    @State var skipped = 0
//    
//    GameScreen(showWordFeedback: $showWordFeedback, lastWordWasCorrect: $lastWordWasCorrect, currentWord: $currentWord, wins: $wins, skipped: $skipped, showInstructions: $showInstructions)
//    
    ContentView()
}

