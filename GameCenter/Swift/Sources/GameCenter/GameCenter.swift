//
//  GameCenterViewController.swift
//  SwiftGodotIosPlugins
//
//  Created by ZT Pawer on 12/26/24.
//

import GameKit
import SwiftGodot

#if canImport(UIKit)
    import UIKit
#endif

#initSwiftExtension(
    cdecl: "gamecenter",
    types: [
        GameCenter.self,
        GameCenterAchievement.self,
        GameCenterAchievementDescription.self,
        GameCenterPlayer.self,
        GameCenterPlayerLocal.self,
        GameCenterSavedGameMetadata.self,
        GameCenterLeaderboardEntry.self
    ]
)

enum GameCenterError: Int, Error {
    case unknownError = 1
    case notAuthenticated = 2
    case notAvailable = 3
    case failedToAuthenticate = 4
    case failedToLoadPicture = 5
    case missingIdentifier = 6
}

@Godot
class GameCenter: Object {

    // MARK: - Authentication signals
    /// @Signal
    /// Player is successfully authenticated on GameCenter
    @Signal var signinSuccess: SignalWithArguments<GameCenterPlayerLocal>
    /// @Signal
    /// Error suring the signing process
    @Signal var signinFail: SignalWithArguments<Int, String>

    // MARK: - Achievement signals
    /// @Signal
    /// Achievement(s) have been successfully reported
    @Signal var achievementsReportSuccess: SimpleSignal
    /// @Signal
    /// Error reporting the achievements
    @Signal var achievementsReportFail: SignalWithArguments<Int, String>
    /// @Signal
    /// Achievement(s) have been successfully reported
    @Signal var achievementsResetSuccess: SimpleSignal
    /// @Signal
    /// Error reporting the achievements
    @Signal var achievementsResetFail: SignalWithArguments<Int, String>
    /// @Signal
    /// Achievements have been successfully loaded
    @Signal var achievementsLoadSuccess:
        SignalWithArguments<ObjectCollection<GameCenterAchievement>>
    /// @Signal
    /// Error loading the achievements
    @Signal var achievementsLoadFail: SignalWithArguments<Int, String>
    /// @Signal
    /// Achievement(s) have been successfully reported
    @Signal var achievementsDescriptionSuccess:
        SignalWithArguments<ObjectCollection<GameCenterAchievementDescription>>
    /// @Signal
    /// Error reporting the achievements
    @Signal var achievementsDescriptionFail: SignalWithArguments<Int, String>
    
    // MARK: - Leaderboard signals
    /// @Signal
    /// Score(s) have been successfully reported
    @Signal var leaderboardScoreSuccess: SimpleSignal
    /// @Signal
    /// Error reporting the score
    @Signal var leaderboardScoreFail: SignalWithArguments<Int, String>
    /// @Signal
    /// Leaderboard has been shown
    @Signal var leaderboardSuccess: SimpleSignal
    /// @Signal
    /// Leaderboard had been dismissed
    @Signal var leaderboardDismissed: SimpleSignal
    /// @Signal
    /// Error showing the leaderboard
    @Signal var leaderboardFail: SignalWithArguments<Int, String>
    /// @Signal
    /// Returns the leaderboard entries on a successful fetch
    @Signal var fetchLeaderboardEntriesSuccess:
        SignalWithArguments<GDictionary>
    /// @Signal
    /// Error fetching the leaderboard entries list
    @Signal var fetchLeaderboardEntriesFail: SignalWithArguments<Int, String>

    // MARK: - Save & load game signals
    /// @Signal
    /// Returns the saved game metadata list on a successful fetch
    @Signal var fetchSavedGameListSuccess:
        SignalWithArguments<ObjectCollection<GameCenterSavedGameMetadata>>
    /// @Signal
    /// Error loading the saved game list
    @Signal var fetchSavedGameListFail: SignalWithArguments<Int, String>
    /// @Signal
    /// The game was successfully saved
    @Signal var gameSaveSuccess: SimpleSignal
    /// @Signal
    /// Error saving the game
    @Signal var gameSaveFail: SignalWithArguments<Int, String>
    /// @Signal
    /// Returns the saved game data as a string on a successful load
    @Signal var gameLoadSuccess: SignalWithArguments<String>
    /// @Signal
    /// Error loading the game
    @Signal var gameLoadFail: SignalWithArguments<Int, String>
    /// @Signal
    /// The game was successfully deleted
    @Signal var gameDeleteSuccess: SimpleSignal
    /// @Signal
    /// Error deleting the game
    @Signal var gameDeleteFail: SignalWithArguments<Int, String>
    /// @Signal
    /// Returns the conflicting saved game metadata list
    @Signal var hasConflictingSavedGames:
        SignalWithArguments<ObjectCollection<GameCenterSavedGameMetadata>>
    /// @Signal
    /// The save game conflict was successfully resolved
    @Signal var saveGameConflictResolveSuccess: SimpleSignal
    /// @Signal
    /// Error resolving the saved game conflict
    @Signal var saveGameConflictResolveFail: SignalWithArguments<Int, String>


    // MARK: - Properties
    #if canImport(UIKit)
        var viewController: GameCenterViewController =
            GameCenterViewController()
    #endif

    static var shared: GameCenter?
    var player: GameCenterPlayerLocal?
    var gameCenterLocalPlayerListener: GameCenterLocalPlayerListener?
    var fetchedSavedGames = [GKSavedGame]()
    var conflictingSavedGames = [GKSavedGame]()

    // MARK: - Init
    required init() {
        super.init()
        GameCenter.shared = self
        self.gameCenterLocalPlayerListener = GameCenterLocalPlayerListener()
    }

    required init(nativeHandle: UnsafeRawPointer) {
        super.init()
        GameCenter.shared = self
        self.gameCenterLocalPlayerListener = GameCenterLocalPlayerListener()
    }

    // MARK: - Authentication functions
    /// @Callable
    ///
    /// Authenticate with gameCenter.
    ///
    /// - Signals:
    ///     - signin_success: an instance of the GameCenterPlayerLocal is associated with the signal
    ///     - signin_fail: an error message is associated with the signal
    @Callable
    public func authenticate() {
        authenticateInternal()
    }

    /// @Callable
    ///
    /// - Returns:
    ///     - A Boolean value that indicates whether a local player has signed in to Game Center.
    @Callable
    func isAuthenticated() -> Bool {
        return isAuthenticatedInternal()
    }

    // MARK: - Access Point functions
    /// Show or hide the GKAccessPoint, and optionally provide its location on the screen.
    ///
    /// - Parameters:
    ///     - visible: true to show, flase to hide
    ///     - location: the screen location for the access point:
    ///         - topLeading = 0
    ///         - topTrailing = 1
    ///         - bottomLeading = 2
    ///         - bottomTrailing = 3
    ///         - the location is not set if a value outside 0-3 is passed, or no value
    @Callable
    func showOrHideAccessPoint(
        visible: Bool, location: Int = -1
    ) {
        showOrHideAccessPointInternal(visible: visible, location: location)
    }
   
    // MARK: - Achievement functions
    /// @Callable
    ///
    /// Report an array of achievements to the server. Percent complete is required. Points, completed state are set based on percentComplete. isHidden is set to NO anytime this method is invoked. Date is optional. Error will be nil on success.
    /// Possible reasons for error:
    /// 1. Local player not authenticated
    /// 2. Communications failure
    /// 3. Reported Achievement does not exist
    ///
    /// - Signals:
    ///     - achievements_report_success: a signal with no parameters is raised
    ///     - achievements_report_fail: an error message is associated with the signal
    @Callable
    func reportAchievements(
        _ achievements: [GameCenterAchievement]
    ) {
        reportAchievementsInternal(achievements)
    }

    /// @Callable
    /// Reset the achievements progress for the local player. All the entries for the local player are removed from the server. Error will be nil on success.
    /// Possible reasons for error:
    /// 1. Local player not authenticated
    /// 2. Communications failure
    ///
    /// - Signals:
    ///     - achievements_reset_success: a signal with no parameters is raised
    ///     - achievements_reset_fail: an error message is associated with the signal
    @Callable
    func resetAchievements() {
        resetAchievementsInternal()
    }

    /// @Callable
    ///
    /// Load all achievements for the local player
    ///
    /// - Signals:
    ///     - achievements_load_success: the list of achievements for the local player with the signal
    ///     - achievements_load_fail: an error message is associated with the signal
    @Callable
    func loadAchievements() {
        loadAchievementsInternal()
    }

    /// @Callable
    /// Load all achievement descriptions
    ///
    /// - Signals:
    ///     - achievements_description_success: the list of description is associated with the signal
    ///     - achievements_descritpion_fail: an error message is associated with the signal
    @Callable
    func loadAchievementDescriptions() {
        loadAchievementDescriptionsInternal()
    }

    /// Show GameCenter leaderboard display.
    ///
    /// - Signals:
    ///     - leaderboard_shown: a signal with no parameters is raised
    ///     - leaderboard_dismissed: a signal with no parameters is raised
    ///     - leaderboard_fail: an error message is associated with the signal
    @Callable
    func showAchievements() {
        showAchievementsInternal()
    }

    /// Show GameCenter leaderboard for a specific achievement.
    ///
    /// - Parameters:
    ///     - leaderboardID: The identifier for the leaderboard that you enter in App Store Connect.
    ///
    /// - Signals:
    ///     - leaderboard_shown: a signal with no parameters is raised
    ///     - leaderboard_dismissed: a signal with no parameters is raised
    ///     - leaderboard_fail: an error message is associated with the signal
    @Callable
    func showAchievement(achievementID: String) {
        showAchievementInternal(achievementID: achievementID)
    }

    // MARK: - Leaderboard functions
    /// @Callable
    ///
    /// Instance method to submit a single score to the leaderboard associated with this instance
    ///   score - earned by the player
    ///   leaderboardIds - to which the score should be submitted
    ///   context - developer supplied metadata associated with the player's score
    ///
    /// - Signals:
    ///     - achievements_report_success: a signal with no parameters is raised
    ///     - achievements_report_fail: an error message is associated with the signal
    @Callable
    func submitScore(
        score: Int, leaderboardIDs: [String], context: Int
    ) {
        submitScoreInternal(
            score, context: context,
            player: GKLocalPlayer.local,
            leaderboardIDs: leaderboardIDs)
    }

    /// Show GameCenter leaderboards display.
    ///
    /// - Signals:
    ///     - leaderboard_shown: a signal with no parameters is raised
    ///     - leaderboard_dismissed: a signal with no parameters is raised
    ///     - leaderboard_fail: an error message is associated with the signal
    @Callable
    func showLeaderboards() {
        showLeaderboardsInternal()
    }

    /// Show GameCenter leaderboard for a specific leaderboard.
    ///
    /// - Parameters:
    ///     - leaderboardID: The identifier for the leaderboard that you enter in App Store Connect.
    ///
    /// - Signals:
    ///     - leaderboard_shown: a signal with no parameters is raised
    ///     - leaderboard_dismissed: a signal with no parameters is raised
    ///     - leaderboard_fail: an error message is associated with the signal
    @Callable
    func showLeaderboard(leaderboardID: String) {
        showLeaderboardInternal(leaderboardID: leaderboardID)
    }
    
    /// Fetch the leaderboard entries for the passed leaderboards and range.
    ///
    /// - Parameters:
    ///     - leaderboardIDs: array of identifiers for the leaderboards in App Store Connect
    ///     - firstEntryNumber: the first entry number to fetch
    ///     - totalEntries: the number of entries to fetch
    ///
    /// - Signals:
    ///     - fetchLeaderboardEntriesSuccess: A dictionary with the leaderboardID as the key, and list of enties as the value.
    ///       Will return a separate dictionary in a separate signal for each leaderboardID.
    ///     - fetchLeaderboardEntriesFail: An error message is associated with the signal.
    ///       Will return a separate error in a separate signal for each leaderboardID.
    @Callable
    func fetchLeaderboardEntries(leaderboardIDs: [String], firstEntryNumber: Int, totalEntries: Int) {
        let range = NSRange(location: firstEntryNumber, length: totalEntries)
        fetchLeaderboardEntriesInternal(leaderboardIDs: leaderboardIDs, range: range)
    }
    
    // MARK: - Save & load game functions
    /// @Callable
    ///
    /// Fetch all saved games.
    ///
    /// - Signals:
    ///     - fetchSavedGameListSuccess: returns the saved game metadata list
    ///     - fetchSavedGameListFail: returns an error code & message
    @Callable
    func fetchSavedGames() {
        fetchSavedGamesInternal()
    }
    
    /// @Callable
    ///
    /// Save the passed game.
    ///
    /// - Signals:
    ///     - gameSaveSuccess: a signal with no parameters is raised
    ///     - gameSaveFail: returns an error code & message
    @Callable
    func saveGame(saveGameName: String, saveGameDataString: String) {
        saveGameInternal(
            saveGameName: saveGameName,
            saveGameDataString: saveGameDataString)
    }

    /// @Callable
    ///
    /// Load the saved game with the passed index.
    ///
    /// - Signals:
    ///     - gameLoadSuccess: returns the saved game as a string
    ///     - gameLoadFail: returns an error code & message
    @Callable
    func loadSavedGame(savedGameIndex: Int) {
        loadSavedGameInternal(savedGameIndex: savedGameIndex)
    }
    
    /// @Callable
    ///
    /// Delete the saved game(s) with the passed name.
    ///
    /// - Signals:
    ///     - gameDeleteSuccess: a signal with no parameters is raised
    ///     - gameDeleteFail: returns an error code & message
    @Callable
    func deleteGame(saveGameName: String) {
        deleteGameInternal(saveGameName: saveGameName)
    }

    /// @Callable
    ///
    /// Resolve a saved game conflict.  Pass the conflicting game indexes,
    /// and the correct save game data string.
    ///
    /// - Signals:
    ///     - saveGameConflictResolveSuccess: a signal with no parameters is raised
    ///     - saveGameConflictResolveFail: returns an error code & message
    func resolveConflictingSavedGames(conflictingGameIndexesGArray: GArray,
        saveGameDataString: String) {
        var conflictingGameIndexes = [Int]()
        for conflictingGameIndex in conflictingGameIndexesGArray {
            guard let conflictingGameIndex = conflictingGameIndex as? Int else {
                saveGameConflictResolveFail.emit(
                    GameCenterError.unknownError.rawValue,
                    "Error resolving conflict: non-int index")
                return
            }
            conflictingGameIndexes.append(conflictingGameIndex)
        }
        resolveConflictingSavedGamesInternal(
            conflictingGameIndexes: conflictingGameIndexes,
            saveGameDataString: saveGameDataString)
    }

}
