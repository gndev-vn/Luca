import Foundation
import SwiftUI

/// Service for providing localized strings in Vietnamese
class LocalizedStringService {
    static let shared = LocalizedStringService()

    var localizationBundle: Bundle = {
        guard let path = Bundle.main.path(forResource: "vi", ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }()

    private init() {}

    func localizedString(for key: LocalizedStringKey) -> String {
        return NSLocalizedString(key.rawValue, bundle: localizationBundle, comment: "")
    }

    func localizedWeekdayShort(_ weekday: Int) -> String {
        guard (1...7).contains(weekday) else { return "" }
        if weekday == 1 {
            return NSLocalizedString("weekday_short_1", bundle: localizationBundle, comment: "")
        }
        let format = NSLocalizedString("weekday_short_format", bundle: localizationBundle, comment: "")
        return String(format: format, weekday)
    }

    func localizedWeekdayFull(_ weekday: Int) -> String {
        let key = "weekday_full_\(weekday)"
        return NSLocalizedString(key, bundle: localizationBundle, comment: "")
    }

    func localizedMonthFormat(_ month: Int, isLeap: Bool = false) -> String {
        let format = NSLocalizedString(isLeap ? "month_leap_format" : "month_format", bundle: localizationBundle, comment: "")
        return String(format: format, month)
    }

    func localizedMonthFull(_ month: Int) -> String {
        let key = "lunar_month_\(month)"
        return NSLocalizedString(key, bundle: localizationBundle, comment: "")
    }
}

enum LocalizedStringKey: String, CaseIterable {
    case calendar = "calendar"
    case events = "events"
    case settings = "settings"

    case done = "done"
    case cancel = "cancel"
    case delete = "delete"
    case save = "save"
    case edit = "edit"
    case add = "add"

    case lunarCalendar = "lunar_calendar"
    case noEventsForDate = "no_events_for_date"
    case loadingEvents = "loading_events"
    case today = "today"

    case eventDetails = "event_details"
    case holidayDetails = "holiday_details"
    case deleteEvent = "delete_event"
    case disableEvent = "disable_event"
    case enableEvent = "enable_event"
    case disableEventConfirmation = "disable_event_confirmation"
    case disableEventMessage = "disable_event_message"
    case enableEventMessage = "enable_event_message"
    case createEvent = "create_event"
    case editEvent = "edit_event"

    case notificationSettings = "notification_settings"
    case themeSettings = "theme_settings"
    case about = "about"

    case eventNotFound = "event_not_found"
    case loadingEvent = "loading_event"
    case goBack = "go_back"
    case eventNotFoundMessage = "event_not_found_message"
    case failedToLoadEvent = "failed_to_load_event"

    case loading = "loading"
    case leapMonth = "leap_month"
    case duration = "duration"
    case day = "day"
    case days = "days"
    case reminders = "reminders"
    case reminder = "reminder"
    case language = "language"
    case themeSystem = "theme_system"
    case themeLight = "theme_light"
    case themeDark = "theme_dark"
    case previewHolidayEvent = "preview_holiday_event"
    case previewPersonalEvent = "preview_personal_event"

    case lunarDate = "lunar_date"
    case noEventsOnDate = "no_events_on_date"
    case permissionStatus = "permission_status"
    case enableNotificationsDescription = "enable_notifications_description"
    case scheduledNotifications = "scheduled_notifications"
    case scheduledNotificationsDescription = "scheduled_notifications_description"
    case notificationTypes = "notification_types"
    case notifications = "notifications"
    case advanced = "advanced"
    case resetSettingsDescription = "reset_settings_description"
    case preview = "preview"
    case themeOptions = "theme_options"
    case themeDescription = "theme_description"
    case themeInformation = "theme_information"
    case eventTitle = "event_title"
    case descriptionOptional = "description_optional"
    case upcomingEvents = "upcoming_events"
    case andMoreFormat = "and_more_format"

    case newEvent = "new_event"
    case category = "category"
    case reminderDescription = "reminder_description"
    case validationError = "validation_error"
    case eventTitleRequired = "event_title_required"
    case invalidLunarDate = "invalid_lunar_date"
    case saving = "saving"
    case create = "create"
    case selectLunarDate = "select_lunar_date"
    case gregorianEquivalent = "gregorian_equivalent"
    case year = "year"
    case month = "month"

    case addEvent = "add_event"
    case quickAdd = "quick_add"
    case createCustomEvent = "create_custom_event"
    case addPersonalizedEvent = "add_personalized_event"
    case commonEvents = "common_events"
    case recentEvents = "recent_events"
    case duplicate = "duplicate"
    case dateInformation = "date_information"
    case gregorianDate = "gregorian_date"
    case gregorian = "gregorian"
    case description = "description"
    case deleteEventConfirmation = "delete_event_confirmation"
    case deleteEventMessage = "delete_event_message"

    case birthday = "birthday"
    case celebrateBirthday = "celebrate_birthday"
    case anniversary = "anniversary"
    case weddingAnniversary = "wedding_anniversary"
    case familyGathering = "family_gathering"
    case familyReunion = "family_reunion"
    case culturalFestival = "cultural_festival"
    case traditionalCelebration = "traditional_celebration"
    case memorialDay = "memorial_day"
    case rememberAncestors = "remember_ancestors"
    case personalMilestone = "personal_milestone"
    case personalAchievement = "personal_achievement"
    case copy = "copy"

    case dateDetails = "date_details"
 

    case back = "back"
    case welcomeToLuca = "welcome_to_luca"
    case onboardingWelcomeDescription = "onboarding_welcome_description"
    case getStarted = "get_started"
    case continueAction = "continue_action"
    case enableNotifications = "enable_notifications"
    case notificationsDescription = "notifications_description"
    case eventReminders = "event_reminders"
    case eventRemindersDescription = "event_reminders_description"
    case holidayAlerts = "holiday_alerts"
    case holidayAlertsDescription = "holiday_alerts_description"
    case notificationsEnabled = "notifications_enabled"
    case skipForNow = "skip_for_now"
    case powerfulFeatures = "powerful_features"
    case featuresDescription = "features_description"
    case unifiedCalendar = "unified_calendar"
    case unifiedCalendarDesc = "unified_calendar_desc"
    case culturalHolidays = "cultural_holidays"
    case culturalHolidaysDesc = "cultural_holidays_desc"
    case customEvents = "custom_events"
    case customEventsDesc = "custom_events_desc"
    case smartReminders = "smart_reminders"
    case smartRemindersDesc = "smart_reminders_desc"
    case youreAllSet = "youre_all_set"
    case startUsingLuca = "start_using_luca"
    case onboardingPersonalEventReminders = "onboarding_personal_event_reminders"
    case onboardingPersonalEventRemindersDesc = "onboarding_personal_event_reminders_desc"
    case onboardingHolidaysEvents = "onboarding_holidays_events"
    case onboardingHolidaysEventsDesc = "onboarding_holidays_events_desc"
    case onboardingNotifications = "onboarding_notifications"
    case onboardingNotificationsDesc = "onboarding_notifications_desc"

    case aboutLuca = "about_luca"
    case aboutDescription = "about_description"
    case featuresTitle = "features_title"
    case vietnameseLunarCalendar = "vietnamese_lunar_calendar"
    case vietnameseCalendarDesc = "vietnamese_calendar_desc"
    case creditsTitle = "credits_title"
    case creditCalcAlgo = "credit_calc_algo"
    case creditHolidayData = "credit_holiday_data"
    case creditCommunity = "credit_community"
    case creditSwiftUI = "credit_swift_ui"
    case legalTitle = "legal_title"
    case privacyPolicy = "privacy_policy"
    case privacyPolicyDesc = "privacy_policy_desc"
    case openSource = "open_source"
    case openSourceDesc = "open_source_desc"
    case contactSupport = "contact_support"
    case emailSupport = "email_support"
    case emailSupportDesc = "email_support_desc"
    case rateAppStore = "rate_app_store"
    case rateAppStoreDesc = "rate_app_store_desc"
    case copyright = "copyright"
    case lunarCalendarApp = "lunar_calendar_app"
    case versionFormat = "version_format"

    case holidayNotifications = "holiday_notifications"
    case holidayNotificationsDesc = "holiday_notifications_desc"
    case requestPermission = "request_permission"
    case openSettings = "open_settings"
    case notificationsDisabled = "notifications_disabled"
    case permissionRequired = "permission_required"
    case provisionalAccess = "provisional_access"
    case temporaryAccess = "temporary_access"
    case unknownStatus = "unknown_status"
    case notificationsEnabledDesc = "notifications_enabled_desc"
    case notificationsDisabledDesc = "notifications_disabled_desc"
    case permissionRequiredDesc = "permission_required_desc"
    case provisionalAccessDesc = "provisional_access_desc"
    case temporaryAccessDesc = "temporary_access_desc"
    case unknownStatusDesc = "unknown_status_desc"

    case automaticTheme = "automatic_theme"
    case automaticThemeDesc = "automatic_theme_desc"
    case batteryOptimization = "battery_optimization"
    case batteryOptimizationDesc = "battery_optimization_desc"
    case themeAccessibility = "theme_accessibility"
    case themeAccessibilityDesc = "theme_accessibility_desc"
    case themeSystemDesc = "theme_system_desc"
    case themeLightDesc = "theme_light_desc"
    case themeDarkDesc = "theme_dark_desc"

    case categoryPersonal = "category_personal"
    case categoryFamily = "category_family"
    case categoryCultural = "category_cultural"
    case categoryReligious = "category_religious"
    case categoryWork = "category_work"
    case categoryOther = "category_other"

    case repeatsAnnually = "repeats_annually"
    case recurrence = "recurrence"
    case repeatEvent = "repeat_event"
    case recurrenceNone = "recurrence_none"
    case recurrenceDaily = "recurrence_daily"
    case recurrenceWeekly = "recurrence_weekly"
    case recurrenceMonthly = "recurrence_monthly"
    case recurrenceYearly = "recurrence_yearly"

    case reminderOnDay = "reminder_on_day"
    case reminderOneDayBefore = "reminder_one_day_before"
    case reminderTwoDaysBefore = "reminder_two_days_before"
    case reminderThreeDaysBefore = "reminder_three_days_before"

    case lunarFullYearFormat = "lunar_full_year_format"
    case lunarDateLine1Format = "lunar_date_line1_format"
    case lunarDateLine2Format = "lunar_date_line2_format"
    case gregorianDateFormat = "gregorian_date_format"
    case correspondingGregorian = "corresponding_gregorian"
    case lunarDayZodiacFormat = "lunar_day_zodiac_format"
    case lunarDateSearchFormat = "lunar_date_search_format"
    case selectLunarMonth = "select_lunar_month"

    case initializationFailed = "initialization_failed"
    case initializationErrorDescription = "initialization_error_description"
    case errorDetails = "error_details"
    case tryAgain = "try_again"
    case restartPrompt = "restart_prompt"

    case searchEvents = "search_events"
    case allCategories = "all_categories"
    case noResultsFound = "no_results_found"
    case noEventsInCategory = "no_events_in_category"
    case noEventsYet = "no_events_yet"
    case noEventsToday = "no_events_today"
    case noEventsUpcoming = "no_events_upcoming"
    case noEventsPersonal = "no_events_personal"
    case noEventsCultural = "no_events_cultural"
    case noEventsReligion = "no_events_religion"

    case createFirstEvent = "create_first_event"
    case noResultsMessage = "no_results_message"
    case noEventsInCategoryMessage = "no_events_in_category_message"
    case noEventsFilterMessage = "no_events_filter_message"
    case createFirstEventMessage = "create_first_event_message"
    case resetToDefaults = "reset_to_defaults"

    case developer = "developer"
    case developerOptions = "developer_options"
    case reSeedHolidays = "re_seed_holidays"
    case reSeed = "re_seed"
    case reSeedTitle = "re_seed_title"
    case reseedingDescription = "reseeding_description"
    case reseedingWarning = "reseeding_warning"
    case holidaysReSeeded = "holidays_re_seeded"
    case holidaysReSeededSuccess = "holidays_re_seeded_success"
    case failedToReSeed = "failed_to_re_seed"
    case resetDeveloperMode = "reset_developer_mode"
    case resetDeveloperModeTitle = "reset_developer_mode_title"
    case resetDeveloperModeWarning = "reset_developer_mode_warning"
    case developerModeDisabled = "developer_mode_disabled"
    case developerModeEnabled = "developer_mode_enabled"
    case resetAllSettingsTitle = "reset_all_settings_title"
    case resetAllSettingsWarning = "reset_all_settings_warning"
    case settingsSaved = "settings_saved"
    case settingsReset = "settings_reset"

    case notifyOnDay = "notify_on_day"
    case notifyBefore = "notify_before"
    case notificationSound = "notification_sound"
    case vibration = "vibration"
    case soundAndVibration = "sound_and_vibration"
    case time = "time"
    case daysBefore = "days_before"

    case culturalNotifications = "cultural_notifications"
    case religiousNotifications = "religious_notifications"

    case recurrenceWeeklyFormat = "recurrence_weekly_format"
    case recurrenceMonthlyFormat = "recurrence_monthly_format"
    case recurrenceYearlyFormat = "recurrence_yearly_format"

    case muteNotifications = "mute_notifications"
    case unmuteNotifications = "unmute_notifications"
}
