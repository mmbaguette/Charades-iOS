/*
 Swift class providing photo picking functions in our app.
 */

import PhotosUI
import SwiftUI

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

//sample of how this photo picker can be used with a button
#Preview {
    @Previewable @StateObject var viewModel = PhotoPickerViewModel()
    ZStack (alignment: .center) {
        Color.purple.ignoresSafeArea()
        HStack (alignment: .center) { //bottom PhotosPicker bar
            
            PhotosPicker(selection: $viewModel.imageSelection, matching: .images) { //button content
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(.white)
                    .font(.largeTitle)
            }
            
            .padding()
        }
    }
}
