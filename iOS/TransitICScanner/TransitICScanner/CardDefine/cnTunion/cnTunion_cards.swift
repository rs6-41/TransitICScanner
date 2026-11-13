import SwiftUI

struct cnTunion_Info: Hashable, Codable {
    let name: String
    let area: String?
    let city: String?
    let issuer: String?
}

// https://ipt.kopisee.com/canton/zh-cn/t-union
func cnTunion_getIssueInfo(iin: String) -> cnTunion_Info {
    let card: cnTunion_Info

    //IDの先頭9文字がIINで、そのうち先頭4文字は0310で固定
    switch iin.prefix(9).dropFirst(4) {
    //MARK: 北京 - 0310517
    case "51700": card = cnTunion_Info(name: "北京一卡通", area: nil, city: "北京", issuer: "北京市政交通一卡通支付有限公司")

    //MARK: 上海 - 0310477
    case "47700": card = cnTunion_Info(name: "上海公共交通卡", area: nil, city: "上海", issuer: "上海公共交通卡股份有限公司")

    //MARK: 天津 - 0310491
    case "49102": card = cnTunion_Info(name: "天津城市卡", area: nil, city: "天津", issuer: "天津城市一卡通支付有限公司")

    // MARK: 江西省 - 0310473
    case "47300": card = cnTunion_Info(name: "洪城一卡通", area: "江西省", city: "南昌市", issuer: "江西省洪城一卡通投资有限公司")
    case "47301": card = cnTunion_Info(name: "赣州通", area: "江西省", city: "赣州市", issuer: "赣州城市一卡通有限公司")
    case "47302": card = cnTunion_Info(name: "景德镇公交卡", area: "江西省", city: "景德镇市", issuer: "景德镇公共交通有限公司")
    case "47303": card = cnTunion_Info(name: "萍乡交通一卡通", area: "江西省", city: "萍乡市", issuer: "萍乡市公共交通集团有限公司")
    case "47304": card = cnTunion_Info(name: "九江交通一卡通", area: "江西省", city: "九江市", issuer: "九江市公共交通集团公司")
    case "47305": card = cnTunion_Info(name: "新余公交一卡通", area: "江西省", city: "新余市", issuer: "江西长运新余公共交通有限公司")
    case "47306": card = cnTunion_Info(name: "鹰潭互联互通卡", area: "江西省", city: "鹰潭市", issuer: "江西长运鹰潭公共交通有限公司")
    case "47307": card = cnTunion_Info(name: "宜春公交明月通", area: "江西省", city: "宜春市", issuer: "宜春公交集团有限公司")
    case "47308": card = cnTunion_Info(name: "上饶公交IC卡", area: "江西省", city: "上饶市", issuer: "上饶市公共交通集团有限公司")
    case "47309": card = cnTunion_Info(name: "吉安通", area: "江西省", city: "吉安市", issuer: "江西长运吉安公共交通有限责任公司")
    case "47310": card = cnTunion_Info(name: "抚州交通一卡通", area: "江西省", city: "抚州市", issuer: "抚州市公共交通有限责任公司")

    // MARK: 贵州省 - 0310474
    case "47400": card = cnTunion_Info(name: "贵阳公交电子车票", area: "贵州省", city: "贵阳市", issuer: "贵阳市信捷科技有限公司")
    case "47401": card = cnTunion_Info(name: "遵义交通一卡通", area: "贵州省", city: "遵义市", issuer: "遵义市公共交通(集团)有限责任公司")
    case "47402": card = cnTunion_Info(name: "凉都市民卡", area: "贵州省", city: "六盘水市", issuer: "六盘水凉都市民卡有限公司")
    case "47403": card = cnTunion_Info(name: "安顺公交一卡通", area: "贵州省", city: "安顺市", issuer: "安顺市公共交通总公司")
    case "47404": card = cnTunion_Info(name: "九驿通", area: "贵州省", city: "毕节市大方县", issuer: "大方县城市翼卡支付有限公司")
    case "47405": card = cnTunion_Info(name: "桃源卡", area: "贵州省", city: "铜仁市", issuer: "铜仁市公共交通有限责任公司")
    case "47406": card = cnTunion_Info(name: "兴义卡", area: "贵州省", city: "黔西南布依族苗族自治州", issuer: "兴义市城市公交公司")
    case "47407": card = cnTunion_Info(name: "凯里公交IC卡", area: "贵州省", city: "黔东南苗族侗族自治州", issuer: "贵州省凯里市公共交通总公司")
    case "47408": card = cnTunion_Info(name: "贵州黔南全国交通一卡通", area: "贵州省", city: "黔南布依族苗族自治州", issuer: "都匀市公共交通总公司")
    case "47409": card = cnTunion_Info(name: "一应黔行", area: "贵州省", city: "贵阳市", issuer: "贵阳市信捷科技有限公司")
    case "47410": card = cnTunion_Info(name: "同心市民卡", area: "贵州省", city: "毕节市", issuer: nil)

    // MARK: 西藏自治区 - 0310475
    case "47500": card = cnTunion_Info(name: "西藏交通一卡通", area: "西藏自治区", city: "拉萨市", issuer: "西藏中信海博电子科技有限公司")
    case "47501": card = cnTunion_Info(name: "西藏交通一卡通", area: "西藏自治区", city: "昌都市", issuer: "西藏中信海博电子科技有限公司")
    case "47502": card = cnTunion_Info(name: "西藏交通一卡通", area: "西藏自治区", city: "山南市", issuer: "西藏中信海博电子科技有限公司")
    case "47503": card = cnTunion_Info(name: "西藏交通一卡通", area: "西藏自治区", city: "日喀则市", issuer: "西藏中信海博电子科技有限公司")
    case "47504": card = cnTunion_Info(name: "西藏交通一卡通", area: "西藏自治区", city: "那曲市", issuer: "西藏中信海博电子科技有限公司")
    case "47505": card = cnTunion_Info(name: "西藏交通一卡通", area: "西藏自治区", city: "阿里地区", issuer: "西藏中信海博电子科技有限公司")
    case "47506": card = cnTunion_Info(name: "西藏交通一卡通", area: "西藏自治区", city: "林芝市", issuer: "西藏中信海博电子科技有限公司")

    // MARK: 青海省 - 0310476
    case "47600": card = cnTunion_Info(name: "夏都通", area: "青海省", city: "西宁市", issuer: "西宁智能一卡通责任有限公司")
    case "47601": card = cnTunion_Info(name: "大美青海行", area: "青海省", city: "海东市", issuer: "青海省高速公路运营管理有限公司")
    case "47603": card = cnTunion_Info(name: "大美青海行", area: "青海省", city: "黄南藏族自治州", issuer: "青海省高速公路运营管理有限公司")
    case "47604": card = cnTunion_Info(name: "大美青海行", area: "青海省", city: "黄南藏族自治州", issuer: "青海省高速公路运营管理有限公司")
    case "47606": card = cnTunion_Info(name: "大美青海行", area: "青海省", city: "玉树藏族自治州", issuer: "青海省高速公路运营管理有限公司")
    case "47607": card = cnTunion_Info(name: "大美青海行", area: "青海省", city: "海西蒙古族藏族自治州", issuer: "青海省高速公路运营管理有限公司")

    // MARK: 四川省 - 0310478
    case "47800": card = cnTunion_Info(name: "天府通", area: "四川省", city: "成都市", issuer: "成都天府通金融服务股份有限公司")
    case "47801": card = cnTunion_Info(name: "甜城通", area: "四川省", city: "内江市", issuer: "内江市公共交通集团有限责任公司")
    case "47802": card = cnTunion_Info(name: "月城一卡通", area: "四川省", city: "内江市", issuer: "内江市公共交通集团有限责任公司")
    case "47803": card = cnTunion_Info(name: "乐山交通卡", area: "四川省", city: "乐山市", issuer: "乐山市通联智能交通科技有限公司")
    case "47804": card = cnTunion_Info(name: "自贡通", area: "四川省", city: "自贡市", issuer: "自贡盐都一卡通信息化有限责任公司")
    case "47805": card = cnTunion_Info(name: "攀枝花公交卡", area: "四川省", city: "攀枝花市", issuer: "攀枝花公交客运总公司")
    case "47806": card = cnTunion_Info(name: "酒城一卡通", area: "四川省", city: "泸州市", issuer: "泸州市公共交通集团有限公司")
    case "47807": card = cnTunion_Info(name: "德阳全国交通一卡通", area: "四川省", city: "德阳市", issuer: "德阳裕兴公共交通有限公司")
    case "47808": card = cnTunion_Info(name: "绵州通", area: "四川省", city: "绵阳市", issuer: "绵阳市绵州通有限责任公司")
    case "47809": card = cnTunion_Info(name: "利州通", area: "四川省", city: "广元市", issuer: "广元市公共交通公司")
    case "47810": card = cnTunion_Info(name: "遂州通", area: "四川省", city: "遂宁市", issuer: "遂宁遂州通有限公司")
    case "47811": card = cnTunion_Info(name: "宜宾一卡通", area: "四川省", city: "宜宾市", issuer: "宜宾市和谐卡务有限公司")
    case "47812": card = cnTunion_Info(name: "南充公交卡", area: "四川省", city: "南充市", issuer: "南充市公共交通有限责任公司")
    case "47813": card = cnTunion_Info(name: "达州通", area: "四川省", city: "达州市", issuer: "达州市感知生活科技有限公司")
    case "47814": card = cnTunion_Info(name: "雅安交通一卡通", area: "四川省", city: "雅安市", issuer: "雅安市公共交通有限公司")
    case "47816": card = cnTunion_Info(name: "康定公交一卡通", area: "四川省", city: "甘孜藏族自治州", issuer: "康定公共交通运输有限责任公司")
    case "47817": card = cnTunion_Info(name: "眉山交通一卡通", area: "四川省", city: "眉山市", issuer: "眉山市展通公交客运有限公司")
    case "47818": card = cnTunion_Info(name: "广安全国一卡通", area: "四川省", city: "广安市", issuer: "广安市广泰公共交通有限责任公司")
    case "47819": card = cnTunion_Info(name: "巴中交通一卡通", area: "四川省", city: "巴中市", issuer: "巴中市巴山公共交通有限公司")
    case "47821": card = cnTunion_Info(name: "古城阆中通", area: "四川省", city: "南充市", issuer: "阆中滕王阁旅游公交有限公司")

    // MARK: 新疆维吾尔自治区 - 0310479
    case "47900": card = cnTunion_Info(name: "红山一卡通", area: "新疆维吾尔自治区", city: "乌鲁木齐市", issuer: "乌鲁木齐红山一卡通有限责任公司")
    case "47901": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "阿拉尔市", issuer: "捷行信息技术有限公司")
    case "47902": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "铁门关市", issuer: "捷行信息技术有限公司")
    case "47903": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "图木舒克市", issuer: "捷行信息技术有限公司")
    case "47904": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "可克达拉市", issuer: nil)  //割り振りのみ
    case "47905": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "双河市", issuer: nil)  //割り振りのみ
    case "47906": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "五家渠市", issuer: "捷行信息技术有限公司")
    case "47907": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "胡杨河市", issuer: nil)  //割り振りのみ
    case "47908": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "石河子市", issuer: "捷行信息技术有限公司")
    case "47909": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "白杨市", issuer: nil)  //割り振りのみ
    case "47910": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "北屯市", issuer: "北屯新建旅客运输有限责任公司")
    case "47911": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "乌鲁木齐市", issuer: "捷行信息技术有限公司")
    case "47912": card = cnTunion_Info(name: "金垦卡", area: "新疆维吾尔自治区", city: "新星市", issuer: "哈密市红星客运服务有限公司")
    case "47913": card = cnTunion_Info(name: "崑玉交通一卡通", area: "新疆维吾尔自治区", city: "昆玉市", issuer: "昆玉市安达运输有限公司")
    case "47914": card = cnTunion_Info(name: "克拉玛依公交卡", area: "新疆维吾尔自治区", city: "克拉玛依市", issuer: "克拉玛依市汽车运输有限责任公司")
    case "47915": card = cnTunion_Info(name: "吐鲁番公交卡", area: "新疆维吾尔自治区", city: "吐鲁番市", issuer: "吐鲁番鹏祥公共交通有限公司")
    case "47916": card = cnTunion_Info(name: "哈密市公交卡", area: "新疆维吾尔自治区", city: "哈密市", issuer: "哈密市东畅公共交通有限责任公司")
    case "47917":
        card = cnTunion_Info(name: "昌吉智慧城市一卡通", area: "新疆维吾尔自治区", city: "昌吉回族自治州 昌吉市", issuer: "昌吉公共交通(集团)有限责任公司")
    case "47918":
        card = cnTunion_Info(name: "博乐互通卡", area: "新疆维吾尔自治区", city: "博尔塔拉蒙古自治州 博乐市", issuer: "博乐市阳光公共交通有限责任公司")
    case "47919":
        card = cnTunion_Info(name: "库尔勒市公交卡", area: "新疆维吾尔自治区", city: "巴音郭楞蒙古自治州 库尔勒市", issuer: "库尔勒市公共交通有限责任公司")
    case "47920": card = cnTunion_Info(name: "阿克苏互通卡", area: "新疆维吾尔自治区", city: "阿克苏地区 阿克苏市", issuer: "阿克苏姑墨交通投资有限责任公司")
    case "47921":
        card = cnTunion_Info(name: "阿图什互通卡", area: "新疆维吾尔自治区", city: "克孜勒苏柯尔克孜自治州 阿图什市", issuer: "阿图什顺达公交有限责任公司")
    case "47922": card = cnTunion_Info(name: "喀什智慧城市一卡通", area: "新疆维吾尔自治区", city: "喀什地区", issuer: "喀什市公共交通有限责任公司")
    case "47923": card = cnTunion_Info(name: "", area: "新疆维吾尔自治区", city: "和田地区", issuer: nil)  //割り当てのみ
    case "47924":
        card = cnTunion_Info(name: "伊宁公交卡", area: "新疆维吾尔自治区", city: "伊犁哈萨克自治州 伊宁市", issuer: "伊宁市公共交通(集团)有限责任公司")
    case "47926": card = cnTunion_Info(name: "阿勒泰智慧城市一卡通", area: "新疆维吾尔自治区", city: "阿勒泰地区", issuer: "阿勒泰市利众公共交通有限公司")

    // MARK: 陕西省 - 0310480
    case "48000": card = cnTunion_Info(name: "长安通", area: "陕西省", city: "西安市", issuer: "西安长安通有限责任公司")
    case "48001": card = cnTunion_Info(name: "咸阳城市公交一卡通", area: "陕西省", city: "咸阳市", issuer: "咸阳市公共交通集团公司")
    case "48002": card = cnTunion_Info(name: "宝鸡公交卡", area: "陕西省", city: "宝鸡市", issuer: "宝鸡市公共交通有限责任公司")
    case "48003": card = cnTunion_Info(name: "渭南通", area: "陕西省", city: "渭南市", issuer: "渭南市公共交通总公司")
    case "48004": card = cnTunion_Info(name: "铜川交通一卡通", area: "陕西省", city: "铜川市", issuer: "铜川市公共交通有限责任公司")
    case "48006": card = cnTunion_Info(name: "延安公交一卡通", area: "陕西省", city: "延安市", issuer: "延安市公共交通总公司")
    case "48007": card = cnTunion_Info(name: "天汉通", area: "陕西省", city: "汉中市", issuer: "汉中天汉一卡通有限责任公司")
    case "48008": card = cnTunion_Info(name: "安康公交卡", area: "陕西省", city: "安康市", issuer: "安康市公共交通一卡通有限公司")
    case "48009": card = cnTunion_Info(name: "商洛公交一卡通", area: "陕西省", city: "商洛市", issuer: "商洛市公共汽车公司")
    case "48011": card = cnTunion_Info(name: "榆林驼城通交通卡", area: "陕西省", city: "榆林市", issuer: "榆林城投数字城市建设管理有限责任公司")
    case "48013": card = cnTunion_Info(name: "农科城卡", area: "陕西省", city: "杨凌农业高新技术产业示范区", issuer: "杨凌示范区科技信息中心")
    case "48014": card = cnTunion_Info(name: "西咸一卡通", area: "陕西省", city: "西安市", issuer: "咸阳城市一卡通有限责任公司")

    // MARK: 湖南省 - 0310482
    case "48200": card = cnTunion_Info(name: "长沙潇湘卡", area: "湖南省", city: "长沙市", issuer: "湖南潇湘支付有限公司")
    case "48202": card = cnTunion_Info(name: "株洲公交IC卡", area: "湖南省", city: "株洲市", issuer: "株洲市公共交通集团有限责任公司")
    case "48203": card = cnTunion_Info(name: "湘潭交通卡", area: "湖南省", city: "湘潭市", issuer: "湘潭综合交通科技服务有限公司")
    case "48204": card = cnTunion_Info(name: "衡阳交通卡", area: "湖南省", city: "衡阳市", issuer: "衡阳市公共交通集团有限公司")
    case "48205": card = cnTunion_Info(name: "宝庆一卡通", area: "湖南省", city: "邵阳市", issuer: "邵阳市交通运输信息中心")
    case "48206": card = cnTunion_Info(name: "岳阳通", area: "湖南省", city: "岳阳市", issuer: "岳阳通源投资咨询有限公司")
    case "48207": card = cnTunion_Info(name: "常德公交卡", area: "湖南省", city: "常德市", issuer: "常德市公共交通有限责任公司")
    case "48208": card = cnTunion_Info(name: "张家界一卡通", area: "湖南省", city: "张家界市", issuer: "张家界一卡通科技有限公司")
    case "48209": card = cnTunion_Info(name: "银城一卡通", area: "湖南省", city: "益阳市", issuer: "湖南省益阳市公交公司")
    case "48210": card = cnTunion_Info(name: "娄底公交卡", area: "湖南省", city: "娄底市", issuer: "娄底市公共交通有限公司")
    case "48211": card = cnTunion_Info(name: "福城通", area: "湖南省", city: "郴州市", issuer: "湖南郴州汽车运输集团有限责任公司")
    case "48212": card = cnTunion_Info(name: "永州城市一卡通", area: "湖南省", city: "永州市", issuer: "永州市城市公共交通运输有限责任公司")
    case "48213": card = cnTunion_Info(name: "怀化公交IC卡", area: "湖南省", city: "怀化市", issuer: "怀化公共交通集团有限责任公司")
    case "48214": card = cnTunion_Info(name: "湘西州交通一卡通", area: "湖南省", city: "湘西土家族苗族自治州 吉首市", issuer: "吉首市公共汽车公司")

    // MARK: 江苏省 - 0310483
    // https://zh.wikipedia.org/zh-cn/江苏交通一卡通
    case "48300": card = cnTunion_Info(name: "金陵通", area: "江苏省", city: "南京市", issuer: "南京市市民卡支付有限公司")
    case "48301": card = cnTunion_Info(name: "扬州市民卡", area: "江苏省", city: "扬州市", issuer: "扬州数慧城建科技有限责任公司")
    case "48302": card = cnTunion_Info(name: "镇江公交IC卡", area: "江苏省", city: "镇江市", issuer: "镇江市公共交通有限公司")
    case "48303": card = cnTunion_Info(name: "苏州市民卡", area: "江苏省", city: "苏州市", issuer: "苏州城慧通数字科技有限公司")
    case "48304": card = cnTunion_Info(name: "南通市民卡", area: "江苏省", city: "南通市", issuer: "南通市民卡有限公司")
    case "48305": card = cnTunion_Info(name: "常州市民卡", area: "江苏省", city: "常州市", issuer: "常州市市民卡建设有限公司")
    case "48306": card = cnTunion_Info(name: "宿迁市民卡", area: "江苏省", city: "宿迁市", issuer: "宿迁市市民卡有限公司")
    case "48307": card = cnTunion_Info(name: "黄海通市民卡", area: "江苏省", city: "盐城市", issuer: "盐城市黄海通市民卡有限责任公司")
    case "48308": card = cnTunion_Info(name: "江淮通", area: "江苏省", city: "淮安市", issuer: "淮安市数据集团有限公司")
    case "48309": card = cnTunion_Info(name: "淮海通", area: "江苏省", city: "徐州市", issuer: "徐州市市民卡有限公司")
    case "48310": card = cnTunion_Info(name: "连云港市民卡", area: "江苏省", city: "连云港市", issuer: "江苏云质数科技术有限公司")
    case "48311": card = cnTunion_Info(name: "泰州通", area: "江苏省", city: "泰州市", issuer: "泰州市凤城一卡通有限公司")
    case "48312": card = cnTunion_Info(name: "江苏交通一卡通", area: "江苏省", city: nil, issuer: nil)
    case "48315": card = cnTunion_Info(name: "泰州通", area: "江苏省", city: "昆山市", issuer: "昆通卡")

    // MARK: 广西壮族自治区 - 0310484
    case "48400": card = cnTunion_Info(name: "邕桂通/桂民卡", area: "广西壮族自治区", city: "南宁市", issuer: "南宁轨道科创投资有限公司")
    case "48401": card = cnTunion_Info(name: "柳州市民卡", area: "广西壮族自治区", city: "柳州市", issuer: "柳州银行股份有限公司")
    case "48402": card = cnTunion_Info(name: "桂林市", area: "广西壮族自治区", city: "桂林市", issuer: "桂林市鼎睿交通一卡通有限公司")
    case "48403": card = cnTunion_Info(name: "梧州通", area: "广西壮族自治区", city: "梧州市", issuer: "广西交通一卡通有限公司")
    case "48404": card = cnTunion_Info(name: "北海通", area: "广西壮族自治区", city: "北海市", issuer: "广西交通一卡通有限公司")
    case "48405": card = cnTunion_Info(name: "玉林市民卡", area: "广西壮族自治区", city: "玉林市", issuer: "玉林智慧城市建设有限公司")
    case "48406": card = cnTunion_Info(name: "百色通", area: "广西壮族自治区", city: "百色市", issuer: "广西交通一卡通有限公司")
    case "48407": card = cnTunion_Info(name: "河池通", area: "广西壮族自治区", city: "河池市", issuer: "广西交通一卡通有限公司")
    case "48408": card = cnTunion_Info(name: "钦州市民卡", area: "广西壮族自治区", city: "钦州市", issuer: "广西交通一卡通有限公司")
    case "48409": card = cnTunion_Info(name: "防城港通", area: "广西壮族自治区", city: "防城港市", issuer: "广西交通一卡通有限公司")
    case "48410": card = cnTunion_Info(name: "贵港市民卡", area: "广西壮族自治区", city: "贵港市", issuer: "广西交通一卡通有限公司")
    case "48411": card = cnTunion_Info(name: "贺州通", area: "广西壮族自治区", city: "贺州市", issuer: "广西交通一卡通有限公司")
    case "48412": card = cnTunion_Info(name: "来宾通", area: "广西壮族自治区", city: "来宾市", issuer: "广西交通一卡通有限公司")
    case "48413": card = cnTunion_Info(name: "崇左通", area: "广西壮族自治区", city: "崇左市", issuer: "广西交通一卡通有限公司")

    // MARK: 广东省 - 0310487
    case "48702": card = cnTunion_Info(name: "东莞通全国交通一卡通", area: "广东省", city: "东莞市", issuer: "东莞市东莞通股份有限公司")
    case "48703": card = cnTunion_Info(name: "羊城通全国交通一卡通", area: "广东省", city: "广州市", issuer: "广州羊城通有限公司")
    case "48704": card = cnTunion_Info(name: "深圳通互联互通卡", area: "广东省", city: "深圳市", issuer: "深圳市深圳通有限公司")
    case "48705": card = cnTunion_Info(name: "中山通全国交通一卡通", area: "广东省", city: "中山市", issuer: "中山市中山通智能卡有限公司")
    case "48707": card = cnTunion_Info(name: "广佛通全国交通一卡通", area: "广东省", city: "佛山市", issuer: "佛山市广佛通电子收费营运有限公司")
    case "48708": card = cnTunion_Info(name: "惠州通全国交通一卡通", area: "广东省", city: "惠州市", issuer: "惠州市惠州通智能卡有限公司")
    case "48709": card = cnTunion_Info(name: "汕头全国交通一卡通", area: "广东省", city: "汕头市", issuer: "汕头市公共交通总公司")
    case "48710": card = cnTunion_Info(name: "五邑通全国交通一卡通", area: "广东省", city: "江门市", issuer: "江门市五邑通智能卡有限公司")
    case "48711": card = cnTunion_Info(name: "茂城通", area: "广东省", city: "茂名市", issuer: "广东信浓信息技术有限公司")
    case "48712": card = cnTunion_Info(name: "肇庆通全国交通一卡通", area: "广东省", city: "肇庆市", issuer: "肇庆市肇庆通智能卡有限公司")
    case "48713": card = cnTunion_Info(name: "湛江通全国交通一卡通", area: "广东省", city: "湛江市", issuer: "湛江市公共交通集团有限公司")
    case "48714": card = cnTunion_Info(name: "嘉应通全国交通一卡通", area: "广东省", city: "梅州市", issuer: "梅州城市公共汽车有限公司")
    case "48715": card = cnTunion_Info(name: "红海通全国交通一卡通", area: "广东省", city: "汕尾市", issuer: "汕尾市红海通信息科技有限公司")
    case "48716": card = cnTunion_Info(name: "河源全国交通一卡通", area: "广东省", city: "河源市", issuer: "河源市粤运汽车运输有限公司粤支付分公司")
    case "48717": card = cnTunion_Info(name: "清远市民卡全国交通一卡通", area: "广东省", city: "清远市", issuer: "清远市民卡有限公司")
    case "48718": card = cnTunion_Info(name: "韶州通全国交通一卡通", area: "广东省", city: "韶关市", issuer: "韶关市金迪金融网络有限公司")
    case "48719": card = cnTunion_Info(name: "榕江通全国交通一卡通", area: "广东省", city: "揭阳市", issuer: "广东华讯网络有限公司")
    case "48720": card = cnTunion_Info(name: "漠江通全国交通一卡通", area: "广东省", city: "阳江市", issuer: "阳江市交投朗日公共汽车有限公司")
    case "48721": card = cnTunion_Info(name: "潮州通全国交通一卡通", area: "广东省", city: "潮州市", issuer: "潮州市粤运公共交通有限公司")
    case "48722": card = cnTunion_Info(name: "岭云通", area: "广东省", city: "云浮市", issuer: "云浮市岭云一卡通科技有限公司")
    case "48724": card = cnTunion_Info(name: "珠海通全国交通一卡通", area: "广东省", city: "珠海市", issuer: "珠海市珠海通科技有限公司")

    // MARK: 浙江省 - 0310488
    case "48800": card = cnTunion_Info(name: "温州交运城市公交IC卡互通卡", area: "浙江省", city: "温州市", issuer: "温州市交通运输集团有限公司")
    case "48801": card = cnTunion_Info(name: "杭州通交通联合卡/杭州市第三代社保卡", area: "浙江省", city: "杭州市", issuer: "杭州市民卡支付有限公司")
    case "48802": card = cnTunion_Info(name: "甬城通·交通部卡/宁波交通卡·交通部卡", area: "浙江省", city: "宁波市", issuer: "宁波市民卡运营管理有限公司")
    case "48803":
        card = cnTunion_Info(name: "嘉兴交通一卡通·城际通卡", area: "浙江省", city: "嘉兴市", issuer: "嘉兴市公共交通有限公司、嘉兴市国鸿公共交通有限公司")
    case "48804": card = cnTunion_Info(name: "台州通", area: "浙江省", city: "台州市", issuer: "台州市畅行智慧交通科技有限公司")
    case "48805": card = cnTunion_Info(name: "金华交通一卡通", area: "浙江省", city: "金华市", issuer: "金华市公交集团有限公司")
    case "48806":
        card = cnTunion_Info(name: "湖州市交通一卡通", area: "浙江省", city: "湖州市", issuer: "湖州市惠通公交一卡通有限公司（城市）、湖州康达公交运输有限公司（城乡）")
    case "48807": card = cnTunion_Info(name: "绍兴通卡", area: "浙江省", city: "绍兴市", issuer: "绍兴市公交信息科技有限公司")
    case "48808": card = cnTunion_Info(name: "衢州公交交通一卡通", area: "浙江省", city: "衢州市", issuer: "浙江衢州公交集团有限公司")
    case "48809": card = cnTunion_Info(name: "舟山群岛通卡", area: "浙江省", city: "舟山市", issuer: "舟山市智慧城市运营有限公司")
    case "48810": card = cnTunion_Info(name: "丽水公交IC卡", area: "浙江省", city: "丽水市", issuer: "丽水市公共交通集团有限公司")

    // MARK: 吉林省 - 0310489
    case "48900": card = cnTunion_Info(name: "长春轨道交通一卡通", area: "吉林省", city: "长春市", issuer: "长春市轨道交通集团有限公司")
    case "48901": card = cnTunion_Info(name: "吉林通", area: "吉林省", city: "吉林市", issuer: "吉林省通卡支付股份有限公司")
    case "48902": card = cnTunion_Info(name: "长春城市通卡一卡通", area: "吉林省", city: "长春市", issuer: "长春城市通卡有限责任公司")
    case "48903": card = cnTunion_Info(name: "通化交通一卡通", area: "吉林省", city: "通化市", issuer: "通化市巴士公共交通有限公司")
    case "48904": card = cnTunion_Info(name: "长春城联交通一卡通", area: "吉林省", city: "长春市", issuer: "长春城联交通一卡通有限责任公司")  // 廃止
    case "48905": card = cnTunion_Info(name: "白山交通一卡通", area: "吉林省", city: "白山市", issuer: "白山市公共交通有限公司")
    case "48906": card = cnTunion_Info(name: "蛟河客运公交一卡通", area: "吉林省", city: "吉林市 蛟河市", issuer: "蛟河隆客公交有限公司")
    case "48908": card = cnTunion_Info(name: "四平城市交通一卡通", area: "吉林省", city: "四平市", issuer: "中国建设银行股份有限公司四平分行")
    case "48909": card = cnTunion_Info(name: "辽源交通一卡通", area: "吉林省", city: "辽源市", issuer: "辽源市公共汽车公司")
    case "48910": card = cnTunion_Info(name: "鹤城通", area: "吉林省", city: "白城市", issuer: "白城市城市通卡有限公司")
    case "48912": card = cnTunion_Info(name: "松原通", area: "吉林省", city: "松原市", issuer: "松原市城市通卡有限公司")
    case "48913": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "长春市 榆树市", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48914": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "长春市 农安县", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48915": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "长春市 德惠市", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48916": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "长春市 九台区", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48917": card = cnTunion_Info(name: "永吉万联惠民通卡", area: "吉林省", city: "吉林市 永吉县", issuer: "吉林市万联科技有限公司")
    case "48919": card = cnTunion_Info(name: "磐石万联惠民通卡", area: "吉林省", city: "吉林市 磐石市", issuer: "吉林市万联科技有限公司")
    case "48921": card = cnTunion_Info(name: "四平城市交通一卡通", area: "吉林省", city: "四平市 梨树县", issuer: "中国建设银行股份有限公司四平分行")
    case "48922": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "四平市 伊通满族自治县", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48923": card = cnTunion_Info(name: "双辽市交通一卡通", area: "吉林省", city: "四平市 双辽市", issuer: "双辽市盛世共赢交通卡销售有限公司")
    case "48924": card = cnTunion_Info(name: "公主岭万联惠民卡", area: "吉林省", city: "长春市 公主岭市", issuer: "吉林市万联科技有限公司")
    case "48925": card = cnTunion_Info(name: "", area: "吉林省", city: "辽源市 东丰县", issuer: "东丰县公共交通有限责任公司")
    case "48927": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "通化市 通化县", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48928": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "通化市 辉南县", issuer: "辉南县北方公共汽车客运处")
    case "48929": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "通化市 柳河县", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48930": card = cnTunion_Info(name: "梅河口市交通文明一卡通", area: "吉林省", city: "通化市 梅河口市", issuer: "吉林万联科技有限公司")
    case "48931": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "通化市 集安市", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48935": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "白城市 洮南市", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48936": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "白城市 大安市", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48937": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "白城市 镇赉县", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48938": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "白城市 通榆县", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48939": card = cnTunion_Info(name: "延吉交通一卡通", area: "吉林省", city: "延边朝鲜族自治州 延吉市", issuer: "延吉市公交集团有限公司")
    case "48942":
        card = cnTunion_Info(name: "珲春城市一卡通唰唰通互通卡", area: "吉林省", city: "延边朝鲜族自治州 珲春市", issuer: "珲春市智慧城市投资管理有限公司")
    case "48944": card = cnTunion_Info(name: "", area: "吉林省", city: "延边朝鲜族自治州 和龙市", issuer: "和龙市公交出租旅游汽车中心")
    case "48946": card = cnTunion_Info(name: "吉林通", area: "吉林省", city: "延边朝鲜族自治州 敦化市", issuer: "吉林省通卡支付股份有限公司")
    case "48947": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "松原市 扶余市", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48948": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "松原市 长岭县", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48949": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "松原市 乾安县", issuer: "吉林省长白行交通卡技术服务有限公司")
    case "48950": card = cnTunion_Info(name: "吉林长白行一卡通", area: "吉林省", city: "长白山保护开发区", issuer: "长白山保护开发区智行旅游交通服务有限公司")
    case "48951": card = cnTunion_Info(name: "吉林长白行一卡通/金通卡", area: "吉林省", city: "长春市 双阳区", issuer: "吉林省长白行交通卡技术服务有限公司")

    // MARK: 甘肃省 - 0310490
    case "49000":
        card = cnTunion_Info(
            name: "兰州公交集团IC卡、兰州轨道交通一卡通（市区）/丝路任我行·飞天卡（榆中、永登、皋兰、红古）", area: "甘肃省", city: "兰州市",
            issuer: "兰州公交集团、兰州市轨道交通有限公司（市区）、兰州交发建集团（红古、榆中、永登、皋兰）")
    case "49001": card = cnTunion_Info(name: "", area: "甘肃省", city: "平凉市", issuer: "平凉市崆通公交服务集团有限责任公司")
    case "49003": card = cnTunion_Info(name: "丝路任我行·金昌市公共交通有限公司IC卡", area: "甘肃省", city: "金昌市", issuer: "金昌国有公共交通运营有限公司")
    case "49004":
        card = cnTunion_Info(
            name: "丝路任我行/丝路任我行·靖远/丝路任我行·会宁公交IC卡", area: "甘肃省", city: "白银市",
            issuer: "白银市公共交通公司、靖远五环汽车运输有限公司（靖远）、会宁县汇通公交服务有限公司（会宁）")
    case "49006":
        card = cnTunion_Info(
            name: "丝路任我行·酒泉（肃州）/丝路任我行·敦煌（敦煌）", area: "甘肃省", city: "酒泉市", issuer: "甘肃广和公交集团有限公司（肃州）、敦煌文旅交通有限公司（敦煌）")
    case "49007":
        card = cnTunion_Info(
            name: "丝路任我行·山丹丹运公交公司IC卡/丝路任我行·民乐", area: "甘肃省", city: "张掖市",
            issuer: "山丹县丹运公交运输有限公司（山丹）、甘肃西运运输实业(集团)有限责任公司公交客运分公司（民乐）")
    case "49008": card = cnTunion_Info(name: "丝路任我行·凉州卡", area: "甘肃省", city: "武威市", issuer: "甘肃一卡通信息技术服务有限公司")
    case "49010":
        card = cnTunion_Info(
            name: "丝路任我行·陇南/丝路任我行·宕昌/丝路任我行·成县/丝路任我行·文县", area: "甘肃省", city: "陇南市",
            issuer: "陇运集团武都公交公司、宕昌县金诚公共交通有限责任公司、陇运集团成县公交公司、陇运集团文县公交公司")
    case "49011": card = cnTunion_Info(name: "丝路任我行·环县", area: "甘肃省", city: "庆阳市", issuer: "庆阳公共交通集团有限公司")
    case "49012": card = cnTunion_Info(name: "丝路任我行·临夏", area: "甘肃省", city: "临夏回族自治州", issuer: "临夏道合公交客运服务有限责任公司")
    case "49015": card = cnTunion_Info(name: "兰州新区公交卡", area: "甘肃省", city: "兰州市 兰州新区", issuer: "兰州新区城市公共交通有限公司")

    // MARK: 重庆 - 0310492
    // 主城、江津、永川、荣昌、垫江及万盛开发区
    case "49200": card = cnTunion_Info(name: "宜居畅通卡·交通联合版", area: nil, city: "重庆", issuer: "重庆城市通卡支付有限责任公司")
    case "49201": card = cnTunion_Info(name: "交运通", area: nil, city: "重庆", issuer: "重庆交运城卡科技有限公司")  // その他の区県

    // MARK: 山东省 - 0310493
    case "49300":
        card = cnTunion_Info(
            name: "枣庄汽运交通一卡通/枣庄市交通一卡通", area: "山东省", city: "枣庄市",
            issuer: "山东省枣庄汽车运输有限公司、枣庄市民卡管理有限公司、滕州市上善公交有限公司（滕州公交）、滕州市国运汽车运输有限公司、枣庄骐骥公交客运有限公司（山亭公交）")
    case "49301": card = cnTunion_Info(name: "沂蒙通", area: "山东省", city: "临沂市", issuer: "临沂市沂蒙公交科技有限公司")
    case "49304": card = cnTunion_Info(name: "琴岛通", area: "山东省", city: "青岛市", issuer: "青岛市琴岛通卡股份有限公司")
    case "49305": card = cnTunion_Info(name: "泰安市民卡/省会都市圈卡", area: "山东省", city: "泰安市", issuer: "泰安市公共交通有限公司")
    case "49306": card = cnTunion_Info(name: "烟台市民卡", area: "山东省", city: "烟台市", issuer: "烟台市民卡有限公司")
    case "49307": card = cnTunion_Info(name: "威海市民卡", area: "山东省", city: "威海市", issuer: "威海市民卡有限公司")
    case "49308": card = cnTunion_Info(name: "泉城通/省会都市圈卡", area: "山东省", city: "济南市", issuer: "济南公共交通集团有限公司")
    case "49309": card = cnTunion_Info(name: "齐达通全国交通一卡通/省会都市圈卡", area: "山东省", city: "淄博市", issuer: "淄博齐达通信息技术有限公司")
    case "49310": card = cnTunion_Info(name: "东营公交卡/省会都市圈卡", area: "山东省", city: "东营市", issuer: "东营市公共交通集团有限公司")
    case "49311": card = cnTunion_Info(name: "潍坊通", area: "山东省", city: "潍坊市", issuer: "潍坊市市民卡有限公司")
    case "49312":
        card = cnTunion_Info(
            name: "济宁交通一卡通（市公交）/济宁城际公交IC卡（城际公交）", area: "山东省", city: "济宁市", issuer: "济宁市公共交通集团有限公司、济宁城际公交集团有限公司")
    case "49313": card = cnTunion_Info(name: "滨州交通一卡通/省会都市圈卡", area: "山东省", city: "滨州市", issuer: "滨州市公共汽车公司")
    case "49314": card = cnTunion_Info(name: "德州交通一卡通/省会都市圈卡", area: "山东省", city: "德州市", issuer: "德州市公共汽车公司")
    case "49315": card = cnTunion_Info(name: "聊城交通一卡通/省会都市圈卡", area: "山东省", city: "聊城市", issuer: "聊城市公共交通集团有限公司")
    case "49316": card = cnTunion_Info(name: "菏泽交通一卡通", area: "山东省", city: "菏泽市", issuer: "菏泽公共交通集团有限公司")
    case "49317": card = cnTunion_Info(name: "日照交通一卡通", area: "山东省", city: "日照市", issuer: "日照公交能源集团有限公司信息技术分公司")
    case "49319": card = cnTunion_Info(name: "滨州交运全国交通一卡通", area: "山东省", city: "滨州市", issuer: "山东滨州交运集团有限责任公司")
    case "49320": card = cnTunion_Info(name: "枣庄同诚卡", area: "山东省", city: "枣庄市", issuer: "枣庄市公共交通集团有限公司")

    // MARK: 河北省 - 0310495
    case "49500": card = cnTunion_Info(name: "石家庄公交IC卡", area: "河北省", city: "石家庄市", issuer: "石家庄市公共交通集团有限责任公司")
    case "49501": card = cnTunion_Info(name: "石家庄一卡通·燕赵通", area: "河北省", city: "石家庄市", issuer: "石家庄燕赵通科技有限公司")
    case "49502": card = cnTunion_Info(name: "河北交通一卡通保定卡", area: "河北省", city: "保定市", issuer: "河北一卡通交通服务有限公司")
    case "49503": card = cnTunion_Info(name: "河北交通一卡通", area: "河北省", city: "廊坊市", issuer: "廊坊市交通公路工程有限公司")
    case "49504": card = cnTunion_Info(name: "河北交通一卡通", area: "河北省", city: "张家口市", issuer: "河北一卡通交通服务有限公司")
    case "49505": card = cnTunion_Info(name: "河北交通一卡通唐山卡", area: "河北省", city: "唐山市", issuer: "河北一卡通交通服务有限公司")
    case "49506": card = cnTunion_Info(name: "河北交通一卡通秦皇岛卡", area: "河北省", city: "秦皇岛市", issuer: "河北一卡通交通服务有限公司")
    case "49507": card = cnTunion_Info(name: "河北交通一卡通", area: "河北省", city: "承德市", issuer: "河北一卡通交通服务有限公司")
    case "49508": card = cnTunion_Info(name: "河北交通一卡通", area: "河北省", city: "沧州市", issuer: "河北一卡通交通服务有限公司")
    case "49509": card = cnTunion_Info(name: "河北交通一卡通邢台卡", area: "河北省", city: "邢台市", issuer: "河北一卡通交通服务有限公司")
    case "49510": card = cnTunion_Info(name: "河北交通一卡通", area: "河北省", city: "邯郸市", issuer: "河北一卡通交通服务有限公司")
    case "49511": card = cnTunion_Info(name: "河北交通一卡通衡水卡", area: "河北省", city: "衡水市", issuer: "河北一卡通交通服务有限公司")
    case "49512": card = cnTunion_Info(name: "邯郸市民卡·全国交通一卡通", area: "河北省", city: "邯郸市", issuer: "邯郸市民卡有限公司")
    case "49517": card = cnTunion_Info(name: "雄安公交一卡通", area: "河北省", city: "雄安新区", issuer: "中国雄安集团交通有限公司")

    // MARK: 黑龙江省 - 0310497
    case "49700": card = cnTunion_Info(name: "佳木斯全国交通一卡通", area: "黑龙江省", city: "佳木斯市", issuer: "佳木斯市公共交通有限公司")
    case "49701": card = cnTunion_Info(name: "鸡西交通部卡", area: "黑龙江省", city: "鸡西市", issuer: "鸡西市公共交通有限责任公司")
    case "49702": card = cnTunion_Info(name: "哈尔滨城市通", area: "黑龙江省", city: "哈尔滨市", issuer: "哈尔滨市城市通智能卡有限责任公司")
    case "49703":
        card = cnTunion_Info(name: "齐齐哈尔公交IC卡·齐联卡全国一卡通", area: "黑龙江省", city: "齐齐哈尔市", issuer: "齐齐哈尔市大众智能卡有限公司")
    case "49704": card = cnTunion_Info(name: "鹤岗全国交通一卡通", area: "黑龙江省", city: "鹤岗市", issuer: "鹤岗市公共交通有限责任公司")
    case "49705": card = cnTunion_Info(name: "双鸭山顺达公交卡", area: "黑龙江省", city: "双鸭山市", issuer: "双鸭山市顺达运输集团有限公司")
    case "49706": card = cnTunion_Info(name: "大庆油城公交一卡通", area: "黑龙江省", city: "大庆市", issuer: "大庆市油城公共交通运输有限公司")
    case "49707": card = cnTunion_Info(name: "伊春交通一卡通", area: "黑龙江省", city: "伊春市", issuer: "黑龙江省交通一卡通有限公司")
    case "49708": card = cnTunion_Info(name: "七台河公交IC卡交通联合卡", area: "黑龙江省", city: "七台河市", issuer: "七台河市公共交通有限公司")
    case "49709": card = cnTunion_Info(name: "牡丹江全国交通一卡通公交卡", area: "黑龙江省", city: "牡丹江市", issuer: "牡丹江市通卡科技发展有限责任公司")
    case "49710": card = cnTunion_Info(name: "城市公交一卡通祥和公交卡", area: "黑龙江省", city: "绥化市", issuer: "绥化市祥和公交有限公司")
    case "49711": card = cnTunion_Info(name: "黑河市全国交通一卡通", area: "黑龙江省", city: "黑河市", issuer: "黑龙江省交通一卡通有限公司黑河分公司")
    case "49712": card = cnTunion_Info(name: "大兴安岭加格达奇交通一卡通", area: "黑龙江省", city: "大兴安岭地区", issuer: "大兴安岭利越公共汽车客运有限公司")

    // MARK: 云南省 - 0310498
    case "49802": card = cnTunion_Info(name: "", area: "云南省", city: "德宏傣族景颇族自治州", issuer: "中国工商银行股份有限公司云南德宏分行")
    case "49803": card = cnTunion_Info(name: "丽江交通一卡通", area: "云南省", city: "丽江市", issuer: "中国建设银行股份有限公司丽江市分行")
    case "49804": card = cnTunion_Info(name: "", area: "云南省", city: "迪庆藏族自治州", issuer: "中国建设银行股份有限公司迪庆藏族自治州分行")
    case "49807": card = cnTunion_Info(name: "", area: "云南省", city: "普洱市", issuer: "中国建设银行股份有限公司普洱市分行")
    case "49808": card = cnTunion_Info(name: "", area: "云南省", city: "红河哈尼族彝族自治州", issuer: "中国建设银行股份有限公司红河哈尼族彝族自治州分行")
    case "49809": card = cnTunion_Info(name: "", area: "云南省", city: "文山壮族苗族自治州", issuer: "云南文山交通运输集团公司公交出租车分公司")
    case "49811": card = cnTunion_Info(name: "保山公交IC卡", area: "云南省", city: "保山市", issuer: "保山市公共交通有限公司")
    case "49812": card = cnTunion_Info(name: "楚雄城市交通一卡通·好运通", area: "云南省", city: "楚雄彝族自治州", issuer: "楚雄太阳女城市一卡通科技有限公司")
    case "49813": card = cnTunion_Info(name: "曲靖市公交乘车卡", area: "云南省", city: "曲靖市", issuer: "曲靖市公共汽车有限公司")
    case "49814": card = cnTunion_Info(name: "", area: "云南省", city: "大理白族自治州", issuer: "大理市公共汽车国有独资有限责任公司")
    case "49815": card = cnTunion_Info(name: "", area: "云南省", city: "玉溪市", issuer: "中国建设银行股份有限公司玉溪市分行")
    case "49816": card = cnTunion_Info(name: "昆明智慧通", area: "云南省", city: "昆明市", issuer: "昆明智慧通有限公司、中国建设银行股份有限公司昆明分行")

    // MARK: 安徽省 - 0310499
    case "49900": card = cnTunion_Info(name: "蚌埠城市通卡", area: "安徽省", city: "蚌埠市", issuer: "蚌埠城市通卡有限责任公司")
    case "49902": card = cnTunion_Info(name: "交通部标准合肥通", area: "安徽省", city: "合肥市", issuer: "合肥城市通卡股份有限公司")
    case "49903": card = cnTunion_Info(name: "亳州公交全国交通一卡通", area: "安徽省", city: "亳州市", issuer: "亳州市公共交通集团有限公司")
    case "49904": card = cnTunion_Info(name: "宿州公共交通卡", area: "安徽省", city: "宿州市", issuer: "宿州市公共交通有限公司")
    case "49905": card = cnTunion_Info(name: "颍州通", area: "安徽省", city: "阜阳市", issuer: "阜阳市颍州通卡有限公司")
    case "49906": card = cnTunion_Info(name: "亭城通", area: "安徽省", city: "滁州市", issuer: "滁州市市民卡有限公司")
    case "49907": card = cnTunion_Info(name: "马鞍山市民卡", area: "安徽省", city: "马鞍山市", issuer: "马鞍山市民卡有限公司")
    case "49908": card = cnTunion_Info(name: "芜湖城市卡", area: "安徽省", city: "芜湖市", issuer: "芜湖市惠居住房金融有限公司")
    case "49909": card = cnTunion_Info(name: "铜陵一卡通", area: "安徽省", city: "铜陵市", issuer: "铜陵市公共交通总公司")
    case "49910": card = cnTunion_Info(name: "安庆中北巴士交通一卡通", area: "安徽省", city: "安庆市", issuer: "安庆中北巴士有限公司")
    case "49911": card = cnTunion_Info(name: "六安公交卡交通联合卡", area: "安徽省", city: "六安市", issuer: "六安市皋城公交IC卡有限责任公司")
    case "49913": card = cnTunion_Info(name: "淮北一卡通", area: "安徽省", city: "淮北市", issuer: "淮北市睿智通卡运营管理有限公司")
    case "49914": card = cnTunion_Info(name: "黄山智慧行卡/黄山交通一卡通", area: "安徽省", city: "黄山市", issuer: "黄山智慧行交通科技有限公司")
    case "49915": card = cnTunion_Info(name: "淮南畅通卡", area: "安徽省", city: "淮南市", issuer: "淮南城市通卡有限责任公司")
    case "49916": card = cnTunion_Info(name: "宣城公交IC卡", area: "安徽省", city: "宣城市", issuer: "宣城市公共交通有限公司")
    case "49918": card = cnTunion_Info(name: "池城交通一卡通", area: "安徽省", city: "池州市", issuer: "池州市城市公共交通有限公司")

    // MARK: 海南省 - 0310500
    case "50000": card = cnTunion_Info(name: "海口公交卡", area: "海南省", city: "海口市", issuer: "海口市交通运输投资发展集团有限公司")
    case "50003": card = cnTunion_Info(name: "海南一卡通·文昌通", area: "海南省", city: "文昌市", issuer: "海南海岛一卡通支付网络有限公司")
    case "50010": card = cnTunion_Info(name: "海南一卡通·儋州通", area: "海南省", city: "儋州市", issuer: "海南海岛一卡通支付网络有限公司")
    case "50021": card = cnTunion_Info(name: "天涯行", area: "海南省", city: "三亚市", issuer: "三亚交通科技控股有限公司")

    // MARK: 宁夏回族自治区 - 0310502
    case "50200": card = cnTunion_Info(name: "银川交通一卡通", area: "宁夏回族自治区", city: "银川市", issuer: "银川市公共交通有限公司")
    case "50201": card = cnTunion_Info(name: "石嘴山全国城市公交一卡通", area: "宁夏回族自治区", city: "石嘴山市", issuer: "石嘴山市安道公共交通有限公司")
    case "50202": card = cnTunion_Info(name: "吴忠公交IC卡", area: "宁夏回族自治区", city: "吴忠市", issuer: "吴忠市公共交通有限公司")
    case "50203": card = cnTunion_Info(name: "六盘通", area: "宁夏回族自治区", city: "固原市", issuer: "固原市公共交通有限公司")
    case "50204": card = cnTunion_Info(name: "中卫公交一卡通", area: "宁夏回族自治区", city: "中卫市", issuer: "中卫市卫民公共交通有限责任公司")

    // MARK: 福建省 - 0310506
    case "50600": card = cnTunion_Info(name: "福路通·榕城通", area: "福建省", city: "福州市", issuer: "福州市民卡有限公司")
    case "50601": card = cnTunion_Info(name: "福路通·泉通卡", area: "福建省", city: "泉州市", issuer: "泉州交通一卡通有限责任公司")
    case "50602": card = cnTunion_Info(name: "福路通·平潭海峡通", area: "福建省", city: "平潭综合实验区", issuer: "平潭海峡通信息技术有限公司")
    case "50603": card = cnTunion_Info(name: "福路通·福宁卡", area: "福建省", city: "宁德市", issuer: "宁德交通一卡通有限公司")
    case "50604": card = cnTunion_Info(name: "福路通·龙行卡", area: "福建省", city: "龙岩市", issuer: "龙岩市公共交通有限公司")
    case "50605": card = cnTunion_Info(name: "福路通·莆田城市一卡通", area: "福建省", city: "莆田市", issuer: "莆田市民卡运营管理有限公司")
    case "50606": card = cnTunion_Info(name: "福路通·九龙卡", area: "福建省", city: "漳州市", issuer: "福建漳州市达达通物联网科技有限公司")
    case "50607": card = cnTunion_Info(name: "福路通·明通卡", area: "福建省", city: "三明市", issuer: "三明交运信息科技有限公司")
    case "50608": card = cnTunion_Info(name: "福路通·e通卡", area: "福建省", city: "厦门市", issuer: "厦门易通卡运营有限责任公司")
    case "50609": card = cnTunion_Info(name: "福路通·武夷通", area: "福建省", city: "南平市", issuer: "南平大武夷智慧文旅有限公司")

    // MARK: 河南省 - 0310507
    case "50700": card = cnTunion_Info(name: "轩辕通·平顶山交通一卡通(鹰城通)", area: "河南省", city: "平顶山市", issuer: "平顶山市公共交通有限公司")
    case "50702": card = cnTunion_Info(name: "绿城通", area: "河南省", city: "郑州市", issuer: "郑州城市一卡通有限责任公司")
    case "50703": card = cnTunion_Info(name: "许昌万里一卡通·全国交通一卡通", area: "河南省", city: "许昌市", issuer: "许昌万里一卡通科技有限责任公司")
    case "50705": card = cnTunion_Info(name: "三门峡市公交IC卡", area: "河南省", city: "三门峡市", issuer: "河南省三门峡市公共交通公司")
    case "50706": card = cnTunion_Info(name: "焦作公共交通互联互通卡/武陟公交一卡通", area: "河南省", city: "焦作市", issuer: "焦作市公共交通集团有限公司")
    case "50707": card = cnTunion_Info(name: "轩辕通·全国公交一卡通卡（安阳）", area: "河南省", city: "安阳市", issuer: "安阳市公共交通集团有限公司")
    case "50708": card = cnTunion_Info(name: "轩辕通·天中通", area: "河南省", city: "驻马店市", issuer: "驻马店市公共交通有限公司")
    case "50709": card = cnTunion_Info(name: "轩辕通·南阳交通一卡通卡", area: "河南省", city: "南阳市", issuer: "南阳市公共交通集团有限责任公司")
    case "50710": card = cnTunion_Info(name: "开封公交一卡通", area: "河南省", city: "开封市", issuer: "开封市公共交通有限公司")
    case "50711": card = cnTunion_Info(name: "济源公交IC卡", area: "河南省", city: "济源市", issuer: "济源市交运公共交通有限公司")
    case "50712": card = cnTunion_Info(name: "新乡公交IC卡", area: "河南省", city: "新乡市", issuer: "新乡市公共交通集团有限责任公司")
    case "50713": card = cnTunion_Info(name: "商丘交通一卡通", area: "河南省", city: "商丘市", issuer: "商丘市公共交通有限公司")
    case "50714": card = cnTunion_Info(name: "漯河公交一卡通", area: "河南省", city: "漯河市", issuer: "漯河市公交集团有限公司")
    case "50715": card = cnTunion_Info(name: "洛阳公交IC卡", area: "河南省", city: "洛阳市", issuer: "洛阳市公共交通集团有限公司")
    case "50716": card = cnTunion_Info(name: "濮阳公共交通互联互通卡", area: "河南省", city: "濮阳市", issuer: "濮阳市众意公共交通有限公司")
    case "50717": card = cnTunion_Info(name: "茶城通", area: "河南省", city: "信阳市", issuer: "信阳市公共交通有限责任公司")
    case "50718": card = cnTunion_Info(name: "轩辕通·鹤壁公交IC卡", area: "河南省", city: "鹤壁市", issuer: "鹤壁市国控公共交通有限公司")
    case "50719": card = cnTunion_Info(name: "轩辕通·周口交通一卡通卡", area: "河南省", city: "周口市", issuer: "周口市公共交通总公司")
    case "50720": card = cnTunion_Info(name: "轩辕通·许昌公交交通一卡通", area: "河南省", city: "许昌市", issuer: "许昌市城市公共交通有限公司")
    case "50721": card = cnTunion_Info(name: "轩辕通·巩义", area: "河南省", city: "郑州市 巩义市", issuer: "巩义市公共交通运输有限公司")
    case "50722": card = cnTunion_Info(name: "轩辕通·滑县", area: "河南省", city: "安阳市 滑县", issuer: "滑县通达公共交通运输集团有限公司")
    case "50723": card = cnTunion_Info(name: "轩辕通·民权", area: "河南省", city: "商丘市 民权县", issuer: "民权县晋发城市公交有限公司")
    case "50724": card = cnTunion_Info(name: "轩辕通·卢氏县", area: "河南省", city: "三门峡市 卢氏县", issuer: "卢氏县公共交通有限公司")
    case "50725": card = cnTunion_Info(name: "轩辕通·邓州", area: "河南省", city: "南阳市 邓州市", issuer: "邓州市城市公共交通有限责任公司")
    case "50726": card = cnTunion_Info(name: "洛阳交通一卡通", area: "河南省", city: "洛阳市", issuer: "洛阳交通一卡通有限公司")

    // MARK: 内蒙古自治区 - 0310511
    case "51100": card = cnTunion_Info(name: "鹿城通·互联互通卡", area: "内蒙古自治区", city: "包头市", issuer: "包头市城市一卡通有限公司")
    case "51101": card = cnTunion_Info(name: "呼和浩特全国交通一卡通", area: "内蒙古自治区", city: "呼和浩特市", issuer: "呼和浩特市公共交通有限责任公司")
    case "51102":
        card = cnTunion_Info(name: "乌海交通一卡通", area: "内蒙古自治区", city: "乌海市", issuer: "内蒙古狮城交通集团有限责任公司、乌海市海南区城乡公共交通有限公司")
    case "51103": card = cnTunion_Info(name: "赤峰交通一卡通", area: "内蒙古自治区", city: "赤峰市", issuer: "赤峰市公共交通有限责任公司")
    case "51104":
        card = cnTunion_Info(name: "呼伦贝尔交通一卡通", area: "内蒙古自治区", city: "呼伦贝尔市", issuer: "呼伦贝尔市海拉尔区明途公共汽车有限责任公司")
    case "51105": card = cnTunion_Info(name: "", area: "内蒙古自治区", city: "兴安盟 阿尔山市", issuer: "阿尔山市宏盛公交客运公司")
    case "51106": card = cnTunion_Info(name: "通辽开鲁交通一卡通", area: "内蒙古自治区", city: "通辽市 开鲁县", issuer: "开鲁县公共交通运输有限责任公司")
    case "51107":
        card = cnTunion_Info(name: "锡林浩特交通一卡通", area: "内蒙古自治区", city: "锡林郭勒盟 锡林浩特市", issuer: "锡林浩特市天安公共交通有限责任公司")
    case "51108": card = cnTunion_Info(name: "", area: "内蒙古自治区", city: "乌兰察布市", issuer: "凉城县鑫运公交服务有限公司")
    case "51109": card = cnTunion_Info(name: "天骄通", area: "内蒙古自治区", city: "鄂尔多斯市", issuer: "鄂尔多斯市市民卡建设有限公司")
    case "51110": card = cnTunion_Info(name: "巴彦淖尔交通一卡", area: "内蒙古自治区", city: "巴彦淖尔市", issuer: "巴彦淖尔运通运输服务有限公司")
    case "51111":
        card = cnTunion_Info(name: "阿拉善交通一卡通", area: "内蒙古自治区", city: "阿拉善盟", issuer: "阿拉善盟唐盛公交有限公司、阿拉善左旗城市公交有限责任公司")
    case "51113":
        card = cnTunion_Info(name: "二连浩特交通一卡通", area: "内蒙古自治区", city: "锡林郭勒盟 二连浩特市", issuer: "二连浩特市北辰公共交通有限责任公司")
    case "51114":
        card = cnTunion_Info(name: "内蒙古三代社保卡", area: "内蒙古自治区", city: "乌海市", issuer: "内蒙古狮城交通集团有限责任公司、乌海市海南区城乡公共交通有限公司")

    // MARK: 辽宁省 - 0310512
    case "51200": card = cnTunion_Info(name: "互联互通明珠卡", area: "辽宁省", city: "大连市", issuer: "大连明珠公用卡股份有限公司")
    case "51201": card = cnTunion_Info(name: "盛京通交通联合卡", area: "辽宁省", city: "沈阳市", issuer: "沈阳盛京通有限公司")
    case "51202": card = cnTunion_Info(name: "抚顺城市通", area: "辽宁省", city: "抚顺市", issuer: "抚顺浑河城市通卡有限公司")
    case "51203": card = cnTunion_Info(name: "鞍山交运通卡", area: "辽宁省", city: "鞍山市", issuer: "鞍山市交通运输集团有限公司")
    case "51204": card = cnTunion_Info(name: "本溪公交IC卡", area: "辽宁省", city: "本溪市", issuer: "本溪客运集团有限公司")
    case "51205": card = cnTunion_Info(name: "鸭绿江通", area: "辽宁省", city: "丹东市", issuer: "丹东市公共交通总公司")
    case "51206": card = cnTunion_Info(name: "锦州公交IC卡", area: "辽宁省", city: "锦州市", issuer: "锦州市公共交通有限责任公司")
    case "51207": card = cnTunion_Info(name: "营口通", area: "辽宁省", city: "营口市", issuer: "营口交通运输集团有限公司")
    case "51208": card = cnTunion_Info(name: "阜新公交IC卡", area: "辽宁省", city: "阜新市", issuer: "阜新虎跃城市公交有限公司")
    case "51209": card = cnTunion_Info(name: "辽阳交通一卡通", area: "辽宁省", city: "辽阳市", issuer: "辽阳市公共汽车有限公司")
    case "51210": card = cnTunion_Info(name: "盘锦公交IC卡", area: "辽宁省", city: "盘锦市", issuer: "盘锦市公共交通有限公司")
    case "51211": card = cnTunion_Info(name: "铁岭全国交通一卡通", area: "辽宁省", city: "铁岭市", issuer: "铁岭市公共汽车公司")
    case "51212": card = cnTunion_Info(name: "朝阳公交IC卡互联互通卡", area: "辽宁省", city: "朝阳市", issuer: "朝阳市公共交通有限责任公司")
    case "51213": card = cnTunion_Info(name: "葫芦岛公交IC卡", area: "辽宁省", city: "葫芦岛市", issuer: "葫芦岛城市公交客运有限公司")

    // MARK: 山西省 - 0310513
    case "51300": card = cnTunion_Info(name: "太原公交IC卡全国交通一卡通", area: "山西省", city: "太原市", issuer: "太原公共交通控股(集团)有限公司")
    case "51301": card = cnTunion_Info(name: "大同公交IC卡交通一卡通", area: "山西省", city: "大同市", issuer: "大同市公共交通有限责任公司")
    case "51302": card = cnTunion_Info(name: "阳泉公交IC卡全国交通一卡通", area: "山西省", city: "阳泉市", issuer: "阳泉市公共交通有限责任公司")
    case "51303": card = cnTunion_Info(name: "通联卡/公交通卡", area: "山西省", city: "长治市", issuer: "长治市公共交通集团有限责任公司")
    case "51304": card = cnTunion_Info(name: "晋城公交IC卡", area: "山西省", city: "晋城市", issuer: "晋城市公共交通有限公司")
    case "51305": card = cnTunion_Info(name: "朔州交通一卡通", area: "山西省", city: "朔州市", issuer: "朔州市公共汽车交通责任有限公司")
    case "51306": card = cnTunion_Info(name: "三晋通·忻州通", area: "山西省", city: "忻州市", issuer: "忻州公共交通有限公司")
    case "51307": card = cnTunion_Info(name: "畅行通卡·吕梁公交IC卡", area: "山西省", city: "吕梁市", issuer: "山西畅行通卡科技服务有限公司")
    case "51308": card = cnTunion_Info(name: "晋中交通一卡通", area: "山西省", city: "晋中市", issuer: "晋中瑞达公交有限公司")
    case "51309": card = cnTunion_Info(name: "临汾公共交通一卡通", area: "山西省", city: "临汾市", issuer: "临汾公共交通有限公司")
    case "51310": card = cnTunion_Info(name: "运城全国交通一卡通", area: "山西省", city: "运城市", issuer: "运城市公共交通公司")
    case "51311": card = cnTunion_Info(name: "畅行通卡·山西交通一卡通", area: "山西省", city: "太原市", issuer: "山西畅行通卡科技服务有限公司")

    // MARK: 湖北省 - 0310514
    case "51400": card = cnTunion_Info(name: "武汉通交通联合卡", area: "湖北省", city: "武汉市", issuer: "武汉城市一卡通支付有限公司")
    case "51401": card = cnTunion_Info(name: "黄石公交IC卡", area: "湖北省", city: "黄石市", issuer: "黄石市城市公交集团有限公司")
    case "51402": card = cnTunion_Info(name: "车城通全国交通一卡通", area: "湖北省", city: "十堰市", issuer: "十堰市车城通科技有限公司")
    case "51403": card = cnTunion_Info(name: "全国一卡通·湖北宜昌", area: "湖北省", city: "宜昌市", issuer: "宜昌公交集团有限责任公司")
    case "51404": card = cnTunion_Info(name: "随州一卡通", area: "湖北省", city: "随州市", issuer: "随州市公共交通有限责任公司")
    case "51405": card = cnTunion_Info(name: "襄阳全国公交一卡通", area: "湖北省", city: "襄阳市", issuer: "襄阳市公共交通集团有限责任公司")
    case "51406": card = cnTunion_Info(name: "鄂州交通IC卡", area: "湖北省", city: "鄂州市", issuer: "鄂州市公共交通有限公司")
    case "51407": card = cnTunion_Info(name: "荆门市民卡", area: "湖北省", city: "荆门市", issuer: "荆门市公共交通集团有限公司")
    case "51408": card = cnTunion_Info(name: "黄冈全国公交一卡通", area: "湖北省", city: "黄冈市", issuer: "黄冈市公共交通发展有限公司")
    case "51409": card = cnTunion_Info(name: "全国一卡通·湖北孝感", area: "湖北省", city: "孝感市", issuer: "孝感市众益公交集团众力公共交通运输有限责任公司")
    case "51410": card = cnTunion_Info(name: "咸宁一卡通", area: "湖北省", city: "咸宁市", issuer: "咸宁市枫丹一卡通管理有限公司")
    case "51411": card = cnTunion_Info(name: "荆州版全国一卡通", area: "湖北省", city: "荆州市", issuer: "荆州市公共交通集团有限责任公司")
    case "51412": card = cnTunion_Info(name: "恩施全国一卡通", area: "湖北省", city: "恩施土家族苗族自治州", issuer: "恩施市公共汽车有限责任公司")
    case "51413": card = cnTunion_Info(name: "潜江一卡通", area: "湖北省", city: "潜江市", issuer: "湖北楚捷公共交通股份有限公司")
    case "51414": card = cnTunion_Info(name: "仙桃全国一卡通", area: "湖北省", city: "仙桃市", issuer: "仙桃市顺达公交服务有限公司")

    // MARK: 特別行政区
    case "48500": card = cnTunion_Info(name: "八达通", area: "香港特别行政区", city: nil, issuer: "八达通卡有限公司")
    case "49600": card = cnTunion_Info(name: "澳门通", area: "澳门特别行政区", city: nil, issuer: "澳门通股份有限公司")

    default: card = cnTunion_Info(name: "", area: nil, city: nil, issuer: nil)
    }
    return card
}
