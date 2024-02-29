import SwiftUI

struct CameraView: View {
  @ObservedObject var photoCaptureVM = PhotoCaptureVM()

  var body: some View {
    ZStack(alignment: .bottom) {
      CameraPreview(photoCaptureVM: photoCaptureVM)
        .edgesIgnoringSafeArea(.all)

      CaptureButton(action: {
        photoCaptureVM.capturePhoto()
      })
      .padding(.bottom)
    }
    .onAppear {
      photoCaptureVM.startSession()
    }
    .onDisappear {
      photoCaptureVM.stopSession()
    }
  }
}

struct CameraPreview: UIViewRepresentable {
  @ObservedObject var photoCaptureVM: PhotoCaptureVM

  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: UIScreen.main.bounds)
    photoCaptureVM.setupLivePreview(in: view)
    return view
  }


  func updateUIView(_ uiView: UIView, context: Context) {}
}

struct CaptureButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "camera.circle")
        .font(.system(size: 70))
        .foregroundColor(.white)
    }
    .background(Color.black.opacity(0.5))
    .clipShape(Circle())
    .padding()
  }
}
