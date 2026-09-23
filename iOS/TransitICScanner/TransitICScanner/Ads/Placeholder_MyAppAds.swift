import SwiftUI

// 広告がない・オフライン時、ランダムに自アプリの広告表示

let myAppsAds:[PlaceholderAdsView] = [
    // WebPコンバータ
    PlaceholderAdsView(icon: UIImage(named:"myapp_webp"),headline: String(localized:"ads.placeholder.myapp.webp.title"),bodyText: String(localized:"ads.placeholder.myapp.webp.body"),callToAction:String(localized:"ads.placeholder.myapp.button"),url:URL(string:"https://apps.apple.com/app/id6745822737")),
    
    //スマート置換
    PlaceholderAdsView(icon: UIImage(named:"myapp_Replacer"),headline: String(localized:"ads.placeholder.myapp.Replacer.title"),bodyText: String(localized:"ads.placeholder.myapp.Replacer.body"),callToAction:String(localized:"ads.placeholder.myapp.button"),url:URL(string:"https://apps.apple.com/app/id6760252962")),
    
    //IMGPiper
    PlaceholderAdsView(icon: UIImage(named:"myapp_IMGPiper"),headline: String(localized:"ads.placeholder.myapp.IMGPiper.title"),bodyText: String(localized:"ads.placeholder.myapp.IMGPiper.body"),callToAction:String(localized:"ads.placeholder.myapp.button"),url:URL(string:"https://apps.apple.com/app/id6752764372")),
]
