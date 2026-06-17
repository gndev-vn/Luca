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
        PublicHoliday(
            name: "Tết Nguyên Đán",
            lunarMonth: 1,
            lunarDay: 1,
            isLeapMonth: false,
            duration: 3,
            description: LocalizedContent(en: "The most important Vietnamese holiday celebrating the lunar new year", native: "Ngày lễ quan trọng nhất của người Việt đánh dấu năm mới âm lịch"),
        ),
        PublicHoliday(
            name: "Tết Nguyên Tiêu",
            lunarMonth: 1,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Festival of lights marking the first full moon of the lunar year", native: "Lễ hội ánh sáng đánh dấu trăng tròn đầu tiên của năm âm lịch"),
        ),
        PublicHoliday(
            name: "Lễ Khai Ấn",
            lunarMonth: 1,
            lunarDay: 10,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Traditional ceremony marking the official start of work after Tết", native: "Nghi lễ truyền thống đánh dấu bắt đầu làm việc chính thức sau Tết"),
        ),
        PublicHoliday(
            name: "Tết Hàn Thực",
            lunarMonth: 3,
            lunarDay: 3,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Traditional festival honoring ancestors with cold food offerings", native: "Lễ hội truyền thống tưởng nhớ tổ tiên với đồ ăn lạnh"),
        ),
        PublicHoliday(
            name: "Giỗ Tổ Hùng Vương",
            lunarMonth: 3,
            lunarDay: 10,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "National holiday honoring the legendary Hung Kings, founders of Vietnam", native: "Ngày lễ quốc gia tưởng nhớ các vua Hùng, người sáng lập nước Việt"),
        ),
        PublicHoliday(
            name: "Lễ Phật Đản",
            lunarMonth: 4,
            lunarDay: 8,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Buddhist festival celebrating the birth, enlightenment, and death of Buddha", native: "Lễ Phật giáo kỷ niệm ngày Đức Phật sinh, thành đạo và nhập niết bàn"),
        ),
        PublicHoliday(
            name: "Tết Đoan Ngọ",
            lunarMonth: 5,
            lunarDay: 5,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Festival for health and protection against diseases and evil spirits", native: "Lễ hội về sức khỏe và phòng chống bệnh tật, tà ma"),
        ),
        PublicHoliday(
            name: "Lễ Vu Lan",
            lunarMonth: 7,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Buddhist festival honoring parents and ancestors, Vietnamese Mother's Day", native: "Lễ Phật giáo tưởng nhớ cha mẹ và tổ tiên, Ngày của Mẹ Việt Nam"),
        ),
        PublicHoliday(
            name: "Tết Trung Nguyên",
            lunarMonth: 7,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Festival for honoring deceased ancestors and wandering spirits", native: "Lễ hội tưởng nhớ tổ tiên quá cố và các linh hồn lang thang"),
        ),
        PublicHoliday(
            name: "Tết Trung Thu",
            lunarMonth: 8,
            lunarDay: 15,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Children's festival celebrating the full moon and harvest", native: "Tết thiếu nhi kỷ niệm trăng tròn và mùa thu hoạch"),
        ),
        PublicHoliday(
            name: "Tết Trùng Cửu",
            lunarMonth: 9,
            lunarDay: 9,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Traditional festival for longevity and honoring elders", native: "Lễ hội truyền thống về trường thọ và tôn kính người cao tuổi"),
        ),
        PublicHoliday(
            name: "Tết Ông Táo",
            lunarMonth: 12,
            lunarDay: 23,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Festival sending the Kitchen God to heaven to report on the family's behavior", native: "Lễ hội tiễn Ông Táo về trời báo cáo về gia đình"),
        ),
        PublicHoliday(
            name: "Tết Ông Bà",
            lunarMonth: 12,
            lunarDay: 30,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Year-end ceremony honoring all ancestors before the new year", native: "Lễ cuối năm tưởng nhớ tất cả tổ tiên trước năm mới"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 1,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Major full moon ceremony of the first lunar month", native: "Lễ cúng rằm lớn của tháng giêng âm lịch"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 2,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Monthly full moon ceremony for ancestor worship", native: "Lễ cúng rằm hàng tháng thờ cúng tổ tiên"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 3,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Monthly full moon ceremony for ancestor worship", native: "Lễ cúng rằm hàng tháng thờ cúng tổ tiên"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 4,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Monthly full moon ceremony for ancestor worship", native: "Lễ cúng rằm hàng tháng thờ cúng tổ tiên"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 5,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Monthly full moon ceremony for ancestor worship", native: "Lễ cúng rằm hàng tháng thờ cúng tổ tiên"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 6,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Monthly full moon ceremony for ancestor worship", native: "Lễ cúng rằm hàng tháng thờ cúng tổ tiên"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 7,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Major full moon ceremony of the seventh lunar month, coinciding with Vu Lan", native: "Lễ cúng rằm lớn tháng bảy âm lịch, trùng với lễ Vu Lan"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 8,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Monthly full moon ceremony coinciding with Mid-Autumn Festival", native: "Lễ cúng rằm hàng tháng trùng với Tết Trung Thu"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 9,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Monthly full moon ceremony for ancestor worship", native: "Lễ cúng rằm hàng tháng thờ cúng tổ tiên"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 10,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Major full moon ceremony of the tenth lunar month", native: "Lễ cúng rằm lớn tháng mười âm lịch"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 11,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Monthly full moon ceremony for ancestor worship", native: "Lễ cúng rằm hàng tháng thờ cúng tổ tiên"),
        ),
        PublicHoliday(
            name: "Cúng Rằm",
            lunarMonth: 12,
            lunarDay: 14,
            isLeapMonth: false,
            duration: 2,
            description: LocalizedContent(en: "Monthly full moon ceremony for ancestor worship", native: "Lễ cúng rằm hàng tháng thờ cúng tổ tiên"),
        ),
        PublicHoliday(
            name: "Lễ Cúng Ông Bà Ngoại",
            lunarMonth: 2,
            lunarDay: 19,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Special day for honoring maternal grandparents and ancestors", native: "Ngày đặc biệt tưởng nhớ ông bà ngoại và tổ tiên ngoại"),
        ),
        PublicHoliday(
            name: "Lễ Quan Âm",
            lunarMonth: 2,
            lunarDay: 19,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Buddhist festival honoring Quan Yin, Goddess of Mercy", native: "Lễ Phật giáo tôn vinh Quan Âm Bồ Tát"),
        ),
        PublicHoliday(
            name: "Lễ Quan Âm Thành Đạo",
            lunarMonth: 6,
            lunarDay: 19,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Buddhist festival celebrating Quan Yin's enlightenment", native: "Lễ Phật giáo kỷ niệm ngày Quan Âm thành đạo"),
        ),
        PublicHoliday(
            name: "Lễ Quan Âm Xuất Gia",
            lunarMonth: 9,
            lunarDay: 19,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Buddhist festival commemorating Quan Yin's ordination", native: "Lễ Phật giáo kỷ niệm ngày Quan Âm xuất gia"),
        ),
        PublicHoliday(
            name: "Tết Thiên Tiên",
            lunarMonth: 3,
            lunarDay: 23,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Traditional festival honoring celestial fairies and goddesses", native: "Lễ hội truyền thống tôn vinh các tiên nữ và nữ thần"),
        ),
        PublicHoliday(
            name: "Lễ Cúng Thần Tài",
            lunarMonth: 1,
            lunarDay: 5,
            isLeapMonth: false,
            duration: 1,
            description: LocalizedContent(en: "Festival honoring the God of Wealth for prosperity", native: "Lễ hội tôn vinh Thần Tài cầu tài lộc"),
        ),
    ]
}
