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
  
  func firstAvailableSystem() async -> ScanSystem {
    while true {
      for nextSystem in systems where await nextSystem.count < 4 {
        await nextSystem.commit()
        return nextSystem
      }
      await Task.sleep(seconds: 0.1)
    }
  }
}
