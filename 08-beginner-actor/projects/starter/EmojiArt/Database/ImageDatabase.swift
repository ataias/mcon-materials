import UIKit

@globalActor actor ImageDatabase {
  static let shared = ImageDatabase()
  
  let imageLoader = ImageLoader()
  
  private var storage: DiskStorage!
  private var storedImagesIndex = [String]()
  
  @MainActor private(set) var inDiskAccess: AsyncStream<Int>?
  private var inDiskAccessContinuation: AsyncStream<Int>.Continuation?
  private var inDiskAccessCounter = 0 {
    didSet { inDiskAccessContinuation?.yield(inDiskAccessCounter) }
  }
  
  func setUp() async throws {
    storage = await DiskStorage()
    for fileURL in try await storage.persistedFiles() {
      storedImagesIndex.append(fileURL.lastPathComponent)
    }
    let inDiskAccessStream = AsyncStream<Int> { continuation in
      inDiskAccessContinuation = continuation
    }
    await MainActor.run {
      inDiskAccess = inDiskAccessStream
    }
    
    await imageLoader.setUp()
  }
  
  func store(image: UIImage, forKey key: String) async throws {
    guard let data = image.pngData() else {
      throw "Could not save image \(key)"
    }
    
    let fileName = DiskStorage.fileName(for: key)
    try await storage.write(data, name: fileName)
    storedImagesIndex.append(fileName)
  }
  
  func image(_ key: String) async throws -> UIImage {
    if await imageLoader.cache.keys.contains(key) {
      print("Cached in-memory")
      return try await imageLoader.image(key)
    }
    
    do {
      let fileName = DiskStorage.fileName(for: key)
      if !storedImagesIndex.contains(fileName) {
        throw "Image not persisted"
      }
      
      let data = try await storage.read(name: fileName)
      guard let image = UIImage(data: data) else {
        throw "Invalid image data"
      }
      print("Cached on disk")
      inDiskAccessCounter += 1
      await imageLoader.add(image, forKey: key)
      return image
      
    } catch {
      let image = try await imageLoader.image(key)
      try await store(image: image, forKey: key)
      return image
    }
  }
  
  func clear() async {
    for name in storedImagesIndex {
      try? await storage.remove(name: name)
    }
    storedImagesIndex.removeAll()
  }
  
  func clearInMemoryAssets() async {
    await imageLoader.clear()
  }
}
