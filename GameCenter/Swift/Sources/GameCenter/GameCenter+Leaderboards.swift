//
//  GameCenter+Leaderboards.swift
//  GameCenter
//
//  Created by ZT Pawer on 12/28/24.
//

import GameKit
import SwiftGodot

extension GameCenter {

    func submitScoreInternal(
        _ score: Int, context: Int, player: GKPlayer,
        leaderboardIDs: [String]
    ) {
        guard GKLocalPlayer.local.isAuthenticated == true else {
            self.leaderboardScoreFail.emit(
                GameCenterError.notAuthenticated.rawValue,
                "Player is not authenticated")
            return
        }
        
        GKLeaderboard.submitScore(
            score, context: context, player: player,
            leaderboardIDs: leaderboardIDs,
            completionHandler: { error in
                guard error == nil else {
                    self.leaderboardScoreFail.emit(
                        (error! as NSError).code,
                        "Error while resetting achievements")
                    return
                }
                self.leaderboardScoreSuccess.emit()
            })
    }

    func showLeaderboardsInternal() {
        #if canImport(UIKit)
            viewController.showUIController(
                GKGameCenterViewController(state: .leaderboards),
                completitionHandler: { status in
                    switch status {
                    case GameCenterUIState.success.rawValue:
                        self.leaderboardSuccess.emit()
                    case GameCenterUIState.dismissed.rawValue:
                        self.leaderboardDismissed.emit()
                    default:
                        self.leaderboardFail.emit(GameCenterError.unknownError.rawValue, "Unknown error")
                    }
                })
        #endif
    }

    func showLeaderboardInternal(leaderboardID: String) {
        #if canImport(UIKit)
            viewController.showUIController(
                GKGameCenterViewController(
                    leaderboardID: leaderboardID,
                    playerScope: .global,
                    timeScope: .allTime
                ),
                completitionHandler: { status in
                    switch status {
                    case GameCenterUIState.success.rawValue:
                        self.leaderboardSuccess.emit()
                    case GameCenterUIState.dismissed.rawValue:
                        self.leaderboardDismissed.emit()
                    default:
                        self.leaderboardFail.emit(GameCenterError.unknownError.rawValue, "Unknown error")
                    }
                })
        #else
            leaderboardFail.emit(
                GameCenterError.notAvailable.rawValue,
                "Leaderboard not available")
        #endif
    }
    
    func fetchLeaderboardEntriesInternal(leaderboardIDs: [String], range: NSRange) {
        GD.printDebug("Fetching leaderboard entries")
        
        GKLeaderboard.loadLeaderboards(IDs: leaderboardIDs, completionHandler: {
            leaderboards, error in
            if let error {
                let localizedDescription = error.localizedDescription
                let errorDetails = localizedDescription.isEmpty ? "" :
                    ": \(localizedDescription)"
                DispatchQueue.main.async {
                    self.fetchLeaderboardEntriesFail.emit(
                        (error as NSError).code,
                        "Error fetching leaderboard entries\(errorDetails)")
                }
            } else {
                if let leaderboards {
                    for leaderboard in leaderboards {
                        leaderboard.loadEntries(for: .global, timeScope: .allTime,
                        range: range, completionHandler: {
                           playerEntry, entries, size, error  in
                            if let error {
                                let localizedDescription = error.localizedDescription
                                let errorDetails = localizedDescription.isEmpty ? "" :
                                    ": \(localizedDescription)"
                                DispatchQueue.main.async {
                                    self.fetchLeaderboardEntriesFail.emit(
                                        (error as NSError).code,
                                        "Error fetching leaderboard entries\(errorDetails)")
                                }
                            } else {
                                var entryCollectiion = ObjectCollection<GameCenterLeaderboardEntry>()
                                if let entries {
                                    let sortedEntries = entries.sorted {$0.rank < $1.rank}
                                    for entry in sortedEntries {
                                        entryCollectiion.append(GameCenterLeaderboardEntry(entry))
                                    }
                                }
                                var leaderboardDictionary = GDictionary()
                                leaderboardDictionary[Variant(leaderboard.baseLeaderboardID)] =
                                    Variant(entryCollectiion)
                                let rank = playerEntry?.rank ?? -1
                                leaderboardDictionary[Variant(
                                    leaderboard.baseLeaderboardID + "-PlayersRank")] = Variant(rank)
                                self.fetchLeaderboardEntriesSuccess.emit(leaderboardDictionary)
                           }
                        })
                    }
                } else {
                    self.fetchLeaderboardEntriesFail.emit(
                            GameCenterError.unknownError.rawValue, "No leaderbaords loaded")
                }
            }
        })
    }
}
