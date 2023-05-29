//
//  AdManager.swift
//  SleepSentry
//
//  Created by Selina on 15/5/2023.
//

import Foundation
import GoogleMobileAds

public extension AdManager {
    static let didReceiveAd = Notification.Name("didReceiveAd")
    static let LoaderConfigKey = "DidReceiveAdIdentifierKey"
}

public extension AdManager {
    struct AdIdentifier: RawRepresentable, Hashable {
        public typealias RawValue = String
        
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
    
    enum AdType: Int {
        case native
        case interstitial
        case video
        
        var needAutoRefresh: Bool {
            switch self {
            case .native:
                return true
            default:
                return false
            }
        }
        
        var refreshTime: TimeInterval {
            switch self {
            case .native:
                return 1 * 60 * 60
            default:
                return 0
            }
        }
    }
    
    struct Config {
        let identifier: AdIdentifier
        let type: AdType
        let unitId: String
        
        /// max preload ad
        let preloadLimit: Int
        
        /// when reach error limit, will pause preload logic
        let preloadErrorLimit: Int
        
        /// when preload logic is paused, after `preloadRestartTimeInterval` seconds it will restart
        let preloadRestartTimeInterval: TimeInterval
        
        var debugInfo: String {
            return "[id: \(identifier), type: \(type), unitId: \(unitId)]"
        }
    }
}

// MARK: - Helper
extension AdManager {
    class WeakProxy: NSObject {
        
        weak var target: NSObjectProtocol?
        
        init(target: NSObjectProtocol) {
            self.target = target
            super.init()
        }
        
        override func responds(to aSelector: Selector!) -> Bool {
            return (target?.responds(to: aSelector) ?? false) || super.responds(to: aSelector)
        }
        
        override func forwardingTarget(for aSelector: Selector!) -> Any? {
            return target
        }
    }
    
    class func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        if AdManager.shared.isLogEnabled {
            debugPrint(items, separator: separator, terminator: terminator)
        }
    }
}

extension AdManager {
    class PreLoader<T>: NSObject {
        let config: Config
        var queue: [(Date, T)] = []
        var isRequesting: Bool = false
        var failedCount: Int = 0
        var timer: Timer?
        
        init(config: Config) {
            self.config = config
            super.init()
        }
        
        /// override this
        func run() {
            
        }
        
        func cleanOutdatedAdIfNeeded() {
            if !config.type.needAutoRefresh {
                return
            }
            
            let now = Date()
            queue = queue.filter({ tuple in
                return abs(tuple.0.timeIntervalSince(now)) < config.type.refreshTime
            })
            
            if queue.count < config.preloadLimit {
                run()
            }
        }
        
        func enqueue(_ ad: T) {
            failedCount = 0
            queue.append((Date(), ad))
            postDidReceiveAdNotification()
        }
        
        func postDidReceiveAdNotification() {
            NotificationCenter.default.post(name: AdManager.didReceiveAd, object: nil, userInfo: [AdManager.LoaderConfigKey: config])
        }
        
        func dequeue() -> T? {
            if let first = queue.first {
                queue.removeFirst()
                return first.1
            }
            
            return nil
        }
        
        func onRequestFailed(_ error: Error?) {
            failedCount += 1
            AdManager.log("\(config.debugInfo) request failed: \(error?.localizedDescription ?? "")")
            
            if failedCount < config.preloadErrorLimit {
                // retry Immediately
                AdManager.log("\(config.debugInfo) retry immediately")
                run()
                return
            }
            
            // retry timer
            AdManager.log("\(config.debugInfo) stop retry and waiting for restart")
            startRetryTimer()
        }
        
        func startRetryTimer() {
            stopRetry()
            
            let timer = Timer(timeInterval: config.preloadRestartTimeInterval, target: AdManager.WeakProxy(target: self), selector: #selector(onRetry), userInfo: nil, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
        }
        
        func stopRetry() {
            timer?.invalidate()
            timer = nil
        }
        
        @objc func onRetry() {
            stopRetry()
            run()
        }
        
        deinit {
            stopRetry()
        }
    }
    
    class NativeAdPreLoader: PreLoader<GADNativeAd>, GADNativeAdLoaderDelegate {
        private var loader: GADAdLoader?
        
        override func run() {
            AdManager.log("\(config.debugInfo) run")
            
            if queue.count >= config.preloadLimit {
                AdManager.log("\(config.debugInfo) queue is full")
                return
            }
            
            if isRequesting {
                AdManager.log("\(config.debugInfo) is requesting, ignore")
                return
            }
            
            if timer != nil {
                AdManager.log("\(config.debugInfo) is in waiting for restart state, ignore")
                return
            }
            
            AdManager.log("\(config.debugInfo) did start request ad")
            
            isRequesting = true
            loader = GADAdLoader(adUnitID: config.unitId, rootViewController: nil, adTypes: [.native], options: [])
            loader?.delegate = self
            
            loader?.load(GADRequest())
        }
        
        func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
            isRequesting = false
            onRequestFailed(error)
        }
        
        func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
            isRequesting = false
            enqueue(nativeAd)
            run()
        }
    }
    
    class VideoAdPreLoader: PreLoader<GADRewardedAd> {
        override func run() {
            AdManager.log("\(config.debugInfo) run")
            
            if queue.count >= config.preloadLimit {
                AdManager.log("\(config.debugInfo) queue is full")
                return
            }
            
            if isRequesting {
                AdManager.log("\(config.debugInfo) is requesting, ignore")
                return
            }
            
            if timer != nil {
                AdManager.log("\(config.debugInfo) is in waiting for restart state, ignore")
                return
            }
            
            AdManager.log("\(config.debugInfo) did start request ad")
            
            isRequesting = true
            GADRewardedAd.load(withAdUnitID: config.unitId, request: GADRequest()) { ad, error in
                self.isRequesting = false
                if let error = error {
                    self.onRequestFailed(error)
                    return
                }
                
                guard let ad = ad else {
                    self.onRequestFailed(nil)
                    return
                }
                
                self.enqueue(ad)
                self.run()
            }
        }
    }
    
    class InterstitialAdPreLoader: PreLoader<GADInterstitialAd> {
        override func run() {
            AdManager.log("\(config.debugInfo) run")
            
            if queue.count >= config.preloadLimit {
                AdManager.log("\(config.debugInfo) queue is full")
                return
            }
            
            if isRequesting {
                AdManager.log("\(config.debugInfo) is requesting, ignore")
                return
            }
            
            if timer != nil {
                AdManager.log("\(config.debugInfo) is in waiting for restart state, ignore")
                return
            }
            
            AdManager.log("\(config.debugInfo) did start request ad")
            
            isRequesting = true
            GADInterstitialAd.load(withAdUnitID: config.unitId, request: GADRequest()) { ad, error in
                self.isRequesting = false
                if let error = error {
                    self.onRequestFailed(error)
                    return
                }
                
                guard let ad = ad else {
                    self.onRequestFailed(nil)
                    return
                }
                
                self.enqueue(ad)
                self.run()
            }
        }
    }
}

public class AdManager: NSObject {
    public static let shared = AdManager()
    public var isLogEnabled: Bool = false
    public var configs: [Config] = []
    public var testDeviceIdentifiers: [String]?
    
    private var isInited: Bool = false
    private override init() {
        super.init()
    }
    
    private var nativePreLoaders: [AdIdentifier: NativeAdPreLoader] = [:]
    private var videoPreLoaders: [AdIdentifier: VideoAdPreLoader] = [:]
    private var interstitialPreLoaders: [AdIdentifier: InterstitialAdPreLoader] = [:]
    
    private var cleanTimer: Timer?

    /// Call this after set configs
    public func setup() {
        GADMobileAds.sharedInstance().start { status in
            self.isInited = true
            self.initPreLoaders()
            self.runPreLoaders()
            self.startCleanTimer()
        }
        
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = testDeviceIdentifiers
    }
    
    public func getNativeAd(_ identifier: AdIdentifier) -> GADNativeAd? {
        if let loader = nativePreLoaders[identifier] {
            let ad = loader.dequeue()
            loader.run()
            return ad
        }
        
        return nil
    }
    
    public func getInterstitialAd(_ identifier: AdIdentifier) -> GADInterstitialAd? {
        if let loader = interstitialPreLoaders[identifier] {
            let ad = loader.dequeue()
            loader.run()
            return ad
        }
        
        return nil
    }
    
    public func getVideoAd(_ identifier: AdIdentifier) -> GADRewardedAd? {
        if let loader = videoPreLoaders[identifier] {
            let ad = loader.dequeue()
            loader.run()
            return ad
        }
        
        return nil
    }
}

// MARK: - Config
extension AdManager {
    public func appendConfig(id: AdIdentifier, type: AdType, unitId: String, preloadLimit: Int = 2, preloadErrorLimit: Int = 3, preloadRestartTimeInterval: TimeInterval = 30) {
        let config = Config(identifier: id, type: type, unitId: unitId, preloadLimit: preloadLimit, preloadErrorLimit: preloadErrorLimit, preloadRestartTimeInterval: preloadRestartTimeInterval)
        configs.append(config)
    }
}

// MARK: - PreLoader
extension AdManager {
    private func initPreLoaders() {
        for config in configs {
            switch config.type {
            case .native:
                nativePreLoaders[config.identifier] = NativeAdPreLoader(config: config)
            case .interstitial:
                interstitialPreLoaders[config.identifier] = InterstitialAdPreLoader(config: config)
            case .video:
                videoPreLoaders[config.identifier] = VideoAdPreLoader(config: config)
            }
        }
    }
    
    private func runPreLoaders() {
        for preLoader in nativePreLoaders.values {
            preLoader.run()
        }
        
        for preLoader in interstitialPreLoaders.values {
            preLoader.run()
        }
        
        for preLoader in videoPreLoaders.values {
            preLoader.run()
        }
    }
    
    private func startCleanTimer() {
        let timer = Timer(timeInterval: 60, target: AdManager.WeakProxy(target: self), selector: #selector(onCleanTimer), userInfo: nil, repeats: true)
        timer.tolerance = 6
        RunLoop.main.add(timer, forMode: .common)
        cleanTimer = timer
    }
    
    @objc private func onCleanTimer() {
        for preLoader in nativePreLoaders.values {
            preLoader.cleanOutdatedAdIfNeeded()
        }
        
        for preLoader in interstitialPreLoaders.values {
            preLoader.cleanOutdatedAdIfNeeded()
        }
        
        for preLoader in videoPreLoaders.values {
            preLoader.cleanOutdatedAdIfNeeded()
        }
    }
}
