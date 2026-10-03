import SwiftUI

struct cnTunion_Info: Hashable, Codable {
    let name: String
    let area: String?
    let city: String?
    let issuer: String?
}

// https://ipt.kopisee.com/canton/zh-cn/t-union
func cnTunion_getIssueInfo(iin:String) -> cnTunion_Info {
    let card:cnTunion_Info
    
    //IDの先頭9文字がIINで、そのうち先頭4文字は0310で固定
    switch iin.prefix(9).dropFirst(4) {
    //MARK: 北京 - 0310517
    case "51700": card = cnTunion_Info(name:"北京一卡通",area:nil,city:"北京",issuer:"北京市政交通一卡通支付有限公司")
        
    //MARK: 上海 - 0310477
    case "47700": card = cnTunion_Info(name:"上海公共交通卡",area:nil,city:"上海",issuer:"上海公共交通卡股份有限公司")
        
    //MARK: 天津 - 0310491
    case "49102": card = cnTunion_Info(name:"天津城市卡",area:nil,city:"天津",issuer:"天津城市一卡通支付有限公司")
        
    // MARK: 江西省 - 0310473
    case "47300": card = cnTunion_Info(name:"洪城一卡通",area:"江西省",city:"南昌市",issuer:"江西省洪城一卡通投资有限公司")
    case "47301": card = cnTunion_Info(name:"赣州通",area:"江西省",city:"赣州市",issuer:"赣州城市一卡通有限公司")
    case "47302": card = cnTunion_Info(name:"景德镇公交卡",area:"江西省",city:"景德镇市",issuer:"景德镇公共交通有限公司")
    case "47303": card = cnTunion_Info(name:"萍乡交通一卡通",area:"江西省",city:"萍乡市",issuer:"萍乡市公共交通集团有限公司")
    case "47304": card = cnTunion_Info(name:"九江交通一卡通",area:"江西省",city:"九江市",issuer:"九江市公共交通集团公司")
    case "47305": card = cnTunion_Info(name:"新余公交一卡通",area:"江西省",city:"新余市",issuer:"江西长运新余公共交通有限公司")
    case "47306": card = cnTunion_Info(name:"鹰潭互联互通卡",area:"江西省",city:"鹰潭市",issuer:"江西长运鹰潭公共交通有限公司")
    case "47307": card = cnTunion_Info(name:"宜春公交明月通",area:"江西省",city:"宜春市",issuer:"宜春公交集团有限公司")
    case "47308": card = cnTunion_Info(name:"上饶公交IC卡",area:"江西省",city:"上饶市",issuer:"上饶市公共交通集团有限公司")
    case "47309": card = cnTunion_Info(name:"吉安通",area:"江西省",city:"吉安市",issuer:"江西长运吉安公共交通有限责任公司")
    case "47310": card = cnTunion_Info(name:"抚州交通一卡通",area:"江西省",city:"抚州市",issuer:"抚州市公共交通有限责任公司")
        
    // MARK: 贵州省 - 0310474
    case "47400": card = cnTunion_Info(name:"贵阳公交电子车票",area:"贵州省",city:"贵阳市",issuer:"贵阳市信捷科技有限公司")
    case "47401": card = cnTunion_Info(name:"遵义交通一卡通",area:"贵州省",city:"遵义市",issuer:"遵义市公共交通(集团)有限责任公司")
    case "47402": card = cnTunion_Info(name:"凉都市民卡",area:"贵州省",city:"六盘水市",issuer:"六盘水凉都市民卡有限公司")
    case "47403": card = cnTunion_Info(name:"安顺公交一卡通",area:"贵州省",city:"安顺市",issuer:"安顺市公共交通总公司")
    case "47404": card = cnTunion_Info(name:"九驿通",area:"贵州省",city:"毕节市大方县",issuer:"大方县城市翼卡支付有限公司")
    case "47405": card = cnTunion_Info(name:"桃源卡",area:"贵州省",city:"铜仁市",issuer:"铜仁市公共交通有限责任公司")
    case "47406": card = cnTunion_Info(name:"兴义卡",area:"贵州省",city:"黔西南布依族苗族自治州",issuer:"兴义市城市公交公司")
    case "47407": card = cnTunion_Info(name:"凯里公交IC卡",area:"贵州省",city:"黔东南苗族侗族自治州",issuer:"贵州省凯里市公共交通总公司")
    case "47408": card = cnTunion_Info(name:"贵州黔南全国交通一卡通",area:"贵州省",city:"黔南布依族苗族自治州",issuer:"都匀市公共交通总公司")
    case "47409": card = cnTunion_Info(name:"一应黔行",area:"贵州省",city:"贵阳市",issuer:"贵阳市信捷科技有限公司")
    case "47410": card = cnTunion_Info(name:"同心市民卡",area:"贵州省",city:"毕节市",issuer:nil)
        
    // MARK: 西藏自治区 - 0310475
    case "47500": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"拉萨市",issuer:"西藏中信海博电子科技有限公司")
    case "47501": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"昌都市",issuer:"西藏中信海博电子科技有限公司")
    case "47502": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"山南市",issuer:"西藏中信海博电子科技有限公司")
    case "47503": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"日喀则市",issuer:"西藏中信海博电子科技有限公司")
    case "47504": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"那曲市",issuer:"西藏中信海博电子科技有限公司")
    case "47505": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"阿里地区",issuer:"西藏中信海博电子科技有限公司")
    case "47506": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"林芝市",issuer:"西藏中信海博电子科技有限公司")
        
    // MARK: 青海省 - 0310476
    case "47600": card = cnTunion_Info(name:"夏都通",area:"青海省",city:"西宁市",issuer:"西宁智能一卡通责任有限公司")
    case "47601": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"海东市",issuer:"青海省高速公路运营管理有限公司")
    case "47603": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"黄南藏族自治州",issuer:"青海省高速公路运营管理有限公司")
    case "47604": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"黄南藏族自治州",issuer:"青海省高速公路运营管理有限公司")
    case "47606": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"玉树藏族自治州",issuer:"青海省高速公路运营管理有限公司")
    case "47607": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"海西蒙古族藏族自治州",issuer:"青海省高速公路运营管理有限公司")
       
    // MARK: 四川省 - 0310478
    case "47800": card = cnTunion_Info(name:"天府通",area:"四川省",city:"成都市",issuer:"成都天府通金融服务股份有限公司")
    case "47801": card = cnTunion_Info(name:"甜城通",area:"四川省",city:"内江市",issuer:"内江市公共交通集团有限责任公司")
    case "47802": card = cnTunion_Info(name:"月城一卡通",area:"四川省",city:"内江市",issuer:"内江市公共交通集团有限责任公司")
    case "47803": card = cnTunion_Info(name:"乐山交通卡",area:"四川省",city:"乐山市",issuer:"乐山市通联智能交通科技有限公司")
    case "47804": card = cnTunion_Info(name:"自贡通",area:"四川省",city:"自贡市",issuer:"自贡盐都一卡通信息化有限责任公司")
    case "47805": card = cnTunion_Info(name:"攀枝花公交卡",area:"四川省",city:"攀枝花市",issuer:"攀枝花公交客运总公司")
    case "47806": card = cnTunion_Info(name:"酒城一卡通",area:"四川省",city:"泸州市",issuer:"泸州市公共交通集团有限公司")
    case "47807": card = cnTunion_Info(name:"德阳全国交通一卡通",area:"四川省",city:"德阳市",issuer:"德阳裕兴公共交通有限公司")
    case "47808": card = cnTunion_Info(name:"绵州通",area:"四川省",city:"绵阳市",issuer:"绵阳市绵州通有限责任公司")
    case "47809": card = cnTunion_Info(name:"利州通",area:"四川省",city:"广元市",issuer:"广元市公共交通公司")
    case "47810": card = cnTunion_Info(name:"遂州通",area:"四川省",city:"遂宁市",issuer:"遂宁遂州通有限公司")
    case "47811": card = cnTunion_Info(name:"宜宾一卡通",area:"四川省",city:"宜宾市",issuer:"宜宾市和谐卡务有限公司")
    case "47812": card = cnTunion_Info(name:"南充公交卡",area:"四川省",city:"南充市",issuer:"南充市公共交通有限责任公司")
    case "47813": card = cnTunion_Info(name:"达州通",area:"四川省",city:"达州市",issuer:"达州市感知生活科技有限公司")
    case "47814": card = cnTunion_Info(name:"雅安交通一卡通",area:"四川省",city:"雅安市",issuer:"雅安市公共交通有限公司")
    case "47816": card = cnTunion_Info(name:"康定公交一卡通",area:"四川省",city:"甘孜藏族自治州",issuer:"康定公共交通运输有限责任公司")
    case "47817": card = cnTunion_Info(name:"眉山交通一卡通",area:"四川省",city:"眉山市",issuer:"眉山市展通公交客运有限公司")
    case "47818": card = cnTunion_Info(name:"广安全国一卡通",area:"四川省",city:"广安市",issuer:"广安市广泰公共交通有限责任公司")
    case "47819": card = cnTunion_Info(name:"巴中交通一卡通",area:"四川省",city:"巴中市",issuer:"巴中市巴山公共交通有限公司")
    case "47821": card = cnTunion_Info(name:"古城阆中通",area:"四川省",city:"南充市",issuer:"阆中滕王阁旅游公交有限公司")
        
    // MARK: 新疆维吾尔自治区 - 0310479
    case "47900": card = cnTunion_Info(name:"红山一卡通",area:"新疆维吾尔自治区",city:"乌鲁木齐市",issuer:"乌鲁木齐红山一卡通有限责任公司")
    case "47901": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"阿拉尔市",issuer:"捷行信息技术有限公司")
    case "47902": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"铁门关市",issuer:"捷行信息技术有限公司")
    case "47903": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"图木舒克市",issuer:"捷行信息技术有限公司")
    case "47904": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"可克达拉市",issuer:nil) //割り振りのみ
    case "47905": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"双河市",issuer:nil) //割り振りのみ
    case "47906": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"五家渠市",issuer:"捷行信息技术有限公司")
    case "47907": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"胡杨河市",issuer:nil) //割り振りのみ
    case "47908": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"石河子市",issuer:"捷行信息技术有限公司")
    case "47909": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"白杨市",issuer:nil) //割り振りのみ
    case "47910": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"北屯市",issuer:"北屯新建旅客运输有限责任公司")
    case "47911": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"乌鲁木齐市",issuer:"捷行信息技术有限公司")
    case "47912": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"新星市",issuer:"哈密市红星客运服务有限公司")
    case "47913": card = cnTunion_Info(name:"崑玉交通一卡通",area:"新疆维吾尔自治区",city:"昆玉市",issuer:"昆玉市安达运输有限公司")
    case "47914": card = cnTunion_Info(name:"克拉玛依公交卡",area:"新疆维吾尔自治区",city:"克拉玛依市",issuer:"克拉玛依市汽车运输有限责任公司")
    case "47915": card = cnTunion_Info(name:"吐鲁番公交卡",area:"新疆维吾尔自治区",city:"吐鲁番市",issuer:"吐鲁番鹏祥公共交通有限公司")
    case "47916": card = cnTunion_Info(name:"哈密市公交卡",area:"新疆维吾尔自治区",city:"哈密市",issuer:"哈密市东畅公共交通有限责任公司")
    case "47917": card = cnTunion_Info(name:"昌吉智慧城市一卡通",area:"新疆维吾尔自治区",city:"昌吉回族自治州 昌吉市",issuer:"昌吉公共交通(集团)有限责任公司")
    case "47918": card = cnTunion_Info(name:"博乐互通卡",area:"新疆维吾尔自治区",city:"博尔塔拉蒙古自治州 博乐市",issuer:"博乐市阳光公共交通有限责任公司")
    case "47919": card = cnTunion_Info(name:"库尔勒市公交卡",area:"新疆维吾尔自治区",city:"巴音郭楞蒙古自治州 库尔勒市",issuer:"库尔勒市公共交通有限责任公司")
    case "47920": card = cnTunion_Info(name:"阿克苏互通卡",area:"新疆维吾尔自治区",city:"阿克苏地区 阿克苏市",issuer:"阿克苏姑墨交通投资有限责任公司")
    case "47921": card = cnTunion_Info(name:"阿图什互通卡",area:"新疆维吾尔自治区",city:"克孜勒苏柯尔克孜自治州 阿图什市",issuer:"阿图什顺达公交有限责任公司")
    case "47922": card = cnTunion_Info(name:"喀什智慧城市一卡通",area:"新疆维吾尔自治区",city:"喀什地区",issuer:"喀什市公共交通有限责任公司")
    case "47923": card = cnTunion_Info(name:"",area:"新疆维吾尔自治区",city:"和田地区",issuer:nil) //割り当てのみ
    case "47924": card = cnTunion_Info(name:"伊宁公交卡",area:"新疆维吾尔自治区",city:"伊犁哈萨克自治州 伊宁市",issuer:"伊宁市公共交通(集团)有限责任公司")
    case "47926": card = cnTunion_Info(name:"阿勒泰智慧城市一卡通",area:"新疆维吾尔自治区",city:"阿勒泰地区",issuer:"阿勒泰市利众公共交通有限公司")
        
    // MARK: 陕西省 - 0310479
    case "48000": card = cnTunion_Info(name:"长安通",area:"陕西省",city:"西安市",issuer:"西安长安通有限责任公司")
    case "48001": card = cnTunion_Info(name:"咸阳城市公交一卡通",area:"陕西省",city:"咸阳市",issuer:"咸阳市公共交通集团公司")
    case "48002": card = cnTunion_Info(name:"宝鸡公交卡",area:"陕西省",city:"宝鸡市",issuer:"宝鸡市公共交通有限责任公司")
    case "48003": card = cnTunion_Info(name:"渭南通",area:"陕西省",city:"渭南市",issuer:"渭南市公共交通总公司")
    case "48004": card = cnTunion_Info(name:"铜川交通一卡通",area:"陕西省",city:"铜川市",issuer:"铜川市公共交通有限责任公司")
    case "48006": card = cnTunion_Info(name:"延安公交一卡通",area:"陕西省",city:"延安市",issuer:"延安市公共交通总公司")
    case "48007": card = cnTunion_Info(name:"天汉通",area:"陕西省",city:"汉中市",issuer:"汉中天汉一卡通有限责任公司")
    case "48008": card = cnTunion_Info(name:"安康公交卡",area:"陕西省",city:"安康市",issuer:"安康市公共交通一卡通有限公司")
    case "48009": card = cnTunion_Info(name:"商洛公交一卡通",area:"陕西省",city:"商洛市",issuer:"商洛市公共汽车公司")
    case "48011": card = cnTunion_Info(name:"榆林驼城通交通卡",area:"陕西省",city:"榆林市",issuer:"榆林城投数字城市建设管理有限责任公司")
    case "48013": card = cnTunion_Info(name:"农科城卡",area:"陕西省",city:"杨凌农业高新技术产业示范区",issuer:"杨凌示范区科技信息中心")
    case "48014": card = cnTunion_Info(name:"西咸一卡通",area:"陕西省",city:"西安市",issuer:"咸阳城市一卡通有限责任公司")
    
    // MARK: 湖南省 - 0310482
    case "48200": card = cnTunion_Info(name:"长沙潇湘卡",area:"湖南省",city:"长沙市",issuer:"湖南潇湘支付有限公司")
    case "48202": card = cnTunion_Info(name:"株洲公交IC卡",area:"湖南省",city:"株洲市",issuer:"株洲市公共交通集团有限责任公司")
    case "48203": card = cnTunion_Info(name:"湘潭交通卡",area:"湖南省",city:"湘潭市",issuer:"湘潭综合交通科技服务有限公司")
    case "48204": card = cnTunion_Info(name:"衡阳交通卡",area:"湖南省",city:"衡阳市",issuer:"衡阳市公共交通集团有限公司")
    case "48205": card = cnTunion_Info(name:"宝庆一卡通",area:"湖南省",city:"邵阳市",issuer:"邵阳市交通运输信息中心")
    case "48206": card = cnTunion_Info(name:"岳阳通",area:"湖南省",city:"岳阳市",issuer:"岳阳通源投资咨询有限公司")
    case "48207": card = cnTunion_Info(name:"常德公交卡",area:"湖南省",city:"常德市",issuer:"常德市公共交通有限责任公司")
    case "48208": card = cnTunion_Info(name:"张家界一卡通",area:"湖南省",city:"张家界市",issuer:"张家界一卡通科技有限公司")
    case "48209": card = cnTunion_Info(name:"银城一卡通",area:"湖南省",city:"益阳市",issuer:"湖南省益阳市公交公司")
    case "48210": card = cnTunion_Info(name:"娄底公交卡",area:"湖南省",city:"娄底市",issuer:"娄底市公共交通有限公司")
    case "48211": card = cnTunion_Info(name:"福城通",area:"湖南省",city:"郴州市",issuer:"湖南郴州汽车运输集团有限责任公司")
    case "48212": card = cnTunion_Info(name:"永州城市一卡通",area:"湖南省",city:"永州市",issuer:"永州市城市公共交通运输有限责任公司")
    case "48213": card = cnTunion_Info(name:"怀化公交IC卡",area:"湖南省",city:"怀化市",issuer:"怀化公共交通集团有限责任公司")
    case "48214": card = cnTunion_Info(name:"湘西州交通一卡通",area:"湖南省",city:"湘西土家族苗族自治州 吉首市",issuer:"吉首市公共汽车公司")
        
        
    // MARK: 江苏省 - 0310483
    // https://zh.wikipedia.org/zh-cn/江苏交通一卡通
    case "48300": card = cnTunion_Info(name:"金陵通",area:"江苏省",city:"南京市",issuer:"南京市市民卡支付有限公司")
    case "48301": card = cnTunion_Info(name:"扬州市民卡",area:"江苏省",city:"扬州市",issuer:"扬州数慧城建科技有限责任公司")
    case "48302": card = cnTunion_Info(name:"镇江公交IC卡",area:"江苏省",city:"镇江市",issuer:"镇江市公共交通有限公司")
    case "48303": card = cnTunion_Info(name:"苏州市民卡",area:"江苏省",city:"苏州市",issuer:"苏州城慧通数字科技有限公司")
    case "48304": card = cnTunion_Info(name:"南通市民卡",area:"江苏省",city:"南通市",issuer:"南通市民卡有限公司")
    case "48305": card = cnTunion_Info(name:"常州市民卡",area:"江苏省",city:"常州市",issuer:"常州市市民卡建设有限公司")
    case "48306": card = cnTunion_Info(name:"宿迁市民卡",area:"江苏省",city:"宿迁市",issuer:"宿迁市市民卡有限公司")
    case "48307": card = cnTunion_Info(name:"黄海通市民卡",area:"江苏省",city:"盐城市",issuer:"盐城市黄海通市民卡有限责任公司")
    case "48308": card = cnTunion_Info(name:"江淮通",area:"江苏省",city:"淮安市",issuer:"淮安市数据集团有限公司")
    case "48309": card = cnTunion_Info(name:"淮海通",area:"江苏省",city:"徐州市",issuer:"徐州市市民卡有限公司")
    case "48310": card = cnTunion_Info(name:"连云港市民卡",area:"江苏省",city:"连云港市",issuer:"江苏云质数科技术有限公司")
    case "48311": card = cnTunion_Info(name:"泰州通",area:"江苏省",city:"泰州市",issuer:"泰州市凤城一卡通有限公司")
    case "48312": card = cnTunion_Info(name:"江苏交通一卡通",area:"江苏省",city:nil,issuer:nil)
    case "48315": card = cnTunion_Info(name:"泰州通",area:"江苏省",city:"昆山市",issuer:"昆通卡")
        
        
    // MARK: 江苏省 - 0310484
        
    /*
    case "48401": card = "柳州市民卡"
    case "48402": card = "桂林通"
    case "48403": card = "梧州通"
    case "48406": card = "百色通"
    case "48407": card = "河池通"
    case "48408": card = "钦州市民卡"
    case "48409": card = "防城港通"
    case "48410": card = "贵港市民卡"
    case "48411": card = "贺州通"
    case "48412": card = "来宾通"
    case "48413": card = "崇左通"
     
    case "48701": card = "甜城通"
    case "48702": card = "东莞通"
    case "48703": card = "羊城通"
    case "48704": card = "深圳通"
    case "48705": card = "中山通"
    case "48707": card = "广佛通"
    case "48708": card = "惠州通"
    case "48711": card = "茂城通"
    case "48712": card = "肇庆通"
    case "48714": card = "嘉应通"
    case "48717": card = "清远市民卡"
    case "48719": card = "榕江通"
    case "48721": card = "潮州通"
    case "48722": card = "岭云通"
    case "48724": card = "珠海通"
     
    case "48800": card = "温州城市公交IC卡"
    case "48801": card = "杭州通"
    case "48802": card = "甬城通交通部卡"
    case "48803": card = "嘉兴交通一卡通"
    case "48804": card = "台州通"
    case "48805": card = "金华交通一卡通"
    case "48806": card = "湖州交通一卡通"
    case "48807": card = "绍兴一卡通"
     
    case "48900": card = "长春轨道交通一卡通"
    case "48901": card = "吉林通"
    case "48902": card = "长春公交一卡通"
    case "48903": card = "通化交通一卡通"
    case "48904": card = "长春城联一卡通"
    case "48905": card = "白山交通一卡通"
    case "48906": card = "蛟河客运公交一卡通"
    case "48908": card = "四平城市交通一卡通"
    case "48910": card = "鹤城通"
    case "48912": card = "松原通"
    case "48914": card = "通化交通一卡通(农安)"
    case "48916": card = "通化交通一卡通(九台)"
    case "48917": card = "永吉万联惠民通卡"
    case "48923": card = "双辽市交通一卡通"
    case "48924": card = "公主岭万联惠民卡"
    case "48929": card = "通化交通一卡通(柳河)"
    case "48930": card = "梅河口交通一卡通"
    case "48931": card = "通化交通一卡通(集安)"
    case "48939": card = "延吉交通一卡通"
    case "48942": card = "唰唰通"
    case "48946": card = "延边交通一卡通"
    case "48948": card = "通化交通一卡通(长岭)"
    case "48951": card = "通化交通一卡通(双阳)"
    case "49000": card = "兰州公交普通卡"
    case "49003": card = "金昌通"
    case "49006": card = "酒泉通"
    case "49007": card = "山丹"
    case "49008": card = "凉州通"
    case "49011": card = "环县通"
    case "49200": card = "宜居畅通卡"
    case "49201": card = "交运通"
    case "49300": card = "枣庄汽运交通一卡通"
    case "49301": card = "沂蒙通"
    case "49304": card = "琴岛通"
    case "49307": card = "威海市民卡"
    case "49308": card = "泉城通"
    case "49310": card = "东营市交通一卡通"
    case "49311": card = "潍坊通"
    case "49312": card = "济宁公交卡"
    case "49313": card = "滨州公交一卡通"
    case "49314": card = "德州交通一卡通"
    case "49315": card = "水城通"
    case "49316": card = "菏泽交通一卡通"
    case "49317": card = "日照交通一卡通"
    case "49320": card = "枣庄同诚卡"
    case "49500": card = "石家庄公交卡"
    case "49501": card = "燕赵通"
    case "49502": card = "保定卡"
    case "49503": card = "河北一卡通卡(廊坊)"
    case "49504": card = "河北一卡通(张家口)"
    case "49505": card = "唐山公交IC卡"
    case "49506": card = "秦皇岛公交卡"
    case "49507": card = "河北一卡通卡(承德)"
    case "49508": card = "河北一卡通卡(沧州)"
    case "49509": card = "邢台卡"
    case "49511": card = "河北一卡通卡(衡水)"
    case "49512": card = "邯郸市民卡"
    case "49517": card = "雄安交通一卡通"
    case "49702": card = "哈尔滨城市卡"
    case "49703": card = "齐联卡"
    case "49707": card = "黑龙江一卡通"
    case "49812": card = "好运通"
    case "49813": card = "曲靖市公交乘车卡"
    case "49816": card = "昆明智慧通"
    case "49900": card = "蚌埠公交一卡通"
    case "49902": card = "合肥通"
    case "49903": card = "亳州交通一卡通"
    case "49904": card = "宿州公共交通卡"
    case "49905": card = "颍州通"
    case "49906": card = "亭城通"
    case "49907": card = "马鞍山市民卡"
    case "49908": card = "芜湖城市卡"
    case "49909": card = "铜陵一卡通"
    case "49910": card = "安庆中北巴士交通一卡通"
    case "49911": card = "六安公交一卡通"
    case "49913": card = "淮北一卡通"
    case "49914": card = "黄山交通一卡通"
    case "49915": card = "淮南畅通卡"
    case "49916": card = "宣城公交IC卡"
    case "49918": card = "池城交通一卡通"
    case "50000": card = "海南一卡通"
    case "50021": card = "天涯行"
    case "50200": card = "银川交通一卡通"
    case "50601": card = "泉通卡"
    case "50202": card = "吴忠公交IC卡"
    case "50203": card = "六盘通"
    case "50600": card = "榕城通"
    case "50602": card = "平潭海峡通"
    case "50603": card = "福宁卡"
    case "50604": card = "龙行卡"
    case "50605": card = "莆田城市一卡通"
    case "50606": card = "九龙卡"
    case "50607": card = "明通卡"
    case "50609": card = "武夷通"
    case "50700": card = "鹰城通"
    case "50702": card = "绿城通"
    case "50703": card = "许昌万里一卡通"
    case "50705": card = "三门峡市公交IC卡"
    case "50706": card = "焦作公交一卡通"
    case "50707": card = "安阳公交一卡通"
    case "50708": card = "天中通"
    case "50709": card = "南阳交通一卡通"
    case "50710": card = "开封交通一卡通"
    case "50712": card = "新乡公交一卡通"
    case "50715": card = "洛阳交通一卡通"
    case "50716": card = "濮阳交通一卡通"
    case "50717": card = "茶城通"
    case "50718": card = "轩辕通-鹤壁"
    case "50719": card = "周口交通一卡通"
    case "50720": card = "许昌公交卡"
    case "51100": card = "鹿城通"
    case "51101": card = "呼和浩特交通一卡通"
    case "51200": card = "大连明珠卡"
    case "51201": card = "盛京通交通部版"
    case "51203": card = "鞍山交运通卡"
    case "51205": card = "鸭绿江通"
    case "51206": card = "锦州公交卡"
    case "51207": card = "营口通"
    case "51208": card = "阜新虎跃城市公交卡"
    case "51209": card = "辽阳公交卡"
    case "51210": card = "盘锦公交卡"
    case "51211": card = "铁岭全国交通一卡通"
    case "51212": card = "朝阳公交卡"
    case "51213": card = "葫芦岛公交IC卡"
    case "51300": card = "太原公交IC卡"
    case "51301": card = "大同公交一卡通"
    case "51302": card = "阳泉交通一卡通"
    case "51303": card = "长治城市一卡通普通卡"
    case "51304": card = "晋城市公交IC卡"
    case "51305": card = "朔州交通一卡通"
    case "51306": card = "三晋通-忻州通"
    case "51307": card = "吕梁交通一卡通"
    case "51308": card = "晋中交通一卡通"
    case "51309": card = "临汾公交一卡通"
    case "51310": card = "运城交通一卡通"
    case "51400": card = "武汉通"
    case "51401": card = "黄石公交一卡通"
    case "51402": card = "车城通交通部版"
    case "51403": card = "全国一卡通・湖北宜昌"
    case "51404": card = "随州一卡通"
    case "51405": card = "襄阳交通一卡通"
    case "51406": card = "鄂州交通IC卡"
    case "51408": card = "黄冈全国公交一卡通"
    case "51410": card = "咸宁一卡通"
    case "51413": card = "潜江一卡通"
    case "51608": card = "e通卡"
    case "55040": card = "漯河公交卡"
    case "58310": card = "连云港市民卡"
    case "58400": card = "邕桂通"
    case "58404": card = "北海通"
    case "58408": card = "钦州市民卡"
    case "034047410": card = "同心市民卡"
     */
    
    // MARK: 特別行政区
    case "48500": card = cnTunion_Info(name:"八达通",area:"香港特别行政区",city:nil, issuer: "八达通卡有限公司")
    case "49600": card = cnTunion_Info(name:"澳门通",area:"澳门特别行政区",city:nil, issuer: "澳门通股份有限公司")
        
    default: card = cnTunion_Info(name:"",area:nil,city:nil, issuer: "")
    }
    return card
}
