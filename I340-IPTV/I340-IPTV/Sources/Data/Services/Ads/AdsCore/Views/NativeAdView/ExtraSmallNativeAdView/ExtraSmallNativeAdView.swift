//
//  ExtraSmallNativeAdView.swift
//  I340_IPTV
//

import UIKit
import GoogleMobileAds

/// Figma "Native Ads_ExtraSmall" (375×71): "Ad" badge, 36pt icon, headline + two-line body and
/// a 100×32 call-to-action, on a white background. No media view, so it suits the no-media unit.
class ExtraSmallNativeAdView: UIView, NativeAdViewProtocol {
    /// Slot height of the design.
    static let height: CGFloat = 71

    private let nativeAdView = NativeAdView()
    private let iconView = UIImageView()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let ctaButton = UIButton(type: .custom)
    private let adBadge = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        if !Configs.Advertisement.canRequestAndShowAds || IAPHelper.shared().isSubscribed() {
            gone()
            return
        }

        IAPHelper.shared().subscriptionSucceed { [weak self] isPurchased in
            if isPurchased {
                self?.gone()
            }
        }

        backgroundColor = .white
        buildLayout()
        isHidden = true
    }

    private func buildLayout() {
        nativeAdView.backgroundColor = .white
        nativeAdView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nativeAdView)

        iconView.contentMode = .scaleAspectFill
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true

        let headlineFont: UIFont = FontFamily.Poppins.semiBold.font(size: 14)
        headlineLabel.font = headlineFont
        headlineLabel.textColor = .black
        headlineLabel.numberOfLines = 1

        let bodyFont: UIFont = FontFamily.Poppins.regular.font(size: 10)
        bodyLabel.font = bodyFont
        bodyLabel.textColor = .black
        bodyLabel.numberOfLines = 2

        let ctaFont: UIFont = FontFamily.Poppins.semiBold.font(size: 12)
        ctaButton.titleLabel?.font = ctaFont
        ctaButton.titleLabel?.adjustsFontSizeToFitWidth = true
        ctaButton.titleLabel?.minimumScaleFactor = 0.7
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.backgroundColor = UIColor(red: 0x29 / 255, green: 0x64 / 255, blue: 0xD0 / 255, alpha: 1)
        ctaButton.layer.cornerRadius = 8

        let badgeColor = UIColor(red: 0x00 / 255, green: 0xB4 / 255, blue: 0xF5 / 255, alpha: 1)
        let badgeFont: UIFont = FontFamily.Poppins.medium.font(size: 10)
        adBadge.text = "Ad"
        adBadge.font = badgeFont
        adBadge.textColor = badgeColor
        adBadge.textAlignment = .center
        adBadge.backgroundColor = badgeColor.withAlphaComponent(0.1)
        adBadge.layer.cornerRadius = 4
        adBadge.layer.maskedCorners = [.layerMaxXMaxYCorner]
        adBadge.clipsToBounds = true

        [iconView, headlineLabel, bodyLabel, ctaButton, adBadge].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            nativeAdView.addSubview($0)
        }

        let textStack = UIStackView(arrangedSubviews: [headlineLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(textStack)

        headlineLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            nativeAdView.topAnchor.constraint(equalTo: topAnchor),
            nativeAdView.leadingAnchor.constraint(equalTo: leadingAnchor),
            nativeAdView.trailingAnchor.constraint(equalTo: trailingAnchor),
            nativeAdView.bottomAnchor.constraint(equalTo: bottomAnchor),

            adBadge.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            adBadge.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            adBadge.widthAnchor.constraint(equalToConstant: 18),
            adBadge.heightAnchor.constraint(equalToConstant: 18),

            iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: ctaButton.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            textStack.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -8),
            textStack.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: nativeAdView.bottomAnchor, constant: -12),

            ctaButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -16),
            ctaButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -12),
            ctaButton.widthAnchor.constraint(equalToConstant: 100),
            ctaButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        nativeAdView.iconView = iconView
        nativeAdView.headlineView = headlineLabel
        nativeAdView.bodyView = bodyLabel
        nativeAdView.callToActionView = ctaButton
    }

    func loadAndConfig(adId: Configs.AdvertisementID = .ADSNativeAdsNoMediaViewID,
                       isSuccess: ((Bool) -> Void)? = nil) {
        AdsManager.shared.refreshNativeAd(adId) { [weak self] ad, error in
            guard let self, let ad, error == nil else {
                self?.gone()
                isSuccess?(false)
                return
            }
            self.visible()
            self.configure(with: ad)
            isSuccess?(true)
        }
    }

    func configure(with nativeAd: NativeAd) {
        // Reset old ad binding to prevent memory accumulation in SDK
        nativeAdView.nativeAd = nil

        headlineLabel.text = nativeAd.headline

        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body == nil

        ctaButton.setTitle(nativeAd.callToAction?.uppercased(), for: .normal)
        ctaButton.isHidden = nativeAd.callToAction == nil

        iconView.image = nativeAd.icon?.image
        iconView.isHidden = nativeAd.icon == nil

        // The SDK handles taps on the registered views.
        ctaButton.isUserInteractionEnabled = false

        nativeAdView.nativeAd = nativeAd
    }
}
