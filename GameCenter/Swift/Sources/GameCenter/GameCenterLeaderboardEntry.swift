//
//  GameCenterLeaderboardEntry.swift
//  GameCenter
//
//  Created by SputnikFive on 8/29/25.
//

import GameKit
import SwiftGodot

@Godot
class GameCenterLeaderboardEntry: Object {
    // MARK: - Export
    /// @Export
    /// The player's rank.
    @Export var rank: Int = 0
    /// @Export
    /// The name of the player.
    @Export var displayName: String = ""
    /// @Export
    /// The player's score.
    @Export var score: Int = 0
    
    convenience init(_ leaderboardEntry: GKLeaderboard.Entry) {
        self.init()
        self.rank = leaderboardEntry.rank
        self.displayName = leaderboardEntry.player.displayName
        self.score = leaderboardEntry.score
    }
}
