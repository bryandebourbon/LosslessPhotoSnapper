import Foundation

class PhotoBatchManager {
  var heifBatch: [Data] = []
  var jpegBatch: [Data] = []
  let batchSize = 10 // Example batch size
  var serverURL = URL(string: "http://yourserver.com/upload")! // Your server's upload endpoint

  func addPhoto(heif: Data, jpeg: Data) {
    heifBatch.append(heif)
    jpegBatch.append(jpeg)

    if heifBatch.count >= batchSize {
      uploadBatch(heifBatch: heifBatch, jpegBatch: jpegBatch)
      heifBatch.removeAll()
      jpegBatch.removeAll()
    }
  }

  func uploadBatch(heifBatch: [Data], jpegBatch: [Data]) {
    uploadPhotos(heifBatch, format: "heif")
    uploadPhotos(jpegBatch, format: "jpeg")
  }

  private func uploadPhotos(_ photos: [Data], format: String) {
    let boundary = "Boundary-\(UUID().uuidString)"
    var request = URLRequest(url: serverURL)
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    let body = createBody(boundary: boundary, photos: photos, format: format)
    request.httpBody = body

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data, error == nil else {
        print("Error during HTTP request: \(String(describing: error))")
        return
      }
      // Handle response here
      print("Upload response: \(String(data: data, encoding: .utf8) ?? "")")
    }
    task.resume()
  }

  private func createBody(boundary: String, photos: [Data], format: String) -> Data {
    var body = Data()
    for (index, photo) in photos.enumerated() {
      body.append("--\(boundary)\r\n")
      body.append("Content-Disposition: form-data; name=\"file\(index)\"; filename=\"photo\(index).\(format)\"\r\n")
      body.append("Content-Type: image/\(format)\r\n\r\n")
      body.append(photo)
      body.append("\r\n")
    }
    body.append("--\(boundary)--\r\n")
    return body
  }
}

extension Data {
  mutating func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      append(data)
    }
  }
}


