//
//  AppLanguage.swift
//  Macro
//
//  Created by Ghala Alsalem on 02/06/2026.
//

import SwiftUI
import Observation

// MARK: - App Language
enum AppLanguage: String, CaseIterable {
    case arabic = "ar"
    case english = "en"

    var layoutDirection: LayoutDirection {
        self == .arabic ? .rightToLeft : .leftToRight
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

// MARK: - Language Manager
// Holds the current language and looks up localized strings from an in-memory
// table. Being @Observable, any view that reads `lang.current` or calls
// `lang.t(...)` updates instantly when the language changes — which is what
// makes the in-app toggle switch the whole UI without an app restart.
@Observable
@MainActor
final class LanguageManager {

    var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "appLanguage")
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage")
        self.current = AppLanguage(rawValue: saved ?? "") ?? .arabic
    }

    func toggle() {
        current = (current == .arabic) ? .english : .arabic
    }

    /// Look up a localized string by key for the current language.
    func t(_ key: String) -> String {
        let table = (current == .arabic) ? Self.ar : Self.en
        return table[key] ?? key
    }

    // MARK: - English Table
    static let en: [String: String] = [
        // Welcome
        "welcome.tagline": "Your journey starts\nwith a brick.",
        "welcome.getStarted": "Get started",
        "welcome.signInApple": "Sign in with Apple",
        // Tabs
        "tab.summary": "Summary",
        "tab.house": "House",
        "tab.portfolio": "Portfolio",
        // Shared stats
        "stat.totalInvested": "Total Invested",
        "stat.totalGain": "Total gain",
        "unit.sar": "SAR",
        "label.portfolio": "PORTFOLIO",
        // Analytics / upgrade panel
        "upgrade.nextIn": "Next upgrade in",
        "upgrade.complete": "Estate complete",
        "upgrade.builtFull": "Your estate is fully built",
        "upgrade.bricksToNext": "%d bricks to next upgrade",   // %d = remaining
        "upgrade.brickToNext": "%d brick to next upgrade",
        // Portfolio list
        "portfolio.title": "Portfolio",
        "portfolio.searchPlaceholder": "Search global or Tadawul stocks...",
        "portfolio.empty": "Your portfolio is empty",
        "portfolio.addInline": "Add Stock Inline",
        "portfolio.closePanel": "Close Panel",
        "portfolio.shares": "Shares",
        "portfolio.share": "Share",
        // Buy sheet
        "buy.title": "Add to Portfolio",
        "buy.livePrice": "Live market price",
        "buy.quantity": "Quantity",
        "buy.pricePerShare": "Price per share",
        "buy.date": "Purchase date",
        "buy.totalCost": "Total cost",
        "buy.confirm": "Add %d Shares",
        "buy.confirmOne": "Add %d Share",
        "buy.loadingPrice": "Loading price…",
        "buy.priceUnavailable": "Price unavailable — enter manually",
        "buy.enterPrice": "Enter a price to continue",
        "buy.added": "Added to portfolio",
        "buy.addedBody": "%d shares of %@ at %.2f %@ each.",
        "remove.swipe": "Remove",
        "remove.confirmTitle": "Remove this holding?",
        "remove.confirmBody": "This deletes all buy and sell records for this stock. This can't be undone.",
        "remove.confirm": "Remove",
        "remove.cancel": "Cancel",
        // Categories
        "category.Popular": "Popular",
        "category.Banking": "Banking",
        "category.Energy": "Energy",
        "category.Real Estate": "Real Estate",
        "category.Consumer": "Consumer",
        "category.Health": "Health",
        "category.Saudi Market": "Saudi Market",
        "category.Global": "Global",
        // Holding detail / sell
        "sell.sharesHeld": "Shares held",
        "sell.avgBuyPrice": "Average buy price",
        "sell.currentPrice": "Current price",
        "sell.currentValue": "Current value",
        "sell.unrealizedGain": "Unrealized gain",
        "sell.loading": "Loading…",
        "sell.howMany": "How many shares to sell?",
        "sell.all": "All",
        "sell.realizedGain": "Realized gain",
        "sell.bricksEarned": "Bricks earned",
        "sell.loadingPrice": "Loading price…",
        "sell.sellShares": "Sell %d Shares",   // %d = quantity
        "sell.sellShare": "Sell %d Share",
        "sell.brickEarnedTitle": "brick earned!",
        "sell.bricksEarnedTitle": "bricks earned!",
        "sell.rewardBody": "Locked in from your profit.\nThey're yours to keep.",
        "sell.complete": "Sale complete",
        "sell.noBricks": "No bricks this time — they're only earned on a profit.",
        "common.done": "Done",
        // House progression
        "house.back": "Back",
        "house.blueprint": "Estate Blueprint",
        "house.pipeline": "CONSTRUCTION PIPELINE",
        "house.stagePrefix": "Stage",        // "Stage 2: ..."
        "house.lifetimeScore": "Lifetime Brick Score: %d",
        "house.requiresBricks": "Requires %d Bricks",
        // Stage names
        "stage.1.name": "Foundation Laying",
        "stage.2.name": "Structural Framing",
        "stage.3.name": "Brick Masonry",
        "stage.4.name": "Roofing & Trim",
        "stage.5.name": "Finished Estate",
        // Stage descriptions
        "stage.1.desc": "Clearing the land plotting vectors and casting raw baseline mortar.",
        "stage.2.desc": "Erecting structural columns and boundary framing layout structures.",
        "stage.3.desc": "Laying exterior structural insulation envelopes and stone details.",
        "stage.4.desc": "Securing environmental barriers and framing premium structural eaves.",
        "stage.5.desc": "The architectural model is fully developed, polished, and operational.",
        // Summary titles (structural only; report content is Phase 5)
        "summary.title": "Summary",
        "summary.settings": "Summary Settings",
        "summary.analyzing": "Analyzing your portfolio…",
        "summary.addStocks": "Add stocks to generate a summary",
        // Summary report content
        "summary.viewFullReport": "View full report",
        "summary.howCalculated": "How it's calculated",
        "summary.initialValue": "Initial value",
        "summary.positionGains": "Position gains",
        "summary.positionLosses": "Position losses",
        "summary.netChange": "Net change",
        "summary.changeSinceBuy": "Portfolio changed %@%.1f%% since purchase.",
        "summary.vsMarket": "You vs the market",
        "summary.yourPortfolio": "Your portfolio",
        "summary.tasiIndex": "TASI (market index)",
        "summary.outperformed": "Outperformed the market by %@%.1f%%",
        "summary.underperformed": "Trailed the market by %.1f%%",
        "summary.sectorPerf": "Your sector performance",
        "summary.forwardLook": "Looking ahead",
        "summary.topMovers": "Top movers",
        "summary.totalBricks": "Total bricks earned",
        "summary.fromRealized": "From your realized profits",
        "summary.nextLabel": "Next summary: %@",
        // Week classification (English equivalents)
        "week.exceptional": "An exceptional week",
        "week.strongPositive": "A strong positive week",
        "week.positive": "A positive week",
        "week.calm": "A calm week",
        "week.negative": "A negative week",
        "week.tough": "A tough week",
        // Forward-look text
        "summary.forwardAhead": "Your portfolio is ahead of the market by %.1f%%. Keep it up.",
        "summary.forwardBehind": "Your portfolio is under pressure this week. Watch your positions closely.",
        // Week label prefix
        "summary.weekPrefix": "Portfolio – week of %@",
        // Since-started content
        "summary.explainTitle": "How this is calculated",
        "summary.explainBody": "Your portfolio value is the sum of your current holdings at today's market prices. The figure shown is the change since you started tracking.",
        "summary.sinceStarted": "since you started",
        "summary.sentencePositive": "Portfolio up %.1f%% since you started. %d of %d positions are positive. %@ contributed %@ %@.",
        "summary.sentenceNegative": "Portfolio down %.1f%% since you started. %d of %d positions are positive. %@ contributed %@ %@.",
        "summary.bricksSince": "Bricks earned since you started"
    ]

    // MARK: - Arabic Table
    static let ar: [String: String] = [
        // Welcome
        "welcome.tagline": "رحلتك تبدأ\nبطابوقة.",
        "welcome.getStarted": "ابدأ الآن",
        "welcome.signInApple": "تسجيل الدخول عبر Apple",
        // Tabs
        "tab.summary": "الملخص",
        "tab.house": "المنزل",
        "tab.portfolio": "المحفظة",
        // Shared stats
        "stat.totalInvested": "إجمالي الاستثمار",
        "stat.totalGain": "إجمالي الربح",
        "unit.sar": "ريال",
        "label.portfolio": "المحفظة",
        // Analytics / upgrade panel
        "upgrade.nextIn": "الترقية القادمة",
        "upgrade.complete": "اكتمل المنزل",
        "upgrade.builtFull": "تم بناء منزلك بالكامل",
        "upgrade.bricksToNext": "%d طابوقة للترقية القادمة",
        "upgrade.brickToNext": "طابوقة واحدة للترقية القادمة",
        // Portfolio list
        "portfolio.title": "المحفظة",
        "portfolio.searchPlaceholder": "ابحث عن أسهم سعودية أو عالمية...",
        "portfolio.empty": "محفظتك فارغة",
        "portfolio.addInline": "إضافة سهم",
        "portfolio.closePanel": "إغلاق",
        "portfolio.shares": "أسهم",
        "portfolio.share": "سهم",
        // Buy sheet
        "buy.title": "إضافة إلى المحفظة",
        "buy.livePrice": "السعر السوقي الحالي",
        "buy.quantity": "الكمية",
        "buy.pricePerShare": "سعر السهم",
        "buy.date": "تاريخ الشراء",
        "buy.totalCost": "التكلفة الإجمالية",
        "buy.confirm": "إضافة %d أسهم",
        "buy.confirmOne": "إضافة %d سهم",
        "buy.loadingPrice": "جارٍ تحميل السعر…",
        "buy.priceUnavailable": "السعر غير متاح — أدخله يدويًا",
        "buy.enterPrice": "أدخل سعرًا للمتابعة",
        "buy.added": "تمت الإضافة إلى المحفظة",
        "buy.addedBody": "%d سهم من %@ بسعر %.2f %@ للسهم.",
        "remove.swipe": "حذف",
        "remove.confirmTitle": "حذف هذا المركز؟",
        "remove.confirmBody": "سيؤدي هذا إلى حذف جميع سجلات الشراء والبيع لهذا السهم. لا يمكن التراجع.",
        "remove.confirm": "حذف",
        "remove.cancel": "إلغاء",
        // Categories
        "category.Popular": "الأكثر تداولًا",
        "category.Banking": "البنوك",
        "category.Energy": "الطاقة",
        "category.Real Estate": "العقارات",
        "category.Consumer": "الاستهلاكية",
        "category.Health": "الصحة",
        "category.Saudi Market": "السوق السعودي",
        "category.Global": "عالمي",
        // Holding detail / sell
        "sell.sharesHeld": "الأسهم المملوكة",
        "sell.avgBuyPrice": "متوسط سعر الشراء",
        "sell.currentPrice": "السعر الحالي",
        "sell.currentValue": "القيمة الحالية",
        "sell.unrealizedGain": "الربح غير المحقق",
        "sell.loading": "جارٍ التحميل…",
        "sell.howMany": "كم سهمًا تريد بيعه؟",
        "sell.all": "الكل",
        "sell.realizedGain": "الربح المحقق",
        "sell.bricksEarned": "الطابوق المكتسب",
        "sell.loadingPrice": "جارٍ تحميل السعر…",
        "sell.sellShares": "بيع %d أسهم",
        "sell.sellShare": "بيع %d سهم",
        "sell.brickEarnedTitle": "طابوقة مكتسبة!",
        "sell.bricksEarnedTitle": "طابوق مكتسب!",
        "sell.rewardBody": "محقق من أرباحك.\nأصبح ملكًا لك.",
        "sell.complete": "تم البيع",
        "sell.noBricks": "لا طابوق هذه المرة — يُكتسب فقط عند تحقيق ربح.",
        "common.done": "تم",
        // House progression
        "house.back": "رجوع",
        "house.blueprint": "مخطط المنزل",
        "house.pipeline": "مراحل البناء",
        "house.stagePrefix": "المرحلة",
        "house.lifetimeScore": "إجمالي رصيد الطابوق: %d",
        "house.requiresBricks": "يتطلب %d طابوقة",
        // Stage names
        "stage.1.name": "تأسيس الأساس",
        "stage.2.name": "الهيكل الإنشائي",
        "stage.3.name": "بناء الطابوق",
        "stage.4.name": "السقف والتشطيب",
        "stage.5.name": "المنزل المكتمل",
        // Stage descriptions
        "stage.1.desc": "تجهيز الأرض وتحديد المخطط وصبّ الأساس.",
        "stage.2.desc": "إقامة الأعمدة الإنشائية وهيكل الحدود الخارجية.",
        "stage.3.desc": "بناء الجدران الخارجية والعزل وتفاصيل الحجر.",
        "stage.4.desc": "تركيب السقف والحواجز والتشطيبات الخارجية.",
        "stage.5.desc": "اكتمل المنزل بالكامل وأصبح جاهزًا.",
        // Summary titles
        "summary.title": "الملخص",
        "summary.settings": "إعدادات الملخص",
        "summary.analyzing": "يتم تحليل محفظتك…",
        "summary.addStocks": "أضف أسهمًا لتوليد الملخص",
        // Summary report content
        "summary.viewFullReport": "عرض التقرير الكامل",
        "summary.howCalculated": "كيف تم الحساب",
        "summary.initialValue": "القيمة الابتدائية",
        "summary.positionGains": "أرباح المراكز",
        "summary.positionLosses": "خسائر المراكز",
        "summary.netChange": "صافي التغيير",
        "summary.changeSinceBuy": "تغيّرت المحفظة %@%.1f%% منذ الشراء.",
        "summary.vsMarket": "محفظتك مقابل السوق",
        "summary.yourPortfolio": "محفظتك",
        "summary.tasiIndex": "TASI (مؤشر السوق)",
        "summary.outperformed": "تفوقت على السوق بـ %@%.1f%%",
        "summary.underperformed": "تراجعت عن السوق بـ %.1f%%",
        "summary.sectorPerf": "أداء قطاعات محفظتك",
        "summary.forwardLook": "نظرة للأمام",
        "summary.topMovers": "أبرز المتحركين",
        "summary.totalBricks": "إجمالي الطابوق المكتسب",
        "summary.fromRealized": "من أرباحك المحققة",
        "summary.nextLabel": "الملخص القادم: %@",
        // Week classification
        "week.exceptional": "أسبوع استثنائي",
        "week.strongPositive": "أسبوع إيجابي قوي",
        "week.positive": "أسبوع إيجابي",
        "week.calm": "أسبوع هادئ",
        "week.negative": "أسبوع سلبي",
        "week.tough": "أسبوع صعب",
        // Forward-look text
        "summary.forwardAhead": "محفظتك متقدمة على السوق بنسبة %.1f٪. واصل المتابعة.",
        "summary.forwardBehind": "محفظتك تحت ضغط هذا الأسبوع. راقب مراكزك عن كثب.",
        // Week label prefix
        "summary.weekPrefix": "المحفظة – أسبوع %@",
        // Since-started content
        "summary.explainTitle": "كيف يتم الحساب",
        "summary.explainBody": "قيمة محفظتك هي مجموع مراكزك الحالية بأسعار السوق اليوم. الرقم المعروض هو التغيّر منذ بدء التتبّع.",
        "summary.sinceStarted": "منذ البداية",
        "summary.sentencePositive": "ارتفعت المحفظة %.1f%% منذ البداية. %d من %d مراكز رابحة. ساهم %@ بـ %@ %@.",
        "summary.sentenceNegative": "انخفضت المحفظة %.1f%% منذ البداية. %d من %d مراكز رابحة. ساهم %@ بـ %@ %@.",
        "summary.bricksSince": "الطابوق المكتسب منذ البداية"
    ]
}
