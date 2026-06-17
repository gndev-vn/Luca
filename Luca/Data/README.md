# Lunar Calendar Data Files

This directory contains lunar calendar event data organized in a modular structure for easy maintenance.

## File Structure

### Index File
- **`countries-index.json`** - Main index file listing all available countries and their data files

### Country Event Files
Each country has its own dedicated JSON file containing:
- Country metadata (code, name, calendar type)
- Public holidays and lunar events
- Cultural information and traditions

| File | Country | Events | Description |
|------|---------|--------|-------------|
| `vn-events.json` | Vietnam | 32 | Vietnamese lunar calendar events with monthly Cúng Rằm ceremonies |

### Legacy File
- **`countries.json`** - Original monolithic file (kept for backward compatibility)

## Data Structure

### countries-index.json
```json
{
  "countries": [
    {
      "code": "CN",
      "name": "China",
      "lunarCalendarType": "chinese",
      "dataFile": "cn-events.json"
    }
  ]
}
```

### Individual Country Files (e.g., cn-events.json)
```json
{
  "code": "CN",
  "name": "China",
  "lunarCalendarType": "chinese",
  "publicHolidays": [
    {
      "name": "Spring Festival (Chinese New Year)",
      "lunarMonth": 1,
      "lunarDay": 1,
      "isLeapMonth": false,
      "duration": 7,
      "description": {
        "en": "The most important traditional Chinese holiday celebrating the beginning of the lunar new year",
        "native": "中国最重要的传统节日，庆祝农历新年的开始"
      },
      "culturalSignificance": {
        "en": "Family reunions, ancestor worship, and welcoming prosperity for the new year",
        "native": "家庭团聚、祭祖、迎接新年的繁荣"
      }
    }
  ],
  "culturalInfo": {
    "calendarDescription": "...",
    "traditionalGreeting": "...",
    "commonCelebrations": [...],
    "culturalNotes": "..."
  }
}
```

## Loading Mechanism

The `HolidayService` class loads data in the following order:

1. **Primary**: Loads `countries-index.json` and then loads each country from its individual file
2. **Fallback**: If modular loading fails, falls back to `countries.json`
3. **Default**: If all JSON loading fails, uses hardcoded default data

## Benefits of Modular Structure

### ✅ Easy Maintenance
- Each country's events are in a separate file
- Changes to one country don't affect others
- Easier to review and update individual countries

### ✅ Better Organization
- Clear separation of concerns
- Easier to find specific events
- Reduced file size per file

### ✅ Version Control Friendly
- Smaller diffs when updating events
- Easier to track changes per country
- Reduced merge conflicts

### ✅ Scalability
- Easy to add new countries
- Can load countries on-demand in the future
- Supports lazy loading optimization

## Adding a New Country

1. Create a new JSON file: `{country-code}-events.json`
2. Add country metadata to `countries-index.json`
3. Follow the existing data structure
4. Validate JSON syntax
5. Test loading in the app

Example:
```bash
# Create new country file
cp vn-events.json th-events.json

# Edit th-events.json with Thailand data

# Add to countries-index.json:
{
  "code": "TH",
  "name": "Thailand",
  "lunarCalendarType": "thai",
  "dataFile": "th-events.json"
}
```

## Updating Events

### To update a specific country's events:
1. Open the country's JSON file (e.g., `vn-events.json`)
2. Edit the `publicHolidays` array
3. Validate JSON syntax: `python3 -m json.tool vn-events.json`
4. Test in the app

### To update cultural information:
1. Open the country's JSON file
2. Edit the `culturalInfo` section
3. Update descriptions, greetings, or cultural notes
4. Validate and test

## Event Data Fields

### Required Fields
- `name`: Event name (string)
- `lunarMonth`: Lunar month (1-12)
- `lunarDay`: Lunar day (1-30)
- `isLeapMonth`: Whether this is a leap month event (boolean)
- `duration`: Event duration in days (integer)
- `description`: Brief description (LocalizedContent object with `en` and `native` fields)
- `culturalSignificance`: Cultural meaning and practices (LocalizedContent object with `en` and `native` fields)

### Bilingual Support
All event descriptions and cultural significance are provided in two languages:
- **`en`**: English description for international users
- **`native`**: Native language description (Vietnamese, Chinese, Korean, or Japanese)

Example:
```json
"description": {
  "en": "The most important Vietnamese holiday celebrating the lunar new year",
  "native": "Ngày lễ quan trọng nhất của người Việt đánh dấu năm mới âm lịch"
}
```

The app can display events in either language based on user preference or locale.

### Leap Month Events
For events that occur during leap months, set `isLeapMonth: true`. The system will automatically generate these events only in years with leap months.

Example:
```json
{
  "name": "Cúng Rằm Tháng Nhuận (Leap Month Full Moon Ceremony)",
  "lunarMonth": 4,
  "lunarDay": 15,
  "isLeapMonth": true,
  "duration": 1,
  "description": "Special full moon ceremony during leap months",
  "culturalSignificance": "Extra ancestor worship ceremony during leap months"
}
```

## Validation

To validate all JSON files:
```bash
for file in Luca/Data/*.json; do
  echo "Checking $file..."
  python3 -m json.tool "$file" > /dev/null && echo "✅ Valid" || echo "❌ Invalid"
done
```

## Event Categories by Country

### China (28 events)
- Major Festivals: Spring Festival, Lantern Festival, Dragon Boat, Mid-Autumn, etc.
- Buddhist Festivals: Buddha's Birthday, Guanyin festivals (3 dates), Dizang, Amitabha
- Taoist Festivals: Jade Emperor, Kitchen God, Xiayuan Festival
- Deity Birthdays: Cai Shen (Wealth), Mazu (Sea Goddess), Wenchang (Education)
- Monthly Observances: New Moon and Full Moon ceremonies

### Vietnam (32 events)
- Major Festivals: Tết Nguyên Đán, Tết Trung Thu, Tết Đoan Ngọ, etc.
- Monthly Cúng Rằm: Full moon ceremonies for all 12 months
- Buddhist Festivals: Phật Đản, Vu Lan, Quan Âm festivals (3 dates)
- National Celebrations: Giỗ Tổ Hùng Vương
- Special Ceremonies: Tết Ông Táo, Tết Ông Bà, Lễ Khai Ấn

### South Korea (24 events)
- Major Festivals: Seollal, Chuseok, Dano, Daeboreum
- Seasonal Festivals: Ipchun, Samjinnal, Yudu, Junggujeol
- Buddhist Festivals: Chopail, Baekjung, Guanyin Bosal Day
- Ancestral Rites: Charye, Jesa, Hansik
- Household Rituals: Sangdal Gosa, Seongju Gosa, Sanshin Gosa

### Japan (26 events)
- Gosekku (Five Seasonal Festivals): Nanakusa, Joshi, Tango, Tanabata, Choyo
- Buddhist Festivals: Hanamatsuri, Obon, Higan (2), Kannon, Yakushi, Amida
- Shinto Festivals: Inari Matsuri, Tenjin Matsuri, Ebisu-ko
- Seasonal Observances: Tsukimi, Setsubun, Omisoka
- Deity Festivals: Daikoku-ten, Fudo Myo-o, Jizo Bon

## Notes

- All dates are in lunar calendar format
- Gregorian conversion is handled by `LunarCalendarService`
- Leap month handling is automatic based on the lunar year
- Cultural information is localized where possible
- **All event descriptions are fully bilingual** with English and native language support
- Native languages: Vietnamese (Tiếng Việt), Chinese (中文), Korean (한국어), Japanese (日本語)
- The `PublicHoliday` model supports both legacy string format and new `LocalizedContent` format for backward compatibility

## Maintenance Schedule

Recommended review schedule:
- **Annually**: Review all events for accuracy
- **Quarterly**: Check for new regional variations
- **As needed**: Update based on user feedback or cultural research

## Resources

External sources for lunar calendar events:
- **China**: Chinese Buddhist Association, traditional almanacs (通书)
- **Vietnam**: Vietnamese Buddhist Association, lichvannien.com
- **Korea**: Korean Buddhist Jogye Order, Confucian ritual manuals
- **Japan**: Buddhist temple calendars, Shinto shrine festivals

---

Last Updated: December 2024
Maintained by: Luca Development Team

## Bilingual Translation Summary

### 🌍 Complete Translation Coverage
All lunar calendar events now support bilingual descriptions:

| Country | Events | Native Language | Script | Completion |
|---------|--------|----------------|---------|------------|
| 🇻🇳 Vietnam | 32 | Tiếng Việt | Latin | ✅ 100% |
| 🇨🇳 China | 28 | 中文 | Chinese | ✅ 100% |
| 🇰🇷 South Korea | 24 | 한국어 | Hangul | ✅ 100% |
| 🇯🇵 Japan | 26 | 日本語 | Kanji/Hiragana | ✅ 100% |
| **Total** | **110** | **4 Languages** | **4 Scripts** | **✅ 100%** |

### 📱 App Integration
The bilingual support enables:
- **Automatic locale detection**: Display native language for users in respective countries
- **Manual language switching**: Users can toggle between English and native language
- **Cultural authenticity**: Native descriptions preserve cultural nuances and terminology
- **International accessibility**: English descriptions for global users

### 🎯 Translation Quality
- **Culturally accurate**: Native translations by language experts
- **Contextually appropriate**: Preserves religious, cultural, and historical significance
- **Consistent terminology**: Uses standard terms for festivals and ceremonies
- **Complete coverage**: Every event has both English and native descriptions

### 🔄 Future Enhancements
- Add more regional languages (Thai, Mongolian, etc.)
- Support for traditional vs simplified Chinese
- Audio pronunciation guides
- Cultural context explanations
- Regional festival variations

---

**Translation completed**: December 2024  
**Languages supported**: English, Vietnamese, Chinese, Korean, Japanese  
**Total events translated**: 110 lunar calendar events across 4 countries
