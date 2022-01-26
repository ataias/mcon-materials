//
//  Systems.swift
//  Sky (iOS)
//
//  Created by Ataias Pereira Reis on 26/01/22.
//

import Foundation

actor Systems {
  private(set) var systems: [ScanSystem]
  var localSystem: ScanSystem { systems[0] }
  
  init(_ localSystem: ScanSystem) {
    systems = [localSystem]
  }
  
  func addSystem(name: String, service: ScanTransport) {
    removeSystem(name: name)
    let newSystem = ScanSystem(name: name, service: service)
    systems.append(newSystem)
  }
  
  func removeSystem(name: String) {
    systems.removeAll { $0.name == name }
  }
}
