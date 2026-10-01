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
    
    switch iin.prefix(9) {
    //MARK: 北京 - 0310517
    case "031051700": card = cnTunion_Info(name:"北京一卡通",area:nil,city:"北京",issuer:"北京市政交通一卡通支付有限公司")
        
    //MARK: 上海 - 0310477
    case "031047700": card = cnTunion_Info(name:"上海公共交通卡",area:nil,city:"上海",issuer:"上海公共交通卡股份有限公司")
        
    //MARK: 天津 - 0310491
    case "031049102": card = cnTunion_Info(name:"天津城市卡",area:nil,city:"天津",issuer:"天津城市一卡通支付有限公司")
        
    // MARK: 江西省 - 0310473
    case "031047300": card = cnTunion_Info(name:"洪城一卡通",area:"江西省",city:"南昌市",issuer:"江西省洪城一卡通投资有限公司")
    case "031047301": card = cnTunion_Info(name:"赣州通",area:"江西省",city:"赣州市",issuer:"赣州城市一卡通有限公司")
    case "031047302": card = cnTunion_Info(name:"景德镇公交卡",area:"江西省",city:"景德镇市",issuer:"景德镇公共交通有限公司")
    case "031047303": card = cnTunion_Info(name:"萍乡交通一卡通",area:"江西省",city:"萍乡市",issuer:"萍乡市公共交通集团有限公司")
    case "031047304": card = cnTunion_Info(name:"九江交通一卡通",area:"江西省",city:"九江市",issuer:"九江市公共交通集团公司")
    case "031047305": card = cnTunion_Info(name:"新余公交一卡通",area:"江西省",city:"新余市",issuer:"江西长运新余公共交通有限公司")
    case "031047306": card = cnTunion_Info(name:"鹰潭互联互通卡",area:"江西省",city:"鹰潭市",issuer:"江西长运鹰潭公共交通有限公司")
    case "031047307": card = cnTunion_Info(name:"宜春公交明月通",area:"江西省",city:"宜春市",issuer:"宜春公交集团有限公司")
    case "031047308": card = cnTunion_Info(name:"上饶公交IC卡",area:"江西省",city:"上饶市",issuer:"上饶市公共交通集团有限公司")
    case "031047309": card = cnTunion_Info(name:"吉安通",area:"江西省",city:"吉安市",issuer:"江西长运吉安公共交通有限责任公司")
    case "031047310": card = cnTunion_Info(name:"抚州交通一卡通",area:"江西省",city:"抚州市",issuer:"抚州市公共交通有限责任公司")
        
    // MARK: 贵州省 - 0310474
    case "031047400": card = cnTunion_Info(name:"贵阳公交电子车票",area:"贵州省",city:"贵阳市",issuer:"贵阳市信捷科技有限公司")
    case "031047401": card = cnTunion_Info(name:"遵义交通一卡通",area:"贵州省",city:"遵义市",issuer:"遵义市公共交通(集团)有限责任公司")
    case "031047402": card = cnTunion_Info(name:"凉都市民卡",area:"贵州省",city:"六盘水市",issuer:"六盘水凉都市民卡有限公司")
    case "031047403": card = cnTunion_Info(name:"安顺公交一卡通",area:"贵州省",city:"安顺市",issuer:"安顺市公共交通总公司")
    case "031047404": card = cnTunion_Info(name:"九驿通",area:"贵州省",city:"毕节市大方县",issuer:"大方县城市翼卡支付有限公司")
    case "031047405": card = cnTunion_Info(name:"桃源卡",area:"贵州省",city:"铜仁市",issuer:"铜仁市公共交通有限责任公司")
    case "031047406": card = cnTunion_Info(name:"兴义卡",area:"贵州省",city:"黔西南布依族苗族自治州",issuer:"兴义市城市公交公司")
    case "031047407": card = cnTunion_Info(name:"凯里公交IC卡",area:"贵州省",city:"黔东南苗族侗族自治州",issuer:"贵州省凯里市公共交通总公司")
    case "031047408": card = cnTunion_Info(name:"贵州黔南全国交通一卡通",area:"贵州省",city:"黔南布依族苗族自治州",issuer:"都匀市公共交通总公司")
    case "031047409": card = cnTunion_Info(name:"一应黔行",area:"贵州省",city:"贵阳市",issuer:"贵阳市信捷科技有限公司")
    case "031047410": card = cnTunion_Info(name:"同心市民卡",area:"贵州省",city:"毕节市",issuer:nil)
        
    // MARK: 西藏自治区 - 0310475
    case "031047500": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"拉萨市",issuer:"西藏中信海博电子科技有限公司")
    case "031047501": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"昌都市",issuer:"西藏中信海博电子科技有限公司")
    case "031047502": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"山南市",issuer:"西藏中信海博电子科技有限公司")
    case "031047503": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"日喀则市",issuer:"西藏中信海博电子科技有限公司")
    case "031047504": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"那曲市",issuer:"西藏中信海博电子科技有限公司")
    case "031047505": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"阿里地区",issuer:"西藏中信海博电子科技有限公司")
    case "031047506": card = cnTunion_Info(name:"西藏交通一卡通",area:"西藏自治区",city:"林芝市",issuer:"西藏中信海博电子科技有限公司")
        
    // MARK: 青海省 - 0310476
    case "031047600": card = cnTunion_Info(name:"夏都通",area:"青海省",city:"西宁市",issuer:"西宁智能一卡通责任有限公司")
    case "031047601": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"海东市",issuer:"青海省高速公路运营管理有限公司")
    case "031047603": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"黄南藏族自治州",issuer:"青海省高速公路运营管理有限公司")
    case "031047604": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"黄南藏族自治州",issuer:"青海省高速公路运营管理有限公司")
    case "031047606": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"玉树藏族自治州",issuer:"青海省高速公路运营管理有限公司")
    case "031047607": card = cnTunion_Info(name:"大美青海行",area:"青海省",city:"海西蒙古族藏族自治州",issuer:"青海省高速公路运营管理有限公司")
       
    // MARK: 四川省 - 0310478
    case "031047800": card = cnTunion_Info(name:"天府通",area:"四川省",city:"成都市",issuer:"成都天府通金融服务股份有限公司")
    case "031047801": card = cnTunion_Info(name:"甜城通",area:"四川省",city:"内江市",issuer:"内江市公共交通集团有限责任公司")
    case "031047802": card = cnTunion_Info(name:"月城一卡通",area:"四川省",city:"内江市",issuer:"内江市公共交通集团有限责任公司")
    case "031047803": card = cnTunion_Info(name:"乐山交通卡",area:"四川省",city:"乐山市",issuer:"乐山市通联智能交通科技有限公司")
    case "031047804": card = cnTunion_Info(name:"自贡通",area:"四川省",city:"自贡市",issuer:"自贡盐都一卡通信息化有限责任公司")
    case "031047805": card = cnTunion_Info(name:"攀枝花公交卡",area:"四川省",city:"攀枝花市",issuer:"攀枝花公交客运总公司")
    case "031047806": card = cnTunion_Info(name:"酒城一卡通",area:"四川省",city:"泸州市",issuer:"泸州市公共交通集团有限公司")
    case "031047807": card = cnTunion_Info(name:"德阳全国交通一卡通",area:"四川省",city:"德阳市",issuer:"德阳裕兴公共交通有限公司")
    case "031047808": card = cnTunion_Info(name:"绵州通",area:"四川省",city:"绵阳市",issuer:"绵阳市绵州通有限责任公司")
    case "031047809": card = cnTunion_Info(name:"利州通",area:"四川省",city:"广元市",issuer:"广元市公共交通公司")
    case "031047810": card = cnTunion_Info(name:"遂州通",area:"四川省",city:"遂宁市",issuer:"遂宁遂州通有限公司")
    case "031047811": card = cnTunion_Info(name:"宜宾一卡通",area:"四川省",city:"宜宾市",issuer:"宜宾市和谐卡务有限公司")
    case "031047812": card = cnTunion_Info(name:"南充公交卡",area:"四川省",city:"南充市",issuer:"南充市公共交通有限责任公司")
    case "031047813": card = cnTunion_Info(name:"达州通",area:"四川省",city:"达州市",issuer:"达州市感知生活科技有限公司")
    case "031047814": card = cnTunion_Info(name:"雅安交通一卡通",area:"四川省",city:"雅安市",issuer:"雅安市公共交通有限公司")
    case "031047816": card = cnTunion_Info(name:"康定公交一卡通",area:"四川省",city:"甘孜藏族自治州",issuer:"康定公共交通运输有限责任公司")
    case "031047817": card = cnTunion_Info(name:"眉山交通一卡通",area:"四川省",city:"眉山市",issuer:"眉山市展通公交客运有限公司")
    case "031047818": card = cnTunion_Info(name:"广安全国一卡通",area:"四川省",city:"广安市",issuer:"广安市广泰公共交通有限责任公司")
    case "031047819": card = cnTunion_Info(name:"巴中交通一卡通",area:"四川省",city:"巴中市",issuer:"巴中市巴山公共交通有限公司")
    case "031047821": card = cnTunion_Info(name:"古城阆中通",area:"四川省",city:"南充市",issuer:"阆中滕王阁旅游公交有限公司")
        
    // MARK: 新疆维吾尔自治区 - 0310479
    case "031047900": card = cnTunion_Info(name:"红山一卡通",area:"新疆维吾尔自治区",city:"乌鲁木齐市",issuer:"乌鲁木齐红山一卡通有限责任公司")
    case "031047901": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"阿拉尔市",issuer:"捷行信息技术有限公司")
    case "031047902": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"铁门关市",issuer:"捷行信息技术有限公司")
    case "031047903": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"图木舒克市",issuer:"捷行信息技术有限公司")
    case "031047904": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"可克达拉市",issuer:nil) //割り振りのみ
    case "031047905": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"双河市",issuer:nil) //割り振りのみ
    case "031047906": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"五家渠市",issuer:"捷行信息技术有限公司")
    case "031047907": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"胡杨河市",issuer:nil) //割り振りのみ
    case "031047908": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"石河子市",issuer:"捷行信息技术有限公司")
    case "031047909": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"白杨市",issuer:nil) //割り振りのみ
    case "031047910": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"北屯市",issuer:"北屯新建旅客运输有限责任公司")
    case "031047911": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"乌鲁木齐市",issuer:"捷行信息技术有限公司")
    case "031047912": card = cnTunion_Info(name:"金垦卡",area:"新疆维吾尔自治区",city:"新星市",issuer:"哈密市红星客运服务有限公司")
    case "031047913": card = cnTunion_Info(name:"崑玉交通一卡通",area:"新疆维吾尔自治区",city:"昆玉市",issuer:"昆玉市安达运输有限公司")
    case "031047914": card = cnTunion_Info(name:"克拉玛依公交卡",area:"新疆维吾尔自治区",city:"克拉玛依市",issuer:"克拉玛依市汽车运输有限责任公司")
    case "031047915": card = cnTunion_Info(name:"吐鲁番公交卡",area:"新疆维吾尔自治区",city:"吐鲁番市",issuer:"吐鲁番鹏祥公共交通有限公司")
    case "031047916": card = cnTunion_Info(name:"哈密市公交卡",area:"新疆维吾尔自治区",city:"哈密市",issuer:"哈密市东畅公共交通有限责任公司")
    case "031047917": card = cnTunion_Info(name:"昌吉智慧城市一卡通",area:"新疆维吾尔自治区",city:"昌吉回族自治州 昌吉市",issuer:"昌吉公共交通(集团)有限责任公司")
    case "031047918": card = cnTunion_Info(name:"博乐互通卡",area:"新疆维吾尔自治区",city:"博尔塔拉蒙古自治州 博乐市",issuer:"博乐市阳光公共交通有限责任公司")
    case "031047919": card = cnTunion_Info(name:"库尔勒市公交卡",area:"新疆维吾尔自治区",city:"巴音郭楞蒙古自治州 库尔勒市",issuer:"库尔勒市公共交通有限责任公司")
    case "031047920": card = cnTunion_Info(name:"阿克苏互通卡",area:"新疆维吾尔自治区",city:"阿克苏地区 阿克苏市",issuer:"阿克苏姑墨交通投资有限责任公司")
    case "031047921": card = cnTunion_Info(name:"阿图什互通卡",area:"新疆维吾尔自治区",city:"克孜勒苏柯尔克孜自治州 阿图什市",issuer:"阿图什顺达公交有限责任公司")
    case "031047922": card = cnTunion_Info(name:"喀什智慧城市一卡通",area:"新疆维吾尔自治区",city:"喀什地区",issuer:"喀什市公共交通有限责任公司")
    case "031047923": card = cnTunion_Info(name:"",area:"新疆维吾尔自治区",city:"和田地区",issuer:nil) //割り当てのみ
    case "031047924": card = cnTunion_Info(name:"伊宁公交卡",area:"新疆维吾尔自治区",city:"伊犁哈萨克自治州 伊宁市",issuer:"伊宁市公共交通(集团)有限责任公司")
    case "031047926": card = cnTunion_Info(name:"阿勒泰智慧城市一卡通",area:"新疆维吾尔自治区",city:"阿勒泰地区",issuer:"阿勒泰市利众公共交通有限公司")
        
    // MARK: 陕西省 - 0310479
    case "031048000": card = cnTunion_Info(name:"长安通",area:"陕西省",city:"西安市",issuer:"西安长安通有限责任公司")
    case "031048001": card = cnTunion_Info(name:"咸阳城市公交一卡通",area:"陕西省",city:"咸阳市",issuer:"咸阳市公共交通集团公司")
    case "031048002": card = cnTunion_Info(name:"宝鸡公交卡",area:"陕西省",city:"宝鸡市",issuer:"宝鸡市公共交通有限责任公司")
    case "031048003": card = cnTunion_Info(name:"渭南通",area:"陕西省",city:"渭南市",issuer:"渭南市公共交通总公司")
    case "031048004": card = cnTunion_Info(name:"铜川交通一卡通",area:"陕西省",city:"铜川市",issuer:"铜川市公共交通有限责任公司")
    case "031048006": card = cnTunion_Info(name:"延安公交一卡通",area:"陕西省",city:"延安市",issuer:"延安市公共交通总公司")
    case "031048007": card = cnTunion_Info(name:"天汉通",area:"陕西省",city:"汉中市",issuer:"汉中天汉一卡通有限责任公司")
    case "031048008": card = cnTunion_Info(name:"安康公交卡",area:"陕西省",city:"安康市",issuer:"安康市公共交通一卡通有限公司")
    case "031048009": card = cnTunion_Info(name:"商洛公交一卡通",area:"陕西省",city:"商洛市",issuer:"商洛市公共汽车公司")
    case "031048011": card = cnTunion_Info(name:"榆林驼城通交通卡",area:"陕西省",city:"榆林市",issuer:"榆林城投数字城市建设管理有限责任公司")
    case "031048013": card = cnTunion_Info(name:"农科城卡",area:"陕西省",city:"杨凌农业高新技术产业示范区",issuer:"杨凌示范区科技信息中心")
    case "031048014": card = cnTunion_Info(name:"西咸一卡通",area:"陕西省",city:"西安市",issuer:"咸阳城市一卡通有限责任公司")
    
    // MARK: 湖南省 - 0310482
    case "031048200": card = cnTunion_Info(name:"长沙潇湘卡",area:"湖南省",city:"长沙市",issuer:"湖南潇湘支付有限公司")
    case "031048202": card = cnTunion_Info(name:"株洲公交IC卡",area:"湖南省",city:"株洲市",issuer:"株洲市公共交通集团有限责任公司")
    case "031048203": card = cnTunion_Info(name:"湘潭交通卡",area:"湖南省",city:"湘潭市",issuer:"湘潭综合交通科技服务有限公司")
    case "031048204": card = cnTunion_Info(name:"衡阳交通卡",area:"湖南省",city:"衡阳市",issuer:"衡阳市公共交通集团有限公司")
    case "031048205": card = cnTunion_Info(name:"宝庆一卡通",area:"湖南省",city:"邵阳市",issuer:"邵阳市交通运输信息中心")
    case "031048206": card = cnTunion_Info(name:"岳阳通",area:"湖南省",city:"岳阳市",issuer:"岳阳通源投资咨询有限公司")
    case "031048207": card = cnTunion_Info(name:"常德公交卡",area:"湖南省",city:"常德市",issuer:"常德市公共交通有限责任公司")
    case "031048208": card = cnTunion_Info(name:"张家界一卡通",area:"湖南省",city:"张家界市",issuer:"张家界一卡通科技有限公司")
    case "031048209": card = cnTunion_Info(name:"银城一卡通",area:"湖南省",city:"益阳市",issuer:"湖南省益阳市公交公司")
    case "031048210": card = cnTunion_Info(name:"娄底公交卡",area:"湖南省",city:"娄底市",issuer:"娄底市公共交通有限公司")
    case "031048211": card = cnTunion_Info(name:"福城通",area:"湖南省",city:"郴州市",issuer:"湖南郴州汽车运输集团有限责任公司")
    case "031048212": card = cnTunion_Info(name:"永州城市一卡通",area:"湖南省",city:"永州市",issuer:"永州市城市公共交通运输有限责任公司")
    case "031048213": card = cnTunion_Info(name:"怀化公交IC卡",area:"湖南省",city:"怀化市",issuer:"怀化公共交通集团有限责任公司")
    case "031048214": card = cnTunion_Info(name:"湘西州交通一卡通",area:"湖南省",city:"湘西土家族苗族自治州 吉首市",issuer:"吉首市公共汽车公司")
        
        
    // MARK: 江苏省 - 0310483
    // https://zh.wikipedia.org/zh-cn/江苏交通一卡通
    case "031048300": card = cnTunion_Info(name:"金陵通",area:"江苏省",city:"南京市",issuer:"南京市市民卡支付有限公司")
    case "031048301": card = cnTunion_Info(name:"扬州市民卡",area:"江苏省",city:"扬州市",issuer:"扬州数慧城建科技有限责任公司")
    case "031048302": card = cnTunion_Info(name:"镇江公交IC卡",area:"江苏省",city:"镇江市",issuer:"镇江市公共交通有限公司")
    case "031048303": card = cnTunion_Info(name:"苏州市民卡",area:"江苏省",city:"苏州市",issuer:"苏州城慧通数字科技有限公司")
    case "031048304": card = cnTunion_Info(name:"南通市民卡",area:"江苏省",city:"南通市",issuer:"南通市民卡有限公司")
    case "031048305": card = cnTunion_Info(name:"常州市民卡",area:"江苏省",city:"常州市",issuer:"常州市市民卡建设有限公司")
    case "031048306": card = cnTunion_Info(name:"宿迁市民卡",area:"江苏省",city:"宿迁市",issuer:"宿迁市市民卡有限公司")
    case "031048307": card = cnTunion_Info(name:"黄海通市民卡",area:"江苏省",city:"盐城市",issuer:"盐城市黄海通市民卡有限责任公司")
    case "031048308": card = cnTunion_Info(name:"江淮通",area:"江苏省",city:"淮安市",issuer:"淮安市数据集团有限公司")
    case "031048309": card = cnTunion_Info(name:"淮海通",area:"江苏省",city:"徐州市",issuer:"徐州市市民卡有限公司")
    case "031048310": card = cnTunion_Info(name:"连云港市民卡",area:"江苏省",city:"连云港市",issuer:"江苏云质数科技术有限公司")
    case "031048311": card = cnTunion_Info(name:"泰州通",area:"江苏省",city:"泰州市",issuer:"泰州市凤城一卡通有限公司")
    case "031048312": card = cnTunion_Info(name:"江苏交通一卡通",area:"江苏省",city:nil,issuer:nil)
    case "031048315": card = cnTunion_Info(name:"泰州通",area:"江苏省",city:"昆山市",issuer:"昆通卡")
        
    
    /*
    case "031048401": card = "柳州市民卡"
    case "031048402": card = "桂林通"
    case "031048403": card = "梧州通"
    case "031048406": card = "百色通"
    case "031048407": card = "河池通"
    case "031048408": card = "钦州市民卡"
    case "031048409": card = "防城港通"
    case "031048410": card = "贵港市民卡"
    case "031048411": card = "贺州通"
    case "031048412": card = "来宾通"
    case "031048413": card = "崇左通"
     
    case "031048701": card = "甜城通"
    case "031048702": card = "东莞通"
    case "031048703": card = "羊城通"
    case "031048704": card = "深圳通"
    case "031048705": card = "中山通"
    case "031048707": card = "广佛通"
    case "031048708": card = "惠州通"
    case "031048711": card = "茂城通"
    case "031048712": card = "肇庆通"
    case "031048714": card = "嘉应通"
    case "031048717": card = "清远市民卡"
    case "031048719": card = "榕江通"
    case "031048721": card = "潮州通"
    case "031048722": card = "岭云通"
    case "031048724": card = "珠海通"
     
    case "031048800": card = "温州城市公交IC卡"
    case "031048801": card = "杭州通"
    case "031048802": card = "甬城通交通部卡"
    case "031048803": card = "嘉兴交通一卡通"
    case "031048804": card = "台州通"
    case "031048805": card = "金华交通一卡通"
    case "031048806": card = "湖州交通一卡通"
    case "031048807": card = "绍兴一卡通"
     
    case "031048900": card = "长春轨道交通一卡通"
    case "031048901": card = "吉林通"
    case "031048902": card = "长春公交一卡通"
    case "031048903": card = "通化交通一卡通"
    case "031048904": card = "长春城联一卡通"
    case "031048905": card = "白山交通一卡通"
    case "031048906": card = "蛟河客运公交一卡通"
    case "031048908": card = "四平城市交通一卡通"
    case "031048910": card = "鹤城通"
    case "031048912": card = "松原通"
    case "031048914": card = "通化交通一卡通(农安)"
    case "031048916": card = "通化交通一卡通(九台)"
    case "031048917": card = "永吉万联惠民通卡"
    case "031048923": card = "双辽市交通一卡通"
    case "031048924": card = "公主岭万联惠民卡"
    case "031048929": card = "通化交通一卡通(柳河)"
    case "031048930": card = "梅河口交通一卡通"
    case "031048931": card = "通化交通一卡通(集安)"
    case "031048939": card = "延吉交通一卡通"
    case "031048942": card = "唰唰通"
    case "031048946": card = "延边交通一卡通"
    case "031048948": card = "通化交通一卡通(长岭)"
    case "031048951": card = "通化交通一卡通(双阳)"
    case "031049000": card = "兰州公交普通卡"
    case "031049003": card = "金昌通"
    case "031049006": card = "酒泉通"
    case "031049007": card = "山丹"
    case "031049008": card = "凉州通"
    case "031049011": card = "环县通"
    case "031049200": card = "宜居畅通卡"
    case "031049201": card = "交运通"
    case "031049300": card = "枣庄汽运交通一卡通"
    case "031049301": card = "沂蒙通"
    case "031049304": card = "琴岛通"
    case "031049307": card = "威海市民卡"
    case "031049308": card = "泉城通"
    case "031049310": card = "东营市交通一卡通"
    case "031049311": card = "潍坊通"
    case "031049312": card = "济宁公交卡"
    case "031049313": card = "滨州公交一卡通"
    case "031049314": card = "德州交通一卡通"
    case "031049315": card = "水城通"
    case "031049316": card = "菏泽交通一卡通"
    case "031049317": card = "日照交通一卡通"
    case "031049320": card = "枣庄同诚卡"
    case "031049500": card = "石家庄公交卡"
    case "031049501": card = "燕赵通"
    case "031049502": card = "保定卡"
    case "031049503": card = "河北一卡通卡(廊坊)"
    case "031049504": card = "河北一卡通(张家口)"
    case "031049505": card = "唐山公交IC卡"
    case "031049506": card = "秦皇岛公交卡"
    case "031049507": card = "河北一卡通卡(承德)"
    case "031049508": card = "河北一卡通卡(沧州)"
    case "031049509": card = "邢台卡"
    case "031049511": card = "河北一卡通卡(衡水)"
    case "031049512": card = "邯郸市民卡"
    case "031049517": card = "雄安交通一卡通"
    case "031049702": card = "哈尔滨城市卡"
    case "031049703": card = "齐联卡"
    case "031049707": card = "黑龙江一卡通"
    case "031049812": card = "好运通"
    case "031049813": card = "曲靖市公交乘车卡"
    case "031049816": card = "昆明智慧通"
    case "031049900": card = "蚌埠公交一卡通"
    case "031049902": card = "合肥通"
    case "031049903": card = "亳州交通一卡通"
    case "031049904": card = "宿州公共交通卡"
    case "031049905": card = "颍州通"
    case "031049906": card = "亭城通"
    case "031049907": card = "马鞍山市民卡"
    case "031049908": card = "芜湖城市卡"
    case "031049909": card = "铜陵一卡通"
    case "031049910": card = "安庆中北巴士交通一卡通"
    case "031049911": card = "六安公交一卡通"
    case "031049913": card = "淮北一卡通"
    case "031049914": card = "黄山交通一卡通"
    case "031049915": card = "淮南畅通卡"
    case "031049916": card = "宣城公交IC卡"
    case "031049918": card = "池城交通一卡通"
    case "031050000": card = "海南一卡通"
    case "031050021": card = "天涯行"
    case "031050200": card = "银川交通一卡通"
    case "031050601": card = "泉通卡"
    case "031050202": card = "吴忠公交IC卡"
    case "031050203": card = "六盘通"
    case "031050600": card = "榕城通"
    case "031050602": card = "平潭海峡通"
    case "031050603": card = "福宁卡"
    case "031050604": card = "龙行卡"
    case "031050605": card = "莆田城市一卡通"
    case "031050606": card = "九龙卡"
    case "031050607": card = "明通卡"
    case "031050609": card = "武夷通"
    case "031050700": card = "鹰城通"
    case "031050702": card = "绿城通"
    case "031050703": card = "许昌万里一卡通"
    case "031050705": card = "三门峡市公交IC卡"
    case "031050706": card = "焦作公交一卡通"
    case "031050707": card = "安阳公交一卡通"
    case "031050708": card = "天中通"
    case "031050709": card = "南阳交通一卡通"
    case "031050710": card = "开封交通一卡通"
    case "031050712": card = "新乡公交一卡通"
    case "031050715": card = "洛阳交通一卡通"
    case "031050716": card = "濮阳交通一卡通"
    case "031050717": card = "茶城通"
    case "031050718": card = "轩辕通-鹤壁"
    case "031050719": card = "周口交通一卡通"
    case "031050720": card = "许昌公交卡"
    case "031051100": card = "鹿城通"
    case "031051101": card = "呼和浩特交通一卡通"
    case "031051200": card = "大连明珠卡"
    case "031051201": card = "盛京通交通部版"
    case "031051203": card = "鞍山交运通卡"
    case "031051205": card = "鸭绿江通"
    case "031051206": card = "锦州公交卡"
    case "031051207": card = "营口通"
    case "031051208": card = "阜新虎跃城市公交卡"
    case "031051209": card = "辽阳公交卡"
    case "031051210": card = "盘锦公交卡"
    case "031051211": card = "铁岭全国交通一卡通"
    case "031051212": card = "朝阳公交卡"
    case "031051213": card = "葫芦岛公交IC卡"
    case "031051300": card = "太原公交IC卡"
    case "031051301": card = "大同公交一卡通"
    case "031051302": card = "阳泉交通一卡通"
    case "031051303": card = "长治城市一卡通普通卡"
    case "031051304": card = "晋城市公交IC卡"
    case "031051305": card = "朔州交通一卡通"
    case "031051306": card = "三晋通-忻州通"
    case "031051307": card = "吕梁交通一卡通"
    case "031051308": card = "晋中交通一卡通"
    case "031051309": card = "临汾公交一卡通"
    case "031051310": card = "运城交通一卡通"
    case "031051400": card = "武汉通"
    case "031051401": card = "黄石公交一卡通"
    case "031051402": card = "车城通交通部版"
    case "031051403": card = "全国一卡通・湖北宜昌"
    case "031051404": card = "随州一卡通"
    case "031051405": card = "襄阳交通一卡通"
    case "031051406": card = "鄂州交通IC卡"
    case "031051408": card = "黄冈全国公交一卡通"
    case "031051410": card = "咸宁一卡通"
    case "031051413": card = "潜江一卡通"
    case "031051608": card = "e通卡"
    case "031055040": card = "漯河公交卡"
    case "031058310": card = "连云港市民卡"
    case "031058400": card = "邕桂通"
    case "031058404": card = "北海通"
    case "031058408": card = "钦州市民卡"
    case "034047410": card = "同心市民卡"
     */
    
    // MARK: 特別行政区
    case "031048500": card = cnTunion_Info(name:"八达通",area:"香港特别行政区",city:nil, issuer: "八达通卡有限公司")
    case "031049600": card = cnTunion_Info(name:"澳门通",area:"澳门特别行政区",city:nil, issuer: "澳门通股份有限公司")
        
    default: card = cnTunion_Info(name:"",area:nil,city:nil, issuer: "")
    }
    return card
}
