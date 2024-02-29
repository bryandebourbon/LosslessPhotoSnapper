import AVFoundation
import Combine
import UIKit

class PhotoCaptureVM: NSObject, ObservableObject {
  var captureSession: AVCaptureSession?
  var photoOutput = AVCapturePhotoOutput()
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  @Published var capturedImage: UIImage?

  let SERVER_URL = "http://10.0.0.229:3000/upload"

  override init() {
    super.init()
    checkPermissions()
    setupCaptureSession()
  }

  private func checkPermissions() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      break
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
          self.setupCaptureSession()
        }
      }
    default:
      print("Camera access denied")
    }
  }

  private func setupCaptureSession() {
    DispatchQueue.global(qos: .userInitiated).async {
      self.captureSession = AVCaptureSession()
      guard let captureSession = self.captureSession,
        let backCamera = AVCaptureDevice.default(
          .builtInWideAngleCamera, for: .video, position: .back)
      else { return }

      do {
        let input = try AVCaptureDeviceInput(device: backCamera)
        if captureSession.canAddInput(input) && captureSession.canAddOutput(self.photoOutput) {
          captureSession.addInput(input)
          captureSession.addOutput(self.photoOutput)
          captureSession.startRunning()
        }
      } catch {
        print("Failed to set up capture session input: \(error)")
      }
    }
  }

  func startSession() {
    if let captureSession = self.captureSession, !captureSession.isRunning {
      captureSession.startRunning()
    }
  }

  func stopSession() {
    if let captureSession = self.captureSession, captureSession.isRunning {
      captureSession.stopRunning()
    }
  }

  func capturePhoto() {
    let settings = AVCapturePhotoSettings()
    photoOutput.capturePhoto(with: settings, delegate: self)
  }

  func uploadImageToServer(imageData: Data) {
    let uploadURL =  URL(string: "http://10.0.0.229:3000/upload")!

    // Generate boundary string for multipart/form-data request
    let boundary = "Boundary-\(UUID().uuidString)"

    var request = URLRequest(url: uploadURL)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    // Construct multipart/form-data body
    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

    // Use URLSession to send the request
    URLSession.shared.uploadTask(with: request, from: body) { responseData, response, error in
      if let error = error {
        print("Upload error: \(error.localizedDescription)")
        return
      }

      guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        print("Non-200 response from server")
        return
      }

      print("Upload successful")
    }.resume()
  }



}

extension PhotoCaptureVM: AVCapturePhotoCaptureDelegate {
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let photoData = photo.fileDataRepresentation() else {
      print("Could not get photo data representation")
      return
    }

    // Upload the image after capture
    uploadImageToServer(imageData: photoData)
  }
}

extension PhotoCaptureVM {
  func setupLivePreview(in view: UIView) {
    guard let captureSession = self.captureSession else { return }

    // Create and add the videoPreviewLayer on the main thread since it updates the UI
    DispatchQueue.main.async {
      self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      self.videoPreviewLayer?.videoGravity = .resizeAspectFill
      self.videoPreviewLayer?.frame = view.bounds
      if let previewLayer = self.videoPreviewLayer {
        view.layer.addSublayer(previewLayer)
      }
    }

    // Start the capture session on a background thread
    DispatchQueue.global(qos: .userInitiated).async {
      captureSession.startRunning()
    }
  }
}


