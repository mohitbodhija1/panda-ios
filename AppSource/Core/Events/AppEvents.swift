import Foundation

extension Notification.Name {
    /// Emitted after expense create/edit succeeds so dependent screens can refresh.
    static let expenseDidMutate = Notification.Name("expenseDidMutate")
}
