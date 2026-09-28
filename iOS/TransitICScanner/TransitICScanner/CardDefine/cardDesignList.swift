import SwiftUI

let cardDesignList:[CardDesigin] = [
    // MARK: jpIC
    CardDesigin(type: .jpIC, name: "card.suica", imageName: "jpIC_suica", isDefault: true),
    CardDesigin(type: .jpIC, name: "card.pasmo", imageName: "jpIC_pasmo", isDefault: false),
    CardDesigin(type: .jpIC, name: "card.icoca", imageName: "jpIC_icoca", isDefault: false),
    CardDesigin(type: .jpIC, name: "card.toica", imageName: "jpIC_toica", isDefault: false),
    CardDesigin(type: .jpIC, name: "card.nimoca", imageName: "jpIC_nimoca", isDefault: false),
    CardDesigin(type: .jpIC, name: "card.manaca", imageName: "jpIC_manaca", isDefault: false),
    CardDesigin(type: .jpIC, name: "card.hayakaken", imageName: "jpIC_hayakaken", isDefault: false),
    CardDesigin(type: .jpIC, name: "card.sugoca", imageName: "jpIC_sugoca", isDefault: false),
    CardDesigin(type: .jpIC, name: "card.SAPICA", imageName: "jpIC_SAPICA", isDefault: false),
    CardDesigin(type: .jpIC, name: "card.IruCa", imageName: "jpIC_IruCa", isDefault: false),
    
    
    // MARK: cnTunion
    CardDesigin(type: .cnTunion, name: "card.default", imageName: "cnTunion_dummy",  isDefault: true),
    CardDesigin(type: .cnTunion, name: "card.beijing", imageName: "cnTunion_beijing",  isDefault: false),
    CardDesigin(type: .cnTunion, name: "card.shanghai", imageName: "cnTunion_shanghai",  isDefault: false),
    CardDesigin(type: .cnTunion, name: "card.shenzhen", imageName: "cnTunion_shenzhen",  isDefault: false),
    CardDesigin(type: .cnTunion, name: "card.yangchengtong", imageName: "cnTunion_yangchengtong",  isDefault: false),
    CardDesigin(type: .cnTunion, name: "card.hangzhou", imageName: "cnTunion_hangzhou",  isDefault: false),
    CardDesigin(type: .cnTunion, name: "card.octopus.Tunion", imageName: "cnTunion_hkOctopus",  isDefault: false),
    CardDesigin(type: .cnTunion, name: "card.macauPass.Tunion", imageName: "cnTunion_macauPass",  isDefault: false),
    
    
    // MARK: hkOctopus
    CardDesigin(type: .hkOctopus, name: "card.hkOctopus", imageName: "hkOctopus",  isDefault: true),
    
    // MARK: krOneCard
    CardDesigin(type: .krOneCard, name: "card.tmoney", imageName: "krOneCard_tmoney",  isDefault: true),
    CardDesigin(type: .krOneCard, name: "card.ezl", imageName: "krOneCard_ezl",  isDefault: true),
    
    // MARK: twICash
    CardDesigin(type: .twICash, name: "card.twICash", imageName: "twICash",  isDefault: true),
    
    
    // MARK: jpNplus
    CardDesigin(type: .jpNplus, name: "card.jpNplus", imageName: "jpNplus", isDefault: true),
    
    // MARK: twEasyCard_old
    CardDesigin(type: .twEasyCard_old, name: "card.twEasyCard_old", imageName: "twEasyCard_old", isDefault: true),
    
    // MARK: usClipper
    CardDesigin(type: .usClipper, name: "card.usClipper", imageName: "usClipper", isDefault: true),
    
    // MARK: twEasyCard_old
    CardDesigin(type: .jpDoCard, name: "card.DoCard", imageName: "jpDoCard", isDefault: true),
    CardDesigin(type: .jpDoCard, name: "card.Asaca", imageName: "jpDoCard_Asaca", isDefault: false)
]
