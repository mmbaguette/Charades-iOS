/*
 This is an interactive party game where the objective is for everyone around you to help you guess the word on the screen before the timer runs out by giving you hints while you hold the phone above your head.
 */

import SwiftUI
import CoreMotion
import _PhotosUI_SwiftUI //PhotoPicker.swift

/*
TODO:
 - Countdown in game
 - countdown before starting game
 - high score, store on phone
 */

@MainActor
class GameGlobalVariablesObject: ObservableObject {
    let defaultGameLength: Int = 120 //default length of game in seconds
    
    @Published var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @Published var pitchIsReset = false //whether the user has held their phone back up straight
    @Published var lastWordWasCorrect = true //whether the last word held up by the user was guessed correctly or skipped
    @Published var showWordFeedback = false //whether we're displaying the current word or "Correct!" or "Skip!" to be used in withAnimation
    @Published var startingGame = false //whether we're starting a new game (user clicked start). this triggers the Start button animation
    @Published var showCountdown = false
    @Published var chosenDeck: String = "" //the name of the deck in the decks.txt file
    
    @Published var words: [String] = []
    @Published var showInstructions = false //whether we're still showing pre-game instructions before the round starts ("Place on forehead")
    
    //values that the user sees
    @Published var currentWord: String = "" //current displayed word
    @Published var wins: Int = 0 //# of correctly guseed words
    @Published var skipped: Int = 0 //# of skipped word
    @Published var timeRemaining: Int //timer time remaining
    
    init() {
        self.timeRemaining = defaultGameLength
        
        let isPreviewing = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] //Preview mode
        if (isPreviewing != nil) {
            if (isPreviewing! == "1") { //if in preview mode
                self.chosenDeck = "People"
                self.words = ["Lebron", "James"]
                self.currentWord = words.first ?? "Johm"
            }
        }
    }
}

@MainActor
struct ContentView: View {
    @StateObject private var viewModel = PhotoPickerViewModel()
    @StateObject private var globalVars: GameGlobalVariablesObject = GameGlobalVariablesObject()
    
    let manager = CMMotionManager()
    let queue = OperationQueue()
    let wordDisplayQueue = OperationQueue() //queue that decides whether the current word, "Correct!", or "Skip!", or the next word is shown during a game
    
    private let rotationChangePublisher = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
    
    @State var showUserAlert: Bool = false
    @State var errorMessage: String = ""
    @State var errorTitle: String = ""
    
    @State var gameMode: Bool = false //whether a game is in sessions and the game fullScreenPopup is showing
    @State var showStartScreen: Bool = false //whether start button is being displayed
    
    //constants
    let deckFileName = "decks" //do NOT include .txt extension
    let wordFeedbackAnimDuration: Double = 0.5 //how long the Skip! or Correct! word appears
    
    var body: some View {
        BackgroundImageViewModel (backgroundUIImage: viewModel.selectedImage) {
            ZStack { //home page
                VStack {
                    CharadesTitle()
                    Spacer()
                    DeckSelectionScreen(globalVars: globalVars, showStartScreen: $showStartScreen, alertUser: alertUser)
                        .fullScreenCover(isPresented: $showStartScreen, content: { //show start button when a deck is selected
                            BackgroundImageViewModel (backgroundUIImage: viewModel.selectedImage) {
                                StartButton(globalVars: globalVars, gameMode: $gameMode, checkMotions: checkMotions, changeOrientation: changeOrientation, alertUser: alertUser)
                                .alert(errorTitle, isPresented: $showUserAlert) {
                                    Button("OK", role: .cancel) {}
                                } message: {
                                    Text(errorMessage)
                                    //Game Screen Pop-up
                                        
                                } //end of alert message
                            }
                            .fullScreenCover(isPresented: $gameMode, content: {
                                //selected background image stays even as the game is playing
                                BackgroundImageViewModel (backgroundUIImage: viewModel.selectedImage) {
                                    GameScreen(globalVars: globalVars, gameMode: $gameMode, onGameEnded: endGame, changeOrientation: changeOrientation, wordFeedbackAnimDuration: wordFeedbackAnimDuration)
                                }}) //end of gameScreen fullScreenCover
                        }) //end of StartButton fullScreenCover
                    
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
        }
    } //end of var body: some View
     
    //when the app first loads
    func onMainScreenAppear() {
        changeOrientation(to: .portrait) //make sure phone is in portrait mode in the beginning
        //manager.stopDeviceMotionUpdates() //use this to stop motin updates
    }
    
    func checkMotions () {
        var curr: Int = 0 //index of the current word
        let shuffledDeck = globalVars.words.shuffled()
        
        if (gameMode && !shuffledDeck.isEmpty) { //make sure deck has contents
            globalVars.currentWord = shuffledDeck.first! //set first word
        } else {
            gameMode = false
            print("This deck is empty!")
            return
        }
        
        manager.startDeviceMotionUpdates(to: self.queue) { (data: CMDeviceMotion?, error: Error?) in
            let attitude = data!.attitude
            
            if gameMode { //if a game is in session,
                if (!globalVars.showInstructions &&  !globalVars.showWordFeedback) { //if we're currently showing a word from the deck (and not instructions or Skip!)
                    if Double(attitude.roll) >= (3*Double.pi/4) && globalVars.pitchIsReset { // 3/4 of pi, rolled phone forwards to indicate "Correct!"
                        DispatchQueue.main.async {
                            globalVars.wins += 1 //add to wins score
                            globalVars.lastWordWasCorrect = true //helps identify whether to display "Correct!" or "Skip!" as feedback when phone is titlted
                        }
                        curr = resetPitch(curr: curr, shuffledDeck: shuffledDeck)
                    } else if Double(attitude.roll) <= (1*Double.pi/4) && Double(attitude.roll) > 0 && globalVars.pitchIsReset { //rolled phone backwards to Skip!
                        DispatchQueue.main.async {
                            globalVars.skipped += 1
                            globalVars.lastWordWasCorrect = false
                        }
                        curr = resetPitch(curr: curr, shuffledDeck: shuffledDeck)
                    }
                    else if Double(attitude.roll) < (3*Double.pi/4) && Double(attitude.roll) > (1*Double.pi/4) { //user rolled phone back up after rolling it down (between 1/4 and 3/4 of pi)
                        DispatchQueue.main.async {
                            globalVars.pitchIsReset = true
                        }
                    }
                }
            } //end of if gameMode
            else { //stop motion updates as soon as game is over
                print("Game has ended. gameMode is false")
                //changeOrientation(to: .portrait) //crashes game
                manager.stopDeviceMotionUpdates()
            }
        } //end of startDeviceMotionUpdates
    }
    
    func endGame(_ msg: String) {
        DispatchQueue.main.async {
            globalVars.timer.upstream.connect().cancel()
            globalVars.currentWord = msg
        }
        manager.stopDeviceMotionUpdates()
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibrate phone 3 times to indicate win
    }
    
    func resetPitch(curr: Int, shuffledDeck: [String]) -> Int {
        DispatchQueue.main.async {
            globalVars.pitchIsReset = false
            globalVars.showWordFeedback = true //display "Correct!" or "Skip!" then make it fade out
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + wordFeedbackAnimDuration) { //0.6 is animation delay.
            globalVars.showWordFeedback = false //take away Skip! or Correct! messages
        }
        
        var curr = curr
        
        curr+=1
        if curr < shuffledDeck.count {
            DispatchQueue.main.async {
                globalVars.currentWord = shuffledDeck[curr]
            }
        } else {
            //warn user game ended, show stats
            endGame("Game Over!")
            return curr
        }
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //vibrate phone
        
        return curr
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
} //end of struct

//an amazing ViewBuilder that when you wrap it around another view, it takes either a UIImage or SwiftUI image and that will be your background.
struct BackgroundImageViewModel<Content: View>: View {
    var backgroundSwiftImage: Image? = nil
    @State var backgroundUIImage: UIImage? = nil
    private var backgroundImage: Image? = nil
    
    @ViewBuilder let content: Content
    
    init(backgroundSwiftImage: Image? = nil, backgroundUIImage: UIImage? = nil, @ViewBuilder content: () -> Content) { //_ underscore means no parameter name required when declaring this struct
        if (backgroundUIImage != nil) {
            self.backgroundImage = Image(uiImage: backgroundUIImage!)
        } else if (backgroundSwiftImage != nil) {
            self.backgroundImage = backgroundSwiftImage
        }
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if (backgroundImage != nil) {
                backgroundImage!
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
                    
            } else {
                Color.purple.ignoresSafeArea(.all)
            }
            content
        }
    }
}

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

