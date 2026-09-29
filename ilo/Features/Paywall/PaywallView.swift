import SwiftUI

struct PaywallView: View {
    @Environment(PurchaseService.self) private var store
    var body: some View {
        Button("Unlock") { store.isPro = true }.buttonStyle(.pill()).padding()
    }
}
