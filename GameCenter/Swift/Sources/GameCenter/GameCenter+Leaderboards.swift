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

    func fetchLeaderboardEntriesInternal(leaderboardIDs: [String], range: NSRange) async {
        GD.printDebug("Fetching leaderboard entries")
        
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: leaderboardIDs)
            for leaderboard in leaderboards {
                
                // Get the current entries.
                let (playerEntry, entries, size) = try await leaderboard.loadEntries(
                    for: .global, timeScope: .allTime, range: range)
                var entryCollectiion = ObjectCollection<GameCenterLeaderboardEntry>()
                let sortedEntries = entries.sorted {$0.rank < $1.rank}
                for entry in sortedEntries {
                    entryCollectiion.append(GameCenterLeaderboardEntry(entry))
                }
                var leaderboardDictionary = GDictionary()
                leaderboardDictionary[Variant(
                    leaderboard.baseLeaderboardID + "-Info")] =
                    Variant(GameCenterLeaderboardInfo(leaderboard))
                leaderboardDictionary[Variant(leaderboard.baseLeaderboardID)] =
                    Variant(entryCollectiion)
                if let playerEntry {
                    leaderboardDictionary[Variant(
                        leaderboard.baseLeaderboardID + "-PlayersEntry")] =
                        Variant(GameCenterLeaderboardEntry(playerEntry))
                }
                
                // Add the previous leaderboard info, and the player's previous entry,
                // if they exist.
                let prevousLeaderboard = try await leaderboard.loadPreviousOccurrence()
                if let prevousLeaderboard,
                   let prevStartDate = prevousLeaderboard.startDate,
                   let startDate = leaderboard.startDate,
                   prevStartDate < startDate {
                    leaderboardDictionary[Variant(
                        leaderboard.baseLeaderboardID + "-PreviousInfo")] =
                        Variant(GameCenterLeaderboardInfo(prevousLeaderboard))
                    let (prevousEntry, _) = try await prevousLeaderboard.loadEntries(
                        for: [], timeScope: .allTime)
                    if let prevousEntry {
                        leaderboardDictionary[Variant(
                            leaderboard.baseLeaderboardID + "-PlayersPreviousEntry")] =
                            Variant(GameCenterLeaderboardEntry(prevousEntry))
                    }
                }
                
                DispatchQueue.main.async {
                    self.fetchLeaderboardEntriesSuccess.emit(leaderboardDictionary)
                }
            }
        } catch {
            let localizedDescription = error.localizedDescription
            let errorDetails = localizedDescription.isEmpty ? "" :
                ": \(localizedDescription)"
            DispatchQueue.main.async {
                self.fetchLeaderboardEntriesFail.emit(
                    (error as NSError).code,
                    "Error fetching leaderboard entries\(errorDetails)")
            }
        }
    }
}
