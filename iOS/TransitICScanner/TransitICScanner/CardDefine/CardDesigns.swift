import SwiftUI

let cardDesignList: [CardDesign] = [
    // MARK: jpIC
    CardDesign(type: .jpIC, name: "card.suica", imageName: "jpIC_suica", isDefault: true),
    CardDesign(type: .jpIC, name: "card.pasmo", imageName: "jpIC_pasmo", isDefault: false),
    CardDesign(type: .jpIC, name: "card.icoca", imageName: "jpIC_icoca", isDefault: false),
    CardDesign(type: .jpIC, name: "card.toica", imageName: "jpIC_toica", isDefault: false),
    CardDesign(type: .jpIC, name: "card.nimoca", imageName: "jpIC_nimoca", isDefault: false),
    CardDesign(type: .jpIC, name: "card.manaca", imageName: "jpIC_manaca", isDefault: false),
    CardDesign(type: .jpIC, name: "card.hayakaken", imageName: "jpIC_hayakaken", isDefault: false),
    CardDesign(type: .jpIC, name: "card.sugoca", imageName: "jpIC_sugoca", isDefault: false),
    CardDesign(type: .jpIC, name: "card.SAPICA", imageName: "jpIC_SAPICA", isDefault: false),
    CardDesign(type: .jpIC, name: "card.IruCa", imageName: "jpIC_iruca", isDefault: false),
    CardDesign(type: .jpIC, name: "card.icsca", imageName: "jpIC_icsca", isDefault: false),

    // MARK: cnTunion
    CardDesign(type: .cnTunion, name: "card.default", imageName: "cnTunion_dummy", isDefault: true),
    CardDesign(type: .cnTunion, name: "北京一卡通", imageName: "cnTunion_beijing", isDefault: false),
    CardDesign(type: .cnTunion, name: "上海公共交通卡", imageName: "cnTunion_shanghai", isDefault: false),
    CardDesign(type: .cnTunion, name: "深圳通", imageName: "cnTunion_shenzhen", isDefault: false),
    CardDesign(type: .cnTunion, name: "羊城通", imageName: "cnTunion_yangchengtong", isDefault: false),
    CardDesign(type: .cnTunion, name: "杭州通", imageName: "cnTunion_hangzhou", isDefault: false),
    CardDesign(type: .cnTunion, name: "八达通", imageName: "cnTunion_hkOctopus", isDefault: false),
    CardDesign(type: .cnTunion, name: "澳门通", imageName: "cnTunion_macauPass", isDefault: false),

    // MARK: hkOctopus
    CardDesign(type: .hkOctopus, name: "card.hkOctopus", imageName: "hkOctopus", isDefault: true),

    // MARK: krOneCard
    CardDesign(type: .krOneCard, name: "card.tmoney", imageName: "krOneCard_tmoney", isDefault: true),
    CardDesign(type: .krOneCard, name: "card.ezl", imageName: "krOneCard_ezl", isDefault: true),

    // MARK: twICash
    CardDesign(type: .twICash, name: "card.twICash", imageName: "twICash", isDefault: true),

    // MARK: jpNplus
    CardDesign(type: .jpNplus, name: "card.jpNplus", imageName: "jpNplus", isDefault: true),

    // MARK: twEasyCard_old
    CardDesign(type: .twEasyCard_old, name: "card.twEasyCard_old", imageName: "twEasyCard_old", isDefault: true),

    // MARK: usClipper
    CardDesign(type: .usClipper, name: "card.usClipper", imageName: "usClipper", isDefault: true),

    // MARK: jpDoCard
    CardDesign(type: .jpDoCard, name: "card.DoCard", imageName: "jpDoCard", isDefault: true),
    CardDesign(type: .jpDoCard, name: "card.Asaca", imageName: "jpDoCard_Asaca", isDefault: false),

    // MARK: jpOKICA
    CardDesign(type: .jpOKICA, name: "card.OKICA", imageName: "jpOKICA", isDefault: true),

    // MARK: jpRapica
    CardDesign(type: .jpRapica, name: "card.rapica", imageName: "jpRapica", isDefault: true),
    CardDesign(type: .jpRapica, name: "card.iwasaki", imageName: "jpRapica_iwasaki", isDefault: false),

    // MARK: idKAI
    CardDesign(type: .idKAI, name: "card.idKAI", imageName: "idKAI", isDefault: true),

    // MARL: spEZLink
    CardDesign(type: .spEZLink, name: "card.spEZLink", imageName: "spEZLink", isDefault: true),
]
