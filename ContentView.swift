//
//  ContentView.swift
//  Charades
//
//  Created by Ali Mohammed-Ali on 2024-08-29.
//

import SwiftUI
import CoreMotion
import AudioToolbox
import PhotosUI

/*
 -
 */

@MainActor
final class PhotoPickerViewModel: ObservableObject {
    
    @Published private(set) var selectedImage: UIImage? = nil
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            setImage(from: imageSelection)
        }
    }
    
    private func setImage(from selection: PhotosPickerItem?) {
        guard let selection else { return }
        
        Task {
            if let data = try? await selection.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                    return
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = PhotoPickerViewModel()
    let manager = CMMotionManager()
    let queue = OperationQueue()
    let wordDisplayQueue = OperationQueue() //queue that decides whether the current word, "Correct!", or "Skip!", or the next word is shown during a game
    
    private let rotationChangePublisher = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
    
    //background vars that the game controls
    @State var gameMode: Bool = false //whether a game is in sessions
    @State var pitchIsReset = false //whether the user has held their phone back up straight
    @State var lastWordWasCorrect = true //whether the last word held up by the user was guessed correctly or skipped
    @State var showWordFeedback = false //whether we're displaying the current word or "Correct!" or "Skip!" to be used in withAnimation
    @State var startingGame = false //whether we're starting a new game (user clicked start)
    @State var showCountdown = false
    @State var chosenDeck: String = "" //the name of the deck in the decks.txt file
    @State var words: [String] = []
    
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
    
    var body: some View {
        ZStack {
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
                 //what is only displayed on the home screen
                Button(action: {
                    if words.count > 0 {
                        //animate the start button to go down
                        withAnimation (.easeIn(duration: 0.5)) {
                            startingGame = true
                        } completion: { //start the game when the button leaves the screen
                            changeOrientation(to: .landscapeLeft)
                            gameMode = true
                            startingGame = false
                        } //end of withAnimation completion
                    } //end of button action
                }, label: {
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
                .alert(errorTitle, isPresented: $showUserAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage)
                }
                .fullScreenCover(isPresented: $gameMode, content: {
                    GameScreen(showWordFeedback: $showWordFeedback, lastWordWasCorrect: $lastWordWasCorrect, currentWord: $currentWord, wins: $wins, skipped: $skipped)
                })
                    
                HStack {
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
        .onAppear {
            changeOrientation(to: .portrait) //make sure phone is in portrait mode in the beginning
            
            chosenDeck = "People" //chose default temporary deck
            
            guard readDeckFromFile(deckFile: deckFileName, deckName: chosenDeck) else {return} //make sure the program can actually fetch the deck from the local file storage, or the game can't function at all!
            
            currentWord = chooseRandomWord() //set first word
            
            manager.startDeviceMotionUpdates(to: self.queue) { (data: CMDeviceMotion?, error: Error?) in
                let attitude = data!.attitude
                
                if gameMode {
                    if Double(attitude.roll) >= (3*Double.pi/4) && pitchIsReset { // 3/4 of pi, rolled phone forwards to indicate "Correct!"
                        wins = wins + 1
                        currentWord = chooseRandomWord()
                        pitchIsReset = false
                        
                        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }//vibrate phone
                        
                        //display "Correct!" then make it fade out
                        showWordFeedback = true
                        lastWordWasCorrect = true
                        withAnimation(.easeOut(duration: 0.2).delay(0.6)) {
                            showWordFeedback = false
                        }
                    } else if Double(attitude.roll) <= (1*Double.pi/4) && Double(attitude.roll) > 0 && pitchIsReset { //rolled phone backwards to skip
                        skipped = skipped + 1
                        currentWord = chooseRandomWord()
                        pitchIsReset = false
                        
                        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }//vibrate phone
                        
                        //display "Skip!" then have it fade out
                        showWordFeedback = true
                        lastWordWasCorrect = false
                        withAnimation(.easeOut(duration: 0.2).delay(0.6)) {
                            showWordFeedback = false
                        }
                    }
                    else if Double(attitude.roll) < (3*Double.pi/4) && Double(attitude.roll) > (1*Double.pi/4) { //user rolled phone back up after rolling it down (between 1/4 and 3/4 of pi)
                        pitchIsReset = true
                    }
                } //end of if gameMode
            } //end of startDeviceMotionUpdates
            
        } //end of .onAppear
    } //end of var body: some View
     
    func readDeckFromFile(deckFile: String, deckName: String) -> Bool { //scans the given deck with the file name and deck name, returns success?
        let path = Bundle.main.path(forResource: deckFile, ofType: "txt") //find the file given the file path

        if (path != nil) {
            do {
                let fileContents: String = try String(contentsOfFile: path!, encoding: .utf8)
                if let i = fileContents.range(of: chosenDeck+":") {
                    
                    let nextDeckIndex = fileContents[i.upperBound...].firstIndex(of: ":") ?? fileContents.endIndex //the end of this deck
                    let deckStringContents = fileContents[i.upperBound...nextDeckIndex]
                                        
                    for cardSubstring in deckStringContents.split(separator: "\n") {
                        let cardString = String(cardSubstring)
                        if !cardString.hasSuffix(":") {
                            words.append(cardString)
                        }
                    }
                } else {
                    alertUser(message: "The given deck cannot be found!")
                    return false
                } //end of if let i
            } catch {
                alertUser(message: "Error: \(error)")
                return false
            }
        } else {
            alertUser(message: "The given file path \(deckFile) is not found!")
            return false
        }
         
        return true //success
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

struct GameScreen: View {
    @Environment(\.dismiss) var dismissScreen
    
    @Binding var showWordFeedback: Bool
    @Binding var lastWordWasCorrect: Bool
    @Binding var currentWord: String
    @Binding var wins: Int
    @Binding var skipped: Int
    
    var body: some View {
        ZStack {
            Color.purple.ignoresSafeArea()
            VStack {
                CharadesTitle()
                Spacer()
                if showWordFeedback { //currently showing "Correct!" or "Skip!" label
                    Text(lastWordWasCorrect ? "Correct!" : "Skip!")
                        .font(.system(size: 70))
                        .foregroundStyle(.white)
                        .bold()
                        .opacity(showWordFeedback ? 1.0 : 0)
                } else { //Display Current Word
                    Text(currentWord)
                        .font(.system(size: 70))
                        .foregroundStyle(.white)
                        .bold()
                        .shadow(color: .white, radius: 6, x: 5, y: 5)
                }
                Spacer() //Display wins
                Text("Correct: \(wins)   Skipped: \(skipped)")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .bold()
                    .padding()
            }
        }
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
//    @State var showWordFeedback = false
//    @State var lastWordWasCorrect = false
//    @State var currentWord = "Joe Biden"
//    @State var wins = 0
//    @State var skipped = 0
//    
//    GameScreen(showWordFeedback: $showWordFeedback, lastWordWasCorrect: $lastWordWasCorrect, currentWord: $currentWord, wins: $wins, skipped: $skipped)
    
    ContentView()
}

