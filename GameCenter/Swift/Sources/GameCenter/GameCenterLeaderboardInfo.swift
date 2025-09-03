//
//  GameCenterLeaderboardInfo.swift
//  GameCenter
//
//  Created by SputnikFive on 9/3/25.
//

import GameKit
import SwiftGodot

@Godot
class GameCenterLeaderboardInfo: Object {
    // MARK: - Export
    /// @Export
    /// The leaderboard's localized name.
    @Export var title: String = ""
    /// @Export
    /// The number of seconds from 1/1/1970 until the next leaderboard start.
    @Export var nextStartSeconds1970: Int = 0
    
    convenience init(_ leaderboard: GKLeaderboard) {
        self.init()
        self.title = leaderboard.title ?? ""
        if let nextStartDate = leaderboard.nextStartDate {
            self.nextStartSeconds1970 = Int(round(nextStartDate.timeIntervalSince1970))
        }
    }
}
