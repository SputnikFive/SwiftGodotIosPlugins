//
//  GameCenter+SaveGame.swift
//  GameCenter
//
//  Created by SputnikFive on 4/14/25.
//

import GameKit
import SwiftGodot

extension GameCenter {
    
    func fetchSavedGamesInternal() {
        GD.printDebug("Fetching saved games")
        GKLocalPlayer.local.fetchSavedGames(completionHandler: {
            gkSavedGames, error in
            self.fetchedSavedGames.removeAll()
            if let error {
                let localizedDescription = error.localizedDescription
                let errorDetails = localizedDescription.isEmpty ? "" :
                    ": \(localizedDescription)"
                DispatchQueue.main.async {
                    self.fetchSavedGameListFail.emit(
                        (error as NSError).code,
                        "Error fetching saved games\(errorDetails)")
                }
            } else {
                var savedGamesMetadata =
                    ObjectCollection<GameCenterSavedGameMetadata>()
                if let gkSavedGames {
                    self.fetchedSavedGames = gkSavedGames
                    for gkSavedGame in gkSavedGames {
                        savedGamesMetadata.append(
                            GameCenterSavedGameMetadata(gkSavedGame))
                    }
                }
                GD.printDebug(
                    "Loaded \(self.fetchedSavedGames.count) saved games")
                DispatchQueue.main.async {
                    self.fetchSavedGameListSuccess.emit(savedGamesMetadata)
                }
            }
        })
    }

    func saveGameInternal(saveGameName: String, saveGameDataString: String) {
        GD.printDebug("Saving game")
        guard let savedGameData = saveGameDataString.data(using: .utf8) else {
            self.gameSaveFail.emit(
                GameCenterError.unknownError.rawValue,
                "Error saving game: game data encoding failed"
            )
            return
        }
        GKLocalPlayer.local.saveGameData(savedGameData, withName: saveGameName, completionHandler: {
            _, error in
            if let error {
                let localizedDescription = error.localizedDescription
                let errorDetails = localizedDescription.isEmpty ? "" :
                ": \(localizedDescription)"
                DispatchQueue.main.async {
                    self.gameSaveFail.emit(
                        (error as NSError).code,
                        "Error saving game\(errorDetails)")
                }
            } else {
                GD.printDebug("Saved game")
                DispatchQueue.main.async {
                    self.gameSaveSuccess.emit()
                }
            }
        })
    }
    
    func loadSavedGameInternal(savedGameIndex: Int) {
        GD.printDebug("Loading saved game")
        guard savedGameIndex >= 0 &&
            savedGameIndex < self.fetchedSavedGames.count else {
                self.gameLoadFail.emit(
                    GameCenterError.unknownError.rawValue,
                    "Error loading game: index out of range"
                )
                return
        }
        let savedGame = self.fetchedSavedGames[savedGameIndex]
        savedGame.loadData(completionHandler: {
            gkSaveGameData, error in
            if let error {
                let localizedDescription = error.localizedDescription
                let errorDetails = localizedDescription.isEmpty ? "" :
                    ": \(localizedDescription)"
                DispatchQueue.main.async {
                    self.gameLoadFail.emit(
                        (error as NSError).code,
                        "Error loading game\(errorDetails)")
                }
            } else {
                guard let gkSaveGameData else {
                    DispatchQueue.main.async {
                        self.gameLoadFail.emit(
                            GameCenterError.unknownError.rawValue,
                            "Error loading game: no save game data available"
                        )
                    }
                    return
                }
                guard let saveGameString = String(data: gkSaveGameData,
                    encoding: .utf8) else {
                    DispatchQueue.main.async {
                        self.gameLoadFail.emit(
                            GameCenterError.unknownError.rawValue,
                            "Error loading game: game data decoding failed"
                        )
                    }
                    return
                }
                GD.printDebug("Loaded saved game")
                DispatchQueue.main.async {
                    self.gameLoadSuccess.emit(saveGameString)
                }
            }
        })
    }
    
    func deleteGameInternal(saveGameName: String) {
        GD.printDebug("Deleting game")
        GKLocalPlayer.local.deleteSavedGames(withName: saveGameName, completionHandler: {
            error in
            if let error {
                let localizedDescription = error.localizedDescription
                let errorDetails = localizedDescription.isEmpty ? "" :
                ": \(localizedDescription)"
                DispatchQueue.main.async {
                    self.gameDeleteFail.emit(
                        (error as NSError).code,
                        "Error deleting game\(errorDetails)")
                }
            } else {
                GD.printDebug("Deleted game")
                DispatchQueue.main.async {
                    self.gameDeleteSuccess.emit()
                }
            }
        })
    }
    
    func resolveConflictingSavedGamesInternal(conflictingGameIndexes: [Int], saveGameDataString: String) {
        GD.printDebug("Resolving save game conflict")
        guard conflictingGameIndexes.count <= conflictingSavedGames.count else {
            self.saveGameConflictResolveFail.emit(
                GameCenterError.unknownError.rawValue,
                "Error resolving conflict: too many indexes"
            )
            return
        }
        var conflictingGames = [GKSavedGame]()
        for savedGameIndex in conflictingGameIndexes {
            guard savedGameIndex >= 0 &&
                savedGameIndex < self.conflictingSavedGames.count else {
                self.saveGameConflictResolveFail.emit(
                    GameCenterError.unknownError.rawValue,
                    "Error resolving conflict: index out of range"
                )
                return
            }
            conflictingGames.append(conflictingSavedGames[savedGameIndex])
        }
        guard let savedGameData = saveGameDataString.data(using: .utf8) else {
            self.saveGameConflictResolveFail.emit(
                GameCenterError.unknownError.rawValue,
                "Error resolving conflict: game data encoding failed"
            )
            return
        }
        GKLocalPlayer.local.resolveConflictingSavedGames(conflictingGames, with: savedGameData,completionHandler: {
            _, error in
            if let error {
                let localizedDescription = error.localizedDescription
                let errorDetails = localizedDescription.isEmpty ? "" :
                    ": \(localizedDescription)"
                DispatchQueue.main.async {
                    self.saveGameConflictResolveFail.emit(
                        (error as NSError).code,
                        "Error resolving conflict\(errorDetails)")
                }
            } else {
                GD.printDebug("Conflict resolved")
                DispatchQueue.main.async {
                    self.saveGameConflictResolveSuccess.emit()
                }
            }
        })
    }
    
}
