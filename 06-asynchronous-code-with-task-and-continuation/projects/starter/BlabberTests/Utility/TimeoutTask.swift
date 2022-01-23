//
//  TimeoutTask.swift
//  BlabberTests
//
//  Created by Ataias Pereira Reis on 23/01/22.
//

import Foundation

class TimeoutTask<Success> {
  let nanoseconds: UInt64
  let operation: @Sendable () async throws -> Success
  private var continuation: CheckedContinuation<Success, Error>?
  
  init(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> Success
  ) {
    self.nanoseconds = UInt64(seconds * 1e9)
    self.operation = operation
  }
  
  var value: Success {
    get async throws {
      try await withCheckedThrowingContinuation({ continuation in
        self.continuation = continuation
        Task { // timeout
          try await Task.sleep(nanoseconds: nanoseconds)
          self.continuation?.resume(throwing: TimeoutError())
          self.continuation = nil
        }
        Task { // the actual work
          let result = try await operation()
          self.continuation?.resume(returning: result)
          self.continuation = nil
        }
      })
    }
  }
  
  func cancel() {
    continuation?.resume(throwing: CancellationError())
    continuation = nil
  }
}

extension TimeoutTask {
  struct TimeoutError: LocalizedError {
    var errorDescription: String? {
      return "The operation timed out."
    }
  }
}
