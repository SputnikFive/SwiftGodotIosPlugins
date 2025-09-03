//
//  GameCenter+AccessPoint.swift
//  GameCenter
//
//  Created by SputnikFive on 8/29/25.
//

import GameKit
import SwiftGodot

extension GameCenter {
    
    func showGameCenterInternal() {
        #if canImport(UIKit)
            viewController.showUIController(
                GKGameCenterViewController(state: .default),
                completitionHandler: { status in
                    switch status {
                    case GameCenterUIState.success.rawValue:
                        self.gameCenterShowSuccess.emit()
                    case GameCenterUIState.dismissed.rawValue:
                        self.gameCenterDismissSuccess.emit()
                    default:
                        self.gameCenterShowFail.emit(GameCenterError.unknownError.rawValue, "Unknown error")
                    }
                })
        #endif
    }

    func showOrHideAccessPointInternal(
        visible: Bool, location: Int
    ) {
        GKAccessPoint.shared.isActive = visible
        if let location = GKAccessPoint.Location(rawValue: location) {
            GKAccessPoint.shared.location = location
        }
    }
    
}
