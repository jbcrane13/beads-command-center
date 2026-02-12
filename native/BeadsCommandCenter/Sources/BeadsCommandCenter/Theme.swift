import SwiftUI

enum Theme {
    static let background = Color(red: 13/255, green: 17/255, blue: 23/255)
    static let cardBackground = Color(red: 22/255, green: 27/255, blue: 34/255)
    static let cardBorder = Color(red: 48/255, green: 54/255, blue: 61/255)
    static let accentBlue = Color(red: 88/255, green: 166/255, blue: 255/255)
    static let accentGreen = Color(red: 35/255, green: 134/255, blue: 54/255)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 139/255, green: 148/255, blue: 158/255)

    static func priorityColor(_ priority: Int) -> Color {
        switch priority {
        case 0: Color(red: 255/255, green: 123/255, blue: 114/255) // red
        case 1: Color(red: 255/255, green: 166/255, blue: 87/255)  // orange
        case 2: Color(red: 121/255, green: 192/255, blue: 255/255) // blue
        case 3: Color(red: 139/255, green: 148/255, blue: 158/255) // gray
        default: Color(red: 139/255, green: 148/255, blue: 158/255)
        }
    }

    static func statusColor(_ status: IssueStatus) -> Color {
        switch status {
        case .open: accentBlue
        case .inProgress: Color(red: 210/255, green: 153/255, blue: 34/255)
        case .blocked: Color(red: 255/255, green: 123/255, blue: 114/255)
        case .closed: accentGreen
        }
    }
}
