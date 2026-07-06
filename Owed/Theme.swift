import SwiftUI

/// Owed's identity: a deep-plum/warm-gold palette — evokes a personal
/// ledger of favors between friends. Distinct from every sibling app's
/// colors (no rust/asphalt, no teal/mustard, no cobalt/lime reused).
enum OWTheme {
    static let backdrop = Color(red: 0.961, green: 0.945, blue: 0.949)   // pale blush-paper
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.918, green: 0.890, blue: 0.898)
    static let ink = Color(red: 0.216, green: 0.106, blue: 0.161)        // deep plum-ink
    static let inkFaded = Color(red: 0.216, green: 0.106, blue: 0.161).opacity(0.55)
    static let rule = Color.black.opacity(0.08)

    static let plum = Color(red: 0.427, green: 0.157, blue: 0.298)      // deep plum
    static let gold = Color(red: 0.788, green: 0.612, blue: 0.243)      // warm gold accent
    static let goldBright = Color(red: 0.878, green: 0.694, blue: 0.290)
    static let danger = Color(red: 0.702, green: 0.243, blue: 0.204)
    static let success = Color(red: 0.235, green: 0.451, blue: 0.286)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
