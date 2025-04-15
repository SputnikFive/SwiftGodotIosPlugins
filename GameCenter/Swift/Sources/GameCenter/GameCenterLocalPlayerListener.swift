//
//  GameCenterLocalPlayerListener.swift
//  GameCenter
//
//  Created by SputnikFive on 4/15/25.
//

import GameKit
import SwiftGodot

class GameCenterLocalPlayerListener: NSObject, GKLocalPlayerListener {
    
    func player(_ player: GKPlayer,
        hasConflictingSavedGames gkSavedGames: [GKSavedGame]) {
            var savedGamesMetadata =
                ObjectCollection<GameCenterSavedGameMetadata>()
            GameCenter.shared?.conflictingSavedGames = gkSavedGames
            for gkSavedGame in gkSavedGames {
                savedGamesMetadata.append(
                    GameCenterSavedGameMetadata(gkSavedGame))
            }
            GD.printDebug("Conflict with \(gkSavedGames.count) saved games")
            DispatchQueue.main.async {
                GameCenter.shared?.hasConflictingSavedGames.emit(
                    savedGamesMetadata)
            }
    }
    
    override init() {
        super.init()
        GKLocalPlayer.local.register(self)
    }
    
    deinit {
        GKLocalPlayer.local.unregisterListener(self)
    }
}
