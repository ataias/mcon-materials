//
//  ScanSystem.swift
//  Sky (iOS)
//
//  Created by Ataias Pereira Reis on 26/01/22.
//

import Foundation

actor ScanSystem {
  let name: String
  let service: ScanTransport?
  
  init(name: String, service: ScanTransport? = nil) {
    self.name = name
    self.service = service
  }
  
  /// Counted of committed tasks; i.e.: tasks the actor accounts for but may not have started yet as "run" may not have been called yet
  private(set) var count = 0
  
  func commit() {
    count += 1
  }
  
  func run(_ task: ScanTask) async throws -> String {
    defer { count -= 1}
    return try await task.run()
  }
}
