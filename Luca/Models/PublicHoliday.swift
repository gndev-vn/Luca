import Foundation

struct LocalizedContent: Codable {
    let en: String
    let native: String?

    func text(preferNative: Bool = false) -> String {
        if preferNative, let native = native {
            return native
        }
        return en
    }
}

struct PublicHoliday: Codable, Identifiable {
    let id: UUID
    let name: String
    let lunarMonth: Int
    let lunarDay: Int
    let isLeapMonth: Bool
    let duration: Int

    private let descriptionValue: LocalizedContent

    var description: String {
        descriptionValue.native ?? descriptionValue.en
    }

    var localizedDescription: LocalizedContent {
        descriptionValue
    }

    enum CodingKeys: String, CodingKey {
        case id, name, lunarMonth, lunarDay, isLeapMonth, duration
        case descriptionValue = "description"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.lunarMonth = try container.decode(Int.self, forKey: .lunarMonth)
        self.lunarDay = try container.decode(Int.self, forKey: .lunarDay)
        self.isLeapMonth = try container.decode(Bool.self, forKey: .isLeapMonth)
        self.duration = try container.decode(Int.self, forKey: .duration)
        self.descriptionValue = try container.decode(LocalizedContent.self, forKey: .descriptionValue)
    }

    init(name: String, lunarMonth: Int, lunarDay: Int, isLeapMonth: Bool, duration: Int, description: String) {
        self.id = UUID()
        self.name = name
        self.lunarMonth = lunarMonth
        self.lunarDay = lunarDay
        self.isLeapMonth = isLeapMonth
        self.duration = duration
        self.descriptionValue = LocalizedContent(en: description, native: nil)
    }

    init(name: String, lunarMonth: Int, lunarDay: Int, isLeapMonth: Bool, duration: Int, description: LocalizedContent) {
        self.id = UUID()
        self.name = name
        self.lunarMonth = lunarMonth
        self.lunarDay = lunarDay
        self.isLeapMonth = isLeapMonth
        self.duration = duration
        self.descriptionValue = description
    }
}

enum VietnameseCalendar {
    static let code = "VN"
    static let name = "Vietnam"
    static let displayName = "Vietnamese Lunar Calendar"

    static let publicHolidayTemplates: [PublicHoliday] = [
        // ====== Tháng Giêng (Lunar Month 1) ======
        PublicHoliday(
            name: "Tết Nguyên Đán",
            lunarMonth: 1,
            lunarDay: 1,
            isLeapMonth: false,
            duration: 3,
            description: LocalizedContent(
                en: "The most important Vietnamese holiday — Lunar New Year. Families reunite, honour ancestors, exchange wishes, and celebrate the arrival of spring with special foods like bánh chưng and bánh tét.",
                native: "Ngày Tết cổ truyền quan trọng nhất của người Việt. Đây là dịp đoàn viên gia đình, thờ cúng tổ tiên, mừng tuổi, và đón mùa xuân mới với bánh chưng, bánh tét cùng các phong tục truyền thống."
            ),
        ),
        PublicHoliday(
            name: "Lễ Cúng Thần Tài",
            lunarMonth: 1,
            lunarDay: 5,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Auspicious day to worship the God of Wealth, especially observed by businesses and shopkeepers to pray for prosperity and good fortune in the new year.",
                native: "Ngày cúng Thần Tài cầu tài lộc đầu năm, được các gia đình và người buôn bán đặc biệt coi trọng với lễ vật cúng Thần Tài - Thổ Địa."
            ),
        ),
        PublicHoliday(
            name: "Lễ Khai Hạ",
            lunarMonth: 1,
            lunarDay: 7,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Ceremony marking the end of the Tết season. The New Year's Pole (cây nêu) is taken down, officially concluding the Lunar New Year celebrations and returning to normal life.",
                native: "Lễ hạ cây nêu kết thúc dịp Tết. Theo phong tục, đây là ngày kết thúc kỳ nghỉ Tết Nguyên Đán, mọi người trở lại cuộc sống thường ngày và công việc."
            ),
        ),
        PublicHoliday(
            name: "Lễ Vía Ngọc Hoàng",
            lunarMonth: 1,
            lunarDay: 9,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Birthday of the Jade Emperor (Ngọc Hoàng Thượng Đế), the supreme deity in Vietnamese folk religion. Buddhists and Taoists pray for peace, health, and blessings at temples and pagodas.",
                native: "Ngày vía Ngọc Hoàng Thượng Đế, vị thần tối cao trong tín ngưỡng dân gian. Các chùa và đền tổ chức cúng lễ cầu quốc thái dân an, gia đình bình an."
            ),
        ),
        PublicHoliday(
            name: "Lễ Khai Ấn",
            lunarMonth: 1,
            lunarDay: 10,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Traditional seal-opening ceremony marking the official resumption of work and administrative affairs after the Tết holiday. The most famous ceremony is at Trần Temple in Nam Định.",
                native: "Lễ khai ấn đầu năm đánh dấu việc bắt đầu công việc chính thức sau Tết. Nghi lễ khai ấn nổi tiếng nhất diễn ra tại đền Trần (Nam Định) vào đêm 14 tháng Giêng."
            ),
        ),
        PublicHoliday(
            name: "Lễ Vía Thần Tài",
            lunarMonth: 1,
            lunarDay: 10,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Main worship day of the God of Wealth and the Earth God. Businesses prepare elaborate offerings — roasted pork, seafood, fruit, and gold paper — to attract prosperity for the year.",
                native: "Ngày vía Thần Tài chính trong năm, đặc biệt quan trọng với dân kinh doanh. Mọi người sắm lễ vật gồm thịt quay, tôm, cua, hoa quả và vàng mã để cầu tài lộc cả năm."
            ),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 1,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "First full moon ceremony of the lunar year — one of the most important of the year. Families pray for a year of peace, good health, and success at the start of spring.",
                native: "Lễ cúng rằm đầu năm, một trong những ngày rằm quan trọng nhất trong năm. Các gia đình làm lễ cúng tổ tiên và Phật Thánh cầu cho một năm mới bình an, may mắn."
            ),
        ),
        PublicHoliday(
            name: "Tết Nguyên Tiêu",
            lunarMonth: 1,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Lantern Festival marking the first full moon of the year, also called Tết Thượng Nguyên. Families visit pagodas, light lanterns, and pray for a prosperous year ahead.",
                native: "Tết Thượng Nguyên - Rằm tháng Giêng, lễ hội hoa đăng đầu năm. Ngày rằm lớn nhất trong năm, người dân đi chùa dâng hương cầu bình an, và thả đèn hoa đăng."
            ),
        ),

        // ====== Tháng Hai (Lunar Month 2) ======
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 2,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Monthly full moon ceremony for ancestor worship and prayer for family well-being.",
                native: "Lễ cúng rằm tháng Hai, cúng tổ tiên và cầu bình an cho gia đình giữa mùa xuân."
            ),
        ),
        PublicHoliday(
            name: "Ngày Phật Nhập Niết Bàn",
            lunarMonth: 2,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Buddhist observance commemorating the passing of Gautama Buddha into Nirvana. Pagodas hold ceremonies, sutra chanting, and offerings to honour the Buddha's final teaching.",
                native: "Ngày kỷ niệm Đức Phật Thích Ca Mâu Ni nhập Niết Bàn. Chùa chiền tổ chức lễ niệm Phật, tụng kinh, và dâng hương tưởng nhớ những lời dạy cuối cùng của Ngài."
            ),
        ),
        PublicHoliday(
            name: "Lễ Quan Âm",
            lunarMonth: 2,
            lunarDay: 19,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Buddhist festival honouring Avalokiteśvara (Quan Thế Âm Bồ Tát) — her birthday. Devotees visit pagodas, offer incense, and pray for compassion, protection, and peace.",
                native: "Ngày vía Quan Thế Âm Bồ Tát - lễ kỷ niệm ngày sinh của Ngài. Phật tử đi chùa dâng hương, cầu nguyện từ bi, cứu khổ cứu nạn và bình an."
            ),
        ),
        PublicHoliday(
            name: "Lễ Cúng Ông Bà Ngoại",
            lunarMonth: 2,
            lunarDay: 19,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Special day for honouring maternal grandparents and maternal ancestors. Families prepare offerings to express gratitude to the maternal lineage.",
                native: "Ngày tưởng nhớ ông bà ngoại và tổ tiên bên ngoại. Con cháu chuẩn bị mâm cúng để bày tỏ lòng biết ơn đối với dòng họ bên ngoại."
            ),
        ),

        // ====== Tháng Ba (Lunar Month 3) ======
        PublicHoliday(
            name: "Tết Hàn Thực",
            lunarMonth: 3,
            lunarDay: 3,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Cold Food Festival — families make bánh trôi and bánh chay (glutinous rice balls) as offerings to ancestors. The name recalls the ancient Chinese legend of Jie Zitui.",
                native: "Tết Hàn Thực - ngày làm bánh trôi, bánh chay dâng cúng tổ tiên. Phong tục này bắt nguồn từ truyền thuyết Trung Quốc về Giới Tử Thôi, nhưng đã Việt hóa mang ý nghĩa tưởng nhớ cội nguồn."
            ),
        ),
        PublicHoliday(
            name: "Giỗ Tổ Hùng Vương",
            lunarMonth: 3,
            lunarDay: 10,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "National holiday commemorating the Hùng Kings, the legendary founders of Vietnam. Grand ceremonies are held at the Hùng Temple in Phú Thọ, attracting millions of pilgrims.",
                native: "Ngày Quốc lễ tưởng nhớ các Vua Hùng, những người có công dựng nước. Lễ hội Đền Hùng ở Phú Thọ thu hút hàng triệu người dân cả nước về dâng hương."
            ),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 3,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Full moon ceremony of the third lunar month, falling in late spring when families prepare offerings for ancestors.",
                native: "Lễ cúng rằm tháng Ba giữa tiết xuân, các gia đình sửa soạn mâm cúng tổ tiên và cầu mong mùa màng tốt tươi."
            ),
        ),

        // ====== Tháng Ba - Tết Thiên Tiên (special) ======
        PublicHoliday(
            name: "Tết Thiên Tiên",
            lunarMonth: 3,
            lunarDay: 23,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Festival honouring celestial fairies and goddesses in Vietnamese folk belief. Associated with the worship of the Holy Mother (Đạo Mẫu) and female deities.",
                native: "Tết Thiên Tiên - ngày tôn vinh các tiên nữ và nữ thần trong tín ngưỡng dân gian, gắn liền với tín ngưỡng thờ Mẫu và các vị Thánh Mẫu."
            ),
        ),

        // ====== Tháng Tư (Lunar Month 4) ======
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 4,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Full moon ceremony before the Buddha's birthday season. Pagodas begin decorating and preparing for the upcoming Phật Đản celebrations.",
                native: "Lễ cúng rằm tháng Tư, thời điểm các chùa chuẩn bị trang hoàng cho mùa Phật Đản sắp tới. Các gia đình cúng tổ tiên và đi chùa dâng hương."
            ),
        ),
        PublicHoliday(
            name: "Lễ Phật Đản",
            lunarMonth: 4,
            lunarDay: 8,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Buddha's Birthday — the most important Buddhist festival. The Vietnam Buddhist Sangha observes from 1/4 to 15/4 lunar. Ceremonies include bathing the baby Buddha, lantern processions, and vegetarian meals.",
                native: "Đại lễ Phật Đản kỷ niệm ngày Đức Phật Thích Ca Mâu Ni đản sinh. Theo Giáo hội Phật giáo Việt Nam, lễ chính vào ngày 15/4, với nghi thức tắm Phật, diễu hành xe hoa, và phát tâm ăn chay."
            ),
        ),

        // ====== Tháng Năm (Lunar Month 5) ======
        PublicHoliday(
            name: "Tết Đoan Ngọ",
            lunarMonth: 5,
            lunarDay: 5,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Mid-year festival (also called 'Insect-Killing Festival'). People eat fermented sticky rice (rượu nếp) and sour fruits at noon to cleanse their bodies from parasites and diseases during summer heat.",
                native: "Tết Đoan Ngọ (Tết giết sâu bọ) - ngày lễ truyền thống giữa năm. Người dân ăn rượu nếp, hoa quả chua vào buổi trưa để diệt sâu bọ, phòng bệnh mùa hè."
            ),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 5,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Full moon ceremony of the fifth lunar month, closely following Tết Đoan Ngọ. Families offer fruits and traditional dishes to ancestors.",
                native: "Lễ cúng rằm tháng Năm diễn ra sát ngày Tết Đoan Ngọ. Các gia đình dâng hoa quả và đồ cúng tổ tiên trong tiết hè."
            ),
        ),

        // ====== Tháng Sáu (Lunar Month 6) ======
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 6,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Mid-summer full moon ceremony. This quiet ceremony allows families to reconnect with ancestors during this season.",
                native: "Lễ cúng rằm tháng Sáu giữa mùa hè, một ngày rằm yên tĩnh để gia đình tưởng nhớ tổ tiên."
            ),
        ),
        PublicHoliday(
            name: "Lễ Quan Âm Thành Đạo",
            lunarMonth: 6,
            lunarDay: 19,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Buddhist festival commemorating the enlightenment of Avalokiteśvara Bodhisattva. Devotees pray for wisdom, compassion, and liberation from suffering.",
                native: "Ngày kỷ niệm Quan Thế Âm Bồ Tát thành đạo. Phật tử đến chùa dâng hương cầu xin trí tuệ, từ bi và giải thoát khỏi khổ đau."
            ),
        ),

        // ====== Tháng Bảy (Lunar Month 7) ======
        PublicHoliday(
            name: "Lễ Thất Tịch",
            lunarMonth: 7,
            lunarDay: 7,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Double Seven Festival — the traditional 'Vietnamese Valentine' based on the legend of Ngưu Lang and Chức Nữ (Đông Phương Tình Nhân). It is also a day for praying for blessings.",
                native: "Ngày Thất Tịch - lễ tình nhân Đông phương dựa trên truyền thuyết Ngưu Lang - Chức Nữ gặp nhau trên cầu Ô Thước. Đây cũng là ngày cầu duyên và may mắn."
            ),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 7,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Major full moon ceremony of the seventh month — the Ghost Month. Families prepare elaborate offerings for deceased ancestors and wandering spirits, coinciding with Vu Lan season.",
                native: "Lễ cúng rằm tháng Bảy - ngày rằm lớn trong mùa Vu Lan. Các gia đình cúng tổ tiên và cô hồn với mâm cỗ đầy đủ, đây là ngày xá tội vong nhân."
            ),
        ),
        PublicHoliday(
            name: "Lễ Vu Lan",
            lunarMonth: 7,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Ullambana Festival — Vietnamese Mother's Day and a Buddhist festival of filial piety. People wear a rose (red if mother is alive, white if deceased) and pray for parents at pagodas.",
                native: "Lễ Vu Lan - Ngày của Mẹ Việt Nam theo Phật giáo. Người dân cài hoa hồng (đỏ nếu còn mẹ, trắng nếu mẹ đã mất) lên ngực áo, đến chùa cầu siêu cho cha mẹ."
            ),
        ),
        PublicHoliday(
            name: "Tết Trung Nguyên",
            lunarMonth: 7,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Wandering Souls Day (Xá Tội Vong Nhân) — believed to be when the gates of hell open, releasing spirits to visit the living. Families offer food, paper clothes, and money to hungry ghosts.",
                native: "Tết Trung Nguyên - ngày xá tội vong nhân, cửa địa ngục mở cho các linh hồn trở về dương thế. Các gia đình cúng cháo, quần áo giấy và vàng mã cho cô hồn."
            ),
        ),

        // ====== Tháng Tám (Lunar Month 8) ======
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 8,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Full moon ceremony preceding the Mid-Autumn Festival. Families prepare offerings both for ancestors and for the upcoming Tết Trung Thu celebrations.",
                native: "Lễ cúng rằm tháng Tám, sát với Tết Trung Thu. Các gia đình làm mâm cúng tổ tiên và chuẩn bị đón Tết thiếu nhi với bánh trung thu và lồng đèn."
            ),
        ),
        PublicHoliday(
            name: "Tết Trung Thu",
            lunarMonth: 8,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Mid-Autumn Festival — Vietnam's second most important festival, especially loved by children. Streets come alive with lantern parades, lion dances, mooncakes, and star-shaped lanterns.",
                native: "Tết Trung Thu - Tết thiếu nhi, lễ hội quan trọng thứ hai sau Tết Nguyên Đán. Trẻ em rước đèn ông sao, xem múa lân, phá cỗ trông trăng và thưởng thức bánh nướng, bánh dẻo."
            ),
        ),

        // ====== Tháng Chín (Lunar Month 9) ======
        PublicHoliday(
            name: "Tết Trùng Cửu",
            lunarMonth: 9,
            lunarDay: 9,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Double Nine Festival — a day for appreciating longevity and honouring elders. Traditionally people climb hills, drink chrysanthemum wine, and pray for good health.",
                native: "Tết Trùng Cửu - ngày lễ trường thọ, tôn kính người cao tuổi. Phong tục truyền thống gồm leo núi, uống rượu hoa cúc và cầu sức khỏe dồi dào."
            ),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 9,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Late autumn full moon ceremony. Families offer incense and food to ancestors in preparation for the approaching year-end ceremonies.",
                native: "Lễ cúng rằm tháng Chín cuối mùa thu, các gia đình thắp hương cúng tổ tiên chuẩn bị cho các lễ cuối năm."
            ),
        ),
        PublicHoliday(
            name: "Lễ Quan Âm Xuất Gia",
            lunarMonth: 9,
            lunarDay: 19,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Buddhist festival marking the day Avalokiteśvara Bodhisattva renounced worldly life to seek enlightenment. Observed at pagodas with incense offerings and prayers.",
                native: "Ngày kỷ niệm Quan Thế Âm Bồ Tát xuất gia, từ bỏ cuộc sống thế tục để tu hành tìm giác ngộ. Phật tử đến chùa dâng hương tưởng nhớ."
            ),
        ),

        // ====== Tháng Mười (Lunar Month 10) ======
        PublicHoliday(
            name: "Tết Trùng Thập",
            lunarMonth: 10,
            lunarDay: 10,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Double Ten Festival (Tết Cơm Mới / Tết Song Thập) — a traditional celebration of the autumn harvest. Families offer newly harvested rice to ancestors, giving thanks for a bountiful crop.",
                native: "Tết Trùng Thập (Tết Song Thập, Tết Cơm Mới) - lễ hội mừng mùa màng bội thu. Các gia đình dâng cơm mới lên tổ tiên để tạ ơn một vụ mùa tốt tươi."
            ),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 10,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Major full moon ceremony of the tenth month, coinciding with Tết Hạ Nguyên. This is considered the third important Nguyên festival of the year.",
                native: "Lễ cúng rằm tháng Mười - một trong những ngày rằm lớn trong năm, trùng với Tết Hạ Nguyên. Các gia đình làm lễ tạ ơn trời đất và tổ tiên."
            ),
        ),
        PublicHoliday(
            name: "Tết Hạ Nguyên",
            lunarMonth: 10,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "The third of the Three Nguyên Festivals (Thượng Nguyên, Trung Nguyên, Hạ Nguyên). Families give thanks for the year's blessings and pray for a peaceful conclusion to the lunar year.",
                native: "Tết Hạ Nguyên - lễ rằm tháng Mười, là một trong ba ngày lễ Tam Nguyên (Thượng Nguyên tháng Giêng, Trung Nguyên tháng Bảy, Hạ Nguyên tháng Mười). Ngày tạ ơn và cầu bình an cuối năm."
            ),
        ),

        // ====== Tháng Mười Một (Lunar Month 11) ======
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 11,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Late autumn full moon ceremony as the year draws to a close. Families honour ancestors and prepare spiritually for the year-end festivities.",
                native: "Lễ cúng rằm tháng Mười Một, thời điểm cuối năm, các gia đình tưởng nhớ tổ tiên và chuẩn bị tinh thần cho các lễ cuối năm."
            ),
        ),

        // ====== Tháng Chạp (Lunar Month 12) ======
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 12,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(
                en: "Last full moon ceremony of the lunar year. Families clean ancestral altars, prepare offerings, and pray for a smooth transition into the new year.",
                native: "Lễ cúng rằm tháng Chạp - ngày rằm cuối cùng của năm âm lịch. Các gia đình dọn dẹp bàn thờ tổ tiên, chuẩn bị đón Tết Nguyên Đán."
            ),
        ),
        PublicHoliday(
            name: "Ngày Phật Thành Đạo",
            lunarMonth: 12,
            lunarDay: 8,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Buddhist observance commemorating the enlightenment of Gautama Buddha under the Bodhi tree. At pagodas, devotees chant sutras, meditate, and offer incense in remembrance of this sacred event.",
                native: "Ngày kỷ niệm Đức Phật Thích Ca Mâu Ni thành đạo dưới cội Bồ Đề. Phật tử đến chùa tụng kinh, thiền định và dâng hương trong tinh thần hướng Phật."
            ),
        ),
        PublicHoliday(
            name: "Tết Ông Táo",
            lunarMonth: 12,
            lunarDay: 23,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Kitchen God Festival — families release live carp into rivers to send the Kitchen Gods (Ông Táo) to heaven to report on the household's conduct to the Jade Emperor in preparation for Tết.",
                native: "Tết Ông Công Ông Táo - ngày tiễn các vị Táo Quân về trời báo cáo với Ngọc Hoàng. Các gia đình thả cá chép sống ra sông hồ để Táo Quân có phương tiện về trời."
            ),
        ),
        PublicHoliday(
            name: "Tết Ông Bà",
            lunarMonth: 12,
            lunarDay: 30,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(
                en: "Year-end ceremony honouring all ancestors (Ông Bà) before the new year begins. Families prepare a grand feast, inviting ancestors to join the Tết celebrations with their descendants.",
                native: "Lễ Tất Niên - lễ cúng tổ tiên cuối năm, bày mâm cỗ Tất Niên thịnh soạn để mời ông bà tổ tiên về ăn Tết cùng con cháu."
            ),
        ),
    ]
}
