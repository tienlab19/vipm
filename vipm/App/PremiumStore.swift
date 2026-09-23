import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class PremiumStore {
    static let productID = "com.viuniverse.pspo.one.premium"

    private var product: Product?
    private(set) var isPremium = false
    private(set) var isLoading = AppFeatures.inAppPurchasesEnabled
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    private(set) var message: String?

    private var isPrepared = false
    private var updatesTask: Task<Void, Never>?

    init() {
        guard AppFeatures.inAppPurchasesEnabled else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                await self.handle(result)
            }
        }
    }

    var isBusy: Bool { isLoading || isPurchasing || isRestoring }
    var displayName: String { product?.displayName ?? String(localized: "Premium lifetime access") }
    var displayPrice: String? { product?.displayPrice }

    func prepare() async {
        guard AppFeatures.inAppPurchasesEnabled else { return }
        guard !isPrepared else {
            await refreshEntitlement()
            return
        }
        isPrepared = true
        isLoading = true
        message = nil
        defer { isLoading = false }

        do {
            product = try await Product.products(for: [Self.productID]).first
            if product == nil {
                Track.log("premium_product_unavailable")
                message = String(localized: "Premium is currently unavailable. Check App Store Connect configuration and try again.")
                isPrepared = false
            }
        } catch {
            message = error.localizedDescription
            isPrepared = false
        }
        await refreshEntitlement()
    }

    func purchase() async {
        guard AppFeatures.inAppPurchasesEnabled else { return }
        guard !isPremium else { return }
        if product == nil { await prepare() }
        guard let product else {
            message = String(localized: "Premium is currently unavailable. Check App Store Connect configuration and try again.")
            return
        }

        isPurchasing = true
        message = nil
        defer { isPurchasing = false }

        do {
            switch try await product.purchase() {
            case .success(let result):
                let transaction = try verified(result)
                guard transaction.productID == Self.productID else { return }
                await transaction.finish()
                await refreshEntitlement()
            case .pending:
                message = String(localized: "Purchase is pending approval.")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func restore() async {
        guard AppFeatures.inAppPurchasesEnabled else { return }
        isRestoring = true
        message = nil
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await refreshEntitlement()
            message = isPremium
                ? String(localized: "Premium restored.")
                : String(localized: "No previous Premium purchase was found.")
        } catch {
            message = error.localizedDescription
        }
    }

    private func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.productID,
                  transaction.revocationDate == nil,
                  transaction.expirationDate.map({ $0 > .now }) ?? true else { continue }
            active = true
            break
        }
        if active != isPremium { Track.log("premium_entitlement_change", ["premium": active]) }
        isPremium = active
        if active { message = nil }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result,
              transaction.productID == Self.productID else { return }
        await transaction.finish()
        await refreshEntitlement()
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): value
        case .unverified: throw PremiumStoreError.failedVerification
        }
    }
}

private enum PremiumStoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? { String(localized: "Purchase could not be verified.") }
}
