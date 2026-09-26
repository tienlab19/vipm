import GoogleMobileAds
import SwiftUI

struct AdBannerView: View {
    @Environment(AdMobService.self) private var adMob
    @State private var height: CGFloat = 0

    var body: some View {
        if adMob.canRequestAds && AdMobConfiguration.isBannerEnabled {
            GeometryReader { proxy in
                let adSize = largeAnchoredAdaptiveBanner(width: max(proxy.size.width, 320))
                BannerViewContainer(adSize: adSize, onHeightChange: { height = $0 })
                    .frame(width: adSize.size.width, height: adSize.size.height)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: height)
            .clipped()
            .background(.white)
            .animation(.easeOut(duration: 0.2), value: height)
        }
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let adSize: AdSize
    let onHeightChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = AdMobConfiguration.bannerID
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, BannerViewDelegate {
        var parent: BannerViewContainer

        init(parent: BannerViewContainer) { self.parent = parent }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            parent.onHeightChange(bannerView.adSize.size.height)
            Track.log("ad_banner_loaded")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            parent.onHeightChange(0)
            Track.log("ad_banner_load_error")
        }
    }
}
