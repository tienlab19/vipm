import Foundation
import GoogleMobileAds
import Observation
import UserMessagingPlatform

enum AdMobConfiguration {
    static let testAppID = "ca-app-pub-3940256099942544~1458002511"
    static let testBannerID = "ca-app-pub-3940256099942544/2435281174"
    static let testInterstitialID = "ca-app-pub-3940256099942544/4411468910"

    private static var configuredBannerID: String {
        Bundle.main.object(forInfoDictionaryKey: "AdMobBannerUnitID") as? String ?? ""
    }

    private static var configuredInterstitialID: String {
        Bundle.main.object(forInfoDictionaryKey: "AdMobInterstitialUnitID") as? String ?? ""
    }

    static var bannerID: String {
        return configuredBannerID
    }

    static var interstitialID: String {
        return configuredInterstitialID
    }

    private static var isAppEnabled: Bool {
#if DEBUG
        return false
#else
        guard AppFeatures.adsEnabled,
              let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
              !appID.isEmpty else { return false }
        return appID != testAppID
#endif
    }

    static var isBannerEnabled: Bool {
        guard isAppEnabled else { return false }
        return !configuredBannerID.isEmpty && configuredBannerID != testBannerID
    }

    static var isInterstitialEnabled: Bool {
        guard isAppEnabled else { return false }
        return !configuredInterstitialID.isEmpty && configuredInterstitialID != testInterstitialID
    }

    static var isEnabled: Bool { isBannerEnabled || isInterstitialEnabled }
}

@MainActor
@Observable
final class AdMobService: NSObject, FullScreenContentDelegate {
    private(set) var canRequestAds = false
    private(set) var privacyOptionsRequired = false
    private var prepared = false
    private var isPremium = false
    private var interstitialAd: InterstitialAd?
    private var isLoadingInterstitial = false

    func prepare(isPremium: Bool) async {
        updatePremiumStatus(isPremium)
        guard AdMobConfiguration.isEnabled, AppFeatures.shouldShowAds(isPremium: isPremium), !prepared else { return }
        prepared = true

        do {
            try await updateConsentInformation()
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            Track.log("ad_consent_error")
        }

        refreshConsentState()
        guard canRequestAds else { return }

        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        await MobileAds.shared.start()
        await loadInterstitial()
    }

    func updatePremiumStatus(_ isPremium: Bool) {
        self.isPremium = isPremium
        if isPremium {
            canRequestAds = false
            interstitialAd = nil
        } else if prepared {
            refreshConsentState()
            if canRequestAds { Task { await loadInterstitial() } }
        }
    }

    func presentExamResultInterstitial() {
        guard canRequestAds, AdMobConfiguration.isInterstitialEnabled, let interstitialAd else {
            Task { await loadInterstitial() }
            return
        }
        self.interstitialAd = nil
        interstitialAd.present(from: nil)
        Track.log("ad_interstitial_present")
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            Track.log("ad_privacy_options_error")
        }
        refreshConsentState()
    }

    private func updateConsentInformation() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    private func refreshConsentState() {
        canRequestAds = AppFeatures.canRequestAds(
            isPremium: isPremium,
            consentAllowsAds: ConsentInformation.shared.canRequestAds
        )
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private func loadInterstitial() async {
        guard canRequestAds, AdMobConfiguration.isInterstitialEnabled,
              interstitialAd == nil, !isLoadingInterstitial else { return }
        isLoadingInterstitial = true
        defer { isLoadingInterstitial = false }
        do {
            let ad = try await InterstitialAd.load(with: AdMobConfiguration.interstitialID, request: Request())
            guard canRequestAds, !isPremium else { return }
            ad.fullScreenContentDelegate = self
            interstitialAd = ad
            Track.log("ad_interstitial_loaded")
        } catch {
            Track.log("ad_interstitial_load_error")
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Track.log("ad_interstitial_dismissed")
        Task { await loadInterstitial() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Track.log("ad_interstitial_present_error")
        Task { await loadInterstitial() }
    }
}
