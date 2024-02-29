import SwiftUI
import AVFoundation
struct PhotoCaptureView: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  @Binding var selectedImage: UIImage?
  var photoViewModel: PhotoCaptureVM // Pass the ViewModel

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator
    picker.sourceType = .camera
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(photoCaptureView: self)
  }

  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var photoCaptureView: PhotoCaptureView

    init(photoCaptureView: PhotoCaptureView) {
      self.photoCaptureView = photoCaptureView
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      if let image = info[.originalImage] as? UIImage {
        self.photoCaptureView.selectedImage = image
        // Optionally handle photo processing here or in the ViewModel
        // For example, converting HEIC to JPEG if necessary
      }
      self.photoCaptureView.isPresented = false
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      self.photoCaptureView.isPresented = false
    }
  }
}




