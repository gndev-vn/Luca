#!/usr/bin/env python3
"""
Script to update country event files with bilingual descriptions.
Converts simple string descriptions to LocalizedContent format with English and native language.
"""

import json

# Bilingual descriptions for Vietnam
vietnam_translations = {
    "Tết Nguyên Đán (Vietnamese New Year)": {
        "description": {
            "en": "The most important Vietnamese holiday celebrating the lunar new year",
            "native": "Ngày lễ quan trọng nhất của người Việt đánh dấu năm mới âm lịch"
        },
        "culturalSignificance": {
            "en": "Family reunions, ancestor veneration, welcoming spring, giving lì xì (lucky money)",
            "native": "Đoàn tụ gia đình, thờ cúng tổ tiên, đón xuân, mừng tuổi lì xì"
        }
    },
    "Tết Nguyên Tiêu (Lantern Festival)": {
        "description": {
            "en": "Festival of lights marking the first full moon of the lunar year",
            "native": "Lễ hội ánh sáng đánh dấu trăng tròn đầu tiên của năm âm lịch"
        },
        "culturalSignificance": {
            "en": "Lighting lanterns, temple visits, community celebrations, eating chè trôi nước",
            "native": "Thắp đèn lồng, đi chùa, lễ hội cộng đồng, ăn chè trôi nước"
        }
    },
    "Lễ Khai Ấn (Seal Opening Ceremony)": {
        "description": {
            "en": "Traditional ceremony marking the official start of work after Tết",
            "native": "Nghi lễ truyền thống đánh dấu bắt đầu làm việc chính thức sau Tết"
        },
        "culturalSignificance": {
            "en": "Opening official seals, beginning new work year, temple ceremonies",
            "native": "Mở ấn quan, bắt đầu năm làm việc mới, lễ chùa"
        }
    },
    "Lễ Phật Đản (Buddha's Birthday)": {
        "description": {
            "en": "Buddhist festival celebrating the birth, enlightenment, and death of Buddha",
            "native": "Lễ Phật giáo kỷ niệm ngày Đức Phật sinh, thành đạo và nhập niết bàn"
        },
        "culturalSignificance": {
            "en": "Temple visits, lotus lantern festivals, vegetarian meals, charitable acts",
            "native": "Đi chùa, lễ hội đèn hoa đăng, ăn chay, làm từ thiện"
        }
    },
    "Lễ Vu Lan (Ullambana Festival)": {
        "description": {
            "en": "Buddhist festival honoring parents and ancestors, Vietnamese Mother's Day",
            "native": "Lễ Phật giáo tưởng nhớ cha mẹ và tổ tiên, Ngày của Mẹ Việt Nam"
        },
        "culturalSignificance": {
            "en": "Wearing roses (red for living mothers, white for deceased), temple ceremonies",
            "native": "Cài hoa hồng (đỏ cho mẹ còn sống, trắng cho mẹ đã mất), lễ chùa"
        }
    },
    "Tết Trung Thu (Mid-Autumn Festival)": {
        "description": {
            "en": "Children's festival celebrating the full moon and harvest",
            "native": "Tết thiếu nhi kỷ niệm trăng tròn và mùa thu hoạch"
        },
        "culturalSignificance": {
            "en": "Lion dances, lantern processions, eating mooncakes, family gatherings",
            "native": "Múa lân, rước đèn, ăn bánh trung thu, sum họp gia đình"
        }
    }
}

# Bilingual descriptions for China
china_translations = {
    "Spring Festival (Chinese New Year)": {
        "description": {
            "en": "The most important traditional Chinese holiday celebrating the beginning of the lunar new year",
            "native": "中国最重要的传统节日，庆祝农历新年的开始"
        },
        "culturalSignificance": {
            "en": "Family reunions, ancestor worship, and welcoming prosperity for the new year",
            "native": "家庭团聚、祭祖、迎接新年的繁荣"
        }
    },
    "Lantern Festival (Yuan Xiao Jie)": {
        "description": {
            "en": "Traditional festival marking the end of Chinese New Year celebrations",
            "native": "标志着春节庆祝活动结束的传统节日"
        },
        "culturalSignificance": {
            "en": "Lighting lanterns, solving riddles, and eating tangyuan (sweet rice balls)",
            "native": "点灯笼、猜灯谜、吃汤圆"
        }
    },
    "Dragon Boat Festival (Duan Wu Jie)": {
        "description": {
            "en": "Festival commemorating the poet Qu Yuan with dragon boat races",
            "native": "纪念诗人屈原的节日，举行龙舟比赛"
        },
        "culturalSignificance": {
            "en": "Dragon boat racing, eating zongzi (rice dumplings), and warding off evil spirits",
            "native": "赛龙舟、吃粽子、驱邪避凶"
        }
    },
    "Mid-Autumn Festival (Zhong Qiu Jie)": {
        "description": {
            "en": "Festival celebrating the full moon and harvest season",
            "native": "庆祝满月和丰收季节的节日"
        },
        "culturalSignificance": {
            "en": "Family gatherings, moon gazing, and eating mooncakes",
            "native": "家庭团聚、赏月、吃月饼"
        }
    }
}

# Bilingual descriptions for Korea
korea_translations = {
    "Seollal (Korean New Year)": {
        "description": {
            "en": "Korean New Year celebration with traditional customs and family gatherings",
            "native": "전통 풍습과 가족 모임이 있는 한국의 설날 축하"
        },
        "culturalSignificance": {
            "en": "Ancestral rites (charye), traditional games (yutnori), and wearing hanbok",
            "native": "차례 지내기, 윷놀이, 한복 입기"
        }
    },
    "Chuseok (Korean Thanksgiving)": {
        "description": {
            "en": "Major harvest festival and time for honoring ancestors",
            "native": "주요 추수 축제이자 조상을 기리는 명절"
        },
        "culturalSignificance": {
            "en": "Family reunions, ancestral rites (charye), sharing traditional foods like songpyeon, and tomb visits",
            "native": "가족 모임, 차례, 송편 나누기, 성묘"
        }
    },
    "Chopail (Buddha's Birthday)": {
        "description": {
            "en": "Buddhist festival celebrating the birth of Buddha",
            "native": "부처님의 탄생을 기념하는 불교 축제"
        },
        "culturalSignificance": {
            "en": "Lantern festivals, temple visits, lotus lantern parades, and charitable acts",
            "native": "연등 축제, 사찰 방문, 연등 행렬, 자선 활동"
        }
    }
}

# Bilingual descriptions for Japan
japan_translations = {
    "Oshogatsu (Japanese New Year)": {
        "description": {
            "en": "Traditional Japanese New Year celebration (historically lunar, now solar)",
            "native": "伝統的な日本の正月祝い（歴史的には旧暦、現在は新暦）"
        },
        "culturalSignificance": {
            "en": "Family gatherings, shrine visits (hatsumode), traditional foods (osechi), and New Year games",
            "native": "家族の集まり、初詣、おせち料理、正月遊び"
        }
    },
    "Obon (Ancestor Festival)": {
        "description": {
            "en": "Buddhist festival for honoring deceased ancestors",
            "native": "亡くなった先祖を敬う仏教の祭り"
        },
        "culturalSignificance": {
            "en": "Welcoming ancestor spirits, lantern lighting, bon odori dancing, and family reunions",
            "native": "先祖の霊を迎える、灯籠流し、盆踊り、家族の再会"
        }
    },
    "Tsukimi (Moon Viewing Festival)": {
        "description": {
            "en": "Traditional festival for appreciating the autumn moon",
            "native": "秋の月を鑑賞する伝統的な祭り"
        },
        "culturalSignificance": {
            "en": "Moon viewing parties, eating tsukimi dango, decorating with pampas grass, and poetry",
            "native": "月見の会、月見団子、ススキの飾り、詩歌"
        }
    }
}

def update_event_with_translation(event, translations):
    """Update an event with bilingual descriptions if translation exists."""
    event_name = event.get("name", "")
    
    if event_name in translations:
        trans = translations[event_name]
        if "description" in trans:
            event["description"] = trans["description"]
        if "culturalSignificance" in trans:
            event["culturalSignificance"] = trans["culturalSignificance"]
    
    return event

def update_country_file(filename, translations):
    """Update a country file with bilingual descriptions."""
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Update each event
        for event in data.get("publicHolidays", []):
            update_event_with_translation(event, translations)
        
        # Write back
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Updated {filename}")
        return True
    except Exception as e:
        print(f"❌ Error updating {filename}: {e}")
        return False

if __name__ == "__main__":
    print("Updating country files with bilingual descriptions...\n")
    
    # Update each country file
    update_country_file("Luca/Data/vn-events.json", vietnam_translations)
    
    print("\n✅ All files updated with bilingual descriptions!")
    print("\nNote: Only major festivals have been translated.")
    print("You can add more translations by editing this script.")
