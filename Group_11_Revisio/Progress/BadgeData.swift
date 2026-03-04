import Foundation

struct BadgeData {
    static let allMilestones: [Badging.Badge] = [
        // MARK: - Quiz Master
        Badging.Badge(id: "qm_1", title: "Novice", category: .quizMaster, tier: .bronze, goalValue: 5, detail: "Finish 5 quizzes.", earnedDate: nil),
        Badging.Badge(id: "qm_2", title: "Master", category: .quizMaster, tier: .silver, goalValue: 25, detail: "Finish 25 quizzes.", earnedDate: nil),
        Badging.Badge(id: "qm_3", title: "Legend", category: .quizMaster, tier: .gold, goalValue: 50, detail: "50 quizzes with >90% score.", earnedDate: nil),

        // MARK: - Flash Genius
        Badging.Badge(id: "fg_1", title: "Starter", category: .flashGenius, tier: .bronze, goalValue: 20, detail: "Review 20 cards.", earnedDate: nil),
        Badging.Badge(id: "fg_2", title: "Genius", category: .flashGenius, tier: .silver, goalValue: 100, detail: "Review 100 cards.", earnedDate: nil),
        Badging.Badge(id: "fg_3", title: "Memory Palace", category: .flashGenius, tier: .gold, goalValue: 500, detail: "Review 500 cards.", earnedDate: nil),

        // MARK: - Notes Creator
        Badging.Badge(id: "nc_1", title: "Scribe", category: .notesCreator, tier: .bronze, goalValue: 5, detail: "Generate 5 AI Notes.", earnedDate: nil),
        Badging.Badge(id: "nc_2", title: "Scholar", category: .notesCreator, tier: .silver, goalValue: 25, detail: "Generate 25 AI Notes.", earnedDate: nil),
        Badging.Badge(id: "nc_3", title: "Chronicler", category: .notesCreator, tier: .gold, goalValue: 100, detail: "Generate 100 AI Notes.", earnedDate: nil),

        // MARK: - Cheatsheet Pro
        Badging.Badge(id: "cp_1", title: "Minimalist", category: .cheatsheetPro, tier: .bronze, goalValue: 5, detail: "5 Cheatsheets.", earnedDate: nil),
        Badging.Badge(id: "cp_2", title: "Optimizer", category: .cheatsheetPro, tier: .silver, goalValue: 20, detail: "20 Cheatsheets.", earnedDate: nil),
        Badging.Badge(id: "cp_3", title: "Strategist", category: .cheatsheetPro, tier: .gold, goalValue: 50, detail: "50 Cheatsheets.", earnedDate: nil),

        // MARK: - Quest Seeker
        Badging.Badge(id: "qs_1", title: "Adventurer", category: .questSeeker, tier: .bronze, goalValue: 10, detail: "10 Side Quests.", earnedDate: nil),
        Badging.Badge(id: "qs_2", title: "Warrior", category: .questSeeker, tier: .silver, goalValue: 50, detail: "50 Side Quests.", earnedDate: nil),
        Badging.Badge(id: "qs_3", title: "Conqueror", category: .questSeeker, tier: .gold, goalValue: 200, detail: "200 Side Quests.", earnedDate: nil),

        // MARK: - Word Filler
        Badging.Badge(id: "wf_1", title: "Typer", category: .wordFiller, tier: .bronze, goalValue: 10, detail: "Finish 10 Word Fills.", earnedDate: nil),
        Badging.Badge(id: "wf_2", title: "Linguist", category: .wordFiller, tier: .silver, goalValue: 50, detail: "Finish 50 Word Fills.", earnedDate: nil),
        Badging.Badge(id: "wf_3", title: "Lexicographer", category: .wordFiller, tier: .gold, goalValue: 150, detail: "150 Word Fills.", earnedDate: nil),

        // MARK: - Connector
        Badging.Badge(id: "con_1", title: "Linker", category: .connector, tier: .bronze, goalValue: 10, detail: "Win 10 Connections.", earnedDate: nil),
        Badging.Badge(id: "con_2", title: "Pattern Finder", category: .connector, tier: .silver, goalValue: 50, detail: "Win 50 games.", earnedDate: nil),
        Badging.Badge(id: "con_3", title: "Mastermind", category: .connector, tier: .gold, goalValue: 150, detail: "Win 150 games.", earnedDate: nil),

        // MARK: - Daily Word
        Badging.Badge(id: "dw_1", title: "Puzzler", category: .dailyWord, tier: .bronze, goalValue: 5, detail: "Solve 5 Daily Words.", earnedDate: nil),
        Badging.Badge(id: "dw_2", title: "Solver", category: .dailyWord, tier: .silver, goalValue: 30, detail: "Solve 30 Daily Words.", earnedDate: nil),
        Badging.Badge(id: "dw_3", title: "Enigma", category: .dailyWord, tier: .gold, goalValue: 100, detail: "Solve 100 Daily Words.", earnedDate: nil),

        // MARK: - Streak Master
        Badging.Badge(id: "sm_1", title: "Habit", category: .streakMaster, tier: .bronze, goalValue: 3, detail: "3-Day Streak.", earnedDate: nil),
        Badging.Badge(id: "sm_2", title: "Dedicated", category: .streakMaster, tier: .silver, goalValue: 7, detail: "7-Day Streak.", earnedDate: nil),
        Badging.Badge(id: "sm_3", title: "Unstoppable", category: .streakMaster, tier: .gold, goalValue: 30, detail: "30-Day Streak.", earnedDate: nil),

        // MARK: - Deep Focus
        Badging.Badge(id: "df_1", title: "Initiate", category: .deepFocus, tier: .bronze, goalValue: 5, detail: "5 Focus sessions.", earnedDate: nil),
        Badging.Badge(id: "df_2", title: "Deep Diver", category: .deepFocus, tier: .silver, goalValue: 30, detail: "30 Focus sessions.", earnedDate: nil),
        Badging.Badge(id: "df_3", title: "Monk Mode", category: .deepFocus, tier: .gold, goalValue: 100, detail: "100 Focus sessions.", earnedDate: nil),

        // MARK: - Social Scholar
        Badging.Badge(id: "ss_1", title: "Team Player", category: .socialScholar, tier: .bronze, goalValue: 20, detail: "Send 20 group messages.", earnedDate: nil),
        Badging.Badge(id: "ss_2", title: "Collaborator", category: .socialScholar, tier: .silver, goalValue: 5, detail: "Join 5 study groups.", earnedDate: nil),
        Badging.Badge(id: "ss_3", title: "Leader", category: .socialScholar, tier: .gold, goalValue: 10, detail: "Start group (10 members).", earnedDate: nil),

        // MARK: - Source Master
        Badging.Badge(id: "src_1", title: "Collector", category: .sourceMaster, tier: .bronze, goalValue: 10, detail: "Upload 10 documents.", earnedDate: nil),
        Badging.Badge(id: "src_2", title: "Archivist", category: .sourceMaster, tier: .silver, goalValue: 50, detail: "Upload 50 documents.", earnedDate: nil),
        Badging.Badge(id: "src_3", title: "Librarian", category: .sourceMaster, tier: .gold, goalValue: 200, detail: "Upload 200 documents.", earnedDate: nil)
    ]
    
    static func imageName(for badge: Badging.Badge) -> String? {
        // Return your asset image name string here
        return nil
    }
}
