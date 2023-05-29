//
//  AdItemViews.swift
//  SleepSentry
//
//  Created by Selina on 16/5/2023.
//

import UIKit
import GoogleMobileAds
import SnapKit

public extension AdManager {
    private static let CommonRadius: CGFloat = 16
    private static let CommonPadding: CGFloat = 12
    private static let ActionBtnHeight: CGFloat = 25
    private static let LargeActionBtnHeight: CGFloat = 50
    
    class PaddingLabel: UILabel {
        var padding: UIEdgeInsets = .zero
        
        public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
            guard text?.count ?? 0 > 0 else {
                return super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
            }
            
            let insets = padding
            var rect = super.textRect(forBounds: bounds.inset(by: insets), limitedToNumberOfLines: numberOfLines)
            rect.origin.x -= insets.left
            rect.origin.y -= insets.top
            rect.size.width += (insets.left + insets.right)
            rect.size.height += (insets.top + insets.bottom)
            
            return rect
        }
        
        public override func drawText(in rect: CGRect) {
            super.drawText(in: rect.inset(by: padding))
        }
    }
}

public extension AdManager {
    class AdBaseItemView: UIView {
        public lazy var contentView: GADNativeAdView = {
            let view = GADNativeAdView()
            return view
        }()
        
        public lazy var adTipsLabel: AdManager.PaddingLabel = {
            let view = AdManager.PaddingLabel()
            view.padding = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
            view.backgroundColor = .orange
            view.textColor = .white
            view.font = .systemFont(ofSize: 10, weight: .medium)
            view.clipsToBounds = true
            view.layer.cornerRadius = 2
            view.text = "Ad"
            view.textAlignment = .center
            
            return view
        }()
        
        public override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public func setup() {
            addSubview(contentView)
            contentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        public func config(_ ad: GADNativeAd) {
            contentView.nativeAd = ad
        }
    }

    class AdSmallItemView: AdBaseItemView {
        public lazy var adIconImageView: UIImageView = {
            let view = UIImageView()
            view.clipsToBounds = true
            view.contentMode = .scaleAspectFill
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            view.layer.cornerRadius = CommonRadius
            
            view.snp.makeConstraints { make in
                make.width.height.equalTo(55)
            }
            
            return view
        }()
        
        public lazy var adTitleLabel: UILabel = {
            let view = UILabel()
            view.font = .systemFont(ofSize: 16, weight: .bold)
            view.textColor = .white
            return view
        }()
        
        public lazy var adBodyLabel: UILabel = {
            let view = UILabel()
            view.font = .systemFont(ofSize: 12, weight: .medium)
            view.textColor = .white
            view.numberOfLines = 2
            return view
        }()
        
        public lazy var adActionBtn: AdManager.PaddingLabel = {
            let view = AdManager.PaddingLabel()
            view.padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            view.font = .systemFont(ofSize: 12, weight: .medium)
            view.textColor = .white
            view.backgroundColor = .orange
            view.clipsToBounds = true
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            view.layer.cornerRadius = ActionBtnHeight / 2
            
            view.snp.makeConstraints { make in
                make.height.equalTo(ActionBtnHeight)
            }
            
            return view
        }()
        
        public lazy var textVStackView: UIStackView = {
            let vStack = UIStackView(arrangedSubviews: [adTitleLabel, adBodyLabel])
            vStack.axis = .vertical
            vStack.spacing = 4
            vStack.alignment = .leading
            return vStack
        }()
        
        public lazy var hStackView: UIStackView = {
            let hStack = UIStackView(arrangedSubviews: [adIconImageView, textVStackView, adActionBtn])
            hStack.axis = .horizontal
            hStack.spacing = 8
            hStack.alignment = .center
            return hStack
        }()
        
        public override func setup() {
            super.setup()
            
            contentView.addSubview(hStackView)
            hStackView.snp.makeConstraints { make in
                make.left.equalTo(AdManager.CommonPadding)
                make.right.equalTo(-AdManager.CommonPadding)
                make.centerY.equalToSuperview()
            }
            
            contentView.addSubview(adTipsLabel)
            adTipsLabel.snp.makeConstraints { make in
                make.left.top.equalToSuperview()
            }
            
            contentView.headlineView = adTitleLabel
            contentView.callToActionView = adActionBtn
            contentView.bodyView = adBodyLabel
            contentView.iconView = adIconImageView
        }
        
        public override func config(_ ad: GADNativeAd) {
            adIconImageView.image = ad.icon?.image
            adIconImageView.isHidden = ad.icon?.image == nil
            
            adTitleLabel.text = ad.headline
            
            adBodyLabel.text = ad.body
            adBodyLabel.isHidden = ad.body == nil
            
            adActionBtn.text = ad.callToAction
            adActionBtn.isHidden = ad.callToAction == nil
            
            super.config(ad)
        }
    }
    
    class AdLargeItemView: AdBaseItemView {
        public lazy var headerContainerView: UIView = {
            let view = UIView()
            view.snp.makeConstraints { make in
                make.height.equalTo(90)
            }
            return view
        }()
        
        public lazy var adIconImageView: UIImageView = {
            let view = UIImageView()
            view.clipsToBounds = true
            view.contentMode = .scaleAspectFill
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            view.layer.cornerRadius = CommonRadius
            
            view.snp.makeConstraints { make in
                make.width.height.equalTo(55)
            }
            
            return view
        }()
        
        public lazy var adTitleLabel: UILabel = {
            let view = UILabel()
            view.font = .systemFont(ofSize: 16, weight: .bold)
            view.textColor = .white
            return view
        }()
        
        public lazy var adBodyLabel: UILabel = {
            let view = UILabel()
            view.font = .systemFont(ofSize: 12, weight: .medium)
            view.textColor = .white
            view.numberOfLines = 2
            return view
        }()
        
        public lazy var adMediaView: GADMediaView = {
            let view = GADMediaView()
            view.contentMode = .scaleAspectFill
            view.clipsToBounds = true
            view.layer.cornerRadius = AdManager.CommonRadius
            return view
        }()
        
        public lazy var adActionBtn: AdManager.PaddingLabel = {
            let view = AdManager.PaddingLabel()
            view.padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            view.textAlignment = .center
            view.font = .systemFont(ofSize: 18, weight: .medium)
            view.textColor = .white
            view.backgroundColor = .orange
            view.clipsToBounds = true
            view.setContentHuggingPriority(.required, for: .horizontal)
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            view.layer.cornerRadius = AdManager.LargeActionBtnHeight / 2
            
            view.snp.makeConstraints { make in
                make.height.equalTo(AdManager.LargeActionBtnHeight)
            }
            
            return view
        }()
        
        public lazy var textVStackView: UIStackView = {
            let vStack = UIStackView(arrangedSubviews: [adTitleLabel, adBodyLabel])
            vStack.axis = .vertical
            vStack.spacing = 4
            vStack.alignment = .leading
            return vStack
        }()
        
        public lazy var hStackView: UIStackView = {
            let hStack = UIStackView(arrangedSubviews: [adIconImageView, textVStackView])
            hStack.axis = .horizontal
            hStack.spacing = 8
            hStack.alignment = .center
            return hStack
        }()
        
        public override func setup() {
            super.setup()
            
            contentView.addSubview(headerContainerView)
            headerContainerView.snp.makeConstraints { make in
                make.left.right.top.equalToSuperview()
            }
            
            headerContainerView.addSubview(hStackView)
            hStackView.snp.makeConstraints { make in
                make.left.equalTo(AdManager.CommonPadding)
                make.right.equalTo(-AdManager.CommonPadding)
                make.centerY.equalToSuperview()
            }
            
            headerContainerView.addSubview(adTipsLabel)
            adTipsLabel.snp.makeConstraints { make in
                make.top.left.equalToSuperview()
            }
            
            contentView.addSubview(adActionBtn)
            adActionBtn.snp.makeConstraints { make in
                make.left.equalTo(AdManager.CommonPadding)
                make.right.equalTo(-AdManager.CommonPadding)
                make.bottom.equalTo(-AdManager.CommonPadding)
            }
            
            // layout must depending on ad object
            contentView.addSubview(adMediaView)
            
            contentView.headlineView = adTitleLabel
            contentView.callToActionView = adActionBtn
            contentView.bodyView = adBodyLabel
            contentView.iconView = adIconImageView
            contentView.mediaView = adMediaView
        }
        
        public override func config(_ ad: GADNativeAd) {
            adIconImageView.image = ad.icon?.image
            adIconImageView.isHidden = ad.icon?.image == nil
            
            adTitleLabel.text = ad.headline
            
            adBodyLabel.text = ad.body
            adBodyLabel.isHidden = ad.body == nil
            
            adActionBtn.text = ad.callToAction
            adActionBtn.isHidden = ad.callToAction == nil
            
            adMediaView.mediaContent = ad.mediaContent
            adMediaView.isHidden = !ad.mediaContent.reallyHasContent
            
            if ad.mediaContent.reallyHasContent {
                adMediaView.snp.remakeConstraints { make in
                    make.top.equalTo(headerContainerView.snp.bottom)
                    make.left.equalTo(AdManager.CommonPadding)
                    make.right.equalTo(-AdManager.CommonPadding)
                    make.height.equalTo(adMediaView.snp.width).dividedBy(ad.mediaContent.realRatio)
                }
            }
            
            super.config(ad)
        }
        
        public class func calculateHeight(_ ad: GADNativeAd, width: CGFloat) -> CGFloat {
            let headerHeight: CGFloat = 90
            let btnHeight: CGFloat = AdManager.LargeActionBtnHeight
            
            var result: CGFloat = 0
            result += headerHeight
            
            if !ad.mediaContent.reallyHasContent, ad.callToAction == nil {
                // nothing to show
                return result
            }
            
            // bottom padding
            result += AdManager.CommonPadding
            
            if ad.callToAction != nil {
                result += btnHeight
            }
            
            let mediaWidth: CGFloat = width - AdManager.CommonPadding * 2
            
            if ad.mediaContent.reallyHasContent {
                let mediaHeight = ad.mediaContent.height(forWidth: mediaWidth)
                result += mediaHeight
                
                if ad.callToAction != nil {
                    result += AdManager.CommonPadding
                }
                
                return result
            }
            
            return result
        }
    }
}
