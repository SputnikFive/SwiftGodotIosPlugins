//
//  GameCenterSavedGameMetadata.swift
//  GameCenter
//
//  Created by SputnikFive on 4/14/25.
//

import GameKit
import SwiftGodot

#if canImport(Foundation)
    import Foundation
#endif

@Godot
class GameCenterSavedGameMetadata: Object {
    // MARK: Export
    /// @Export
    /// The name of the saved game.
    @Export var name: String = ""
    /// @Export
    /// The date the game data was last saved or modified.
    /// The number of seconds passed since 1970-01-01 at 00:00:00 UTC.
    @Export var modificationDate: Float = 0.0
    /// @Export
    /// The name of the device that the player used to save the game.
    @Export var deviceName: String = ""
}
