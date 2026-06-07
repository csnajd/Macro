//
//  ConsentSheet.swift
//  Macro
//
//  Created by Ghala Alsalem on 07/06/2026.
//


import SwiftUI

// MARK: - Consent Sheet (PDPL notice at the point of entry)
// Shown once before the user first enters the app. Summarizes what the app
// does with data, links to the full policy, and requires an explicit agree.
// The agreement flag is stored in UserDefaults ("privacyAccepted").
struct ConsentSheet: View {
    @Environment(LanguageManager.self) private var lang
    let onAgree: () -> Void

    @State private var showFullPolicy = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundColor(Color("light brown"))
                .padding(.top, 28)

            Text(lang.t("consent.title"))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color("brown"))

            Text(lang.t("consent.body"))
                .font(.system(size: 14))
                .foregroundColor(Color("brown").opacity(0.75))
                .multilineTextAlignment(lang.current == .arabic ? .trailing : .leading)
                .padding(.horizontal, 28)

            Button {
                showFullPolicy = true
            } label: {
                Text(lang.t("consent.readPolicy"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("light brown"))
                    .underline()
            }

            Spacer()

            Button {
                onAgree()
            } label: {
                Text(lang.t("consent.agree"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("light brown"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Color("baige").ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showFullPolicy) {
            PrivacyPolicyView()
                .environment(lang)
        }
    }
}

// MARK: - Full Privacy Policy
// The complete bilingual policy, accurate to the app's actual architecture:
// all data on-device, no servers, no analytics, third-party price API.
struct PrivacyPolicyView: View {
    @Environment(LanguageManager.self) private var lang
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(lang.t("privacy.title"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("brown"))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color("brown").opacity(0.3))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)

            ScrollView {
                Text(lang.current == .arabic ? Self.policyAR : Self.policyEN)
                    .font(.system(size: 14))
                    .foregroundColor(Color("brown").opacity(0.85))
                    .multilineTextAlignment(lang.current == .arabic ? .trailing : .leading)
                    .frame(maxWidth: .infinity, alignment: lang.current == .arabic ? .trailing : .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .background(Color("baige").ignoresSafeArea())
    }

    // MARK: Policy text (English)
    static let policyEN = """
Last updated: June 2026

Rassah ("the app") is a portfolio tracking and educational app. This policy explains what data the app handles and how.

1. Data stays on your device
All your data — holdings, transactions, bricks, snapshots, and settings — is stored locally on your device only. The app has no servers, no user database, and no analytics. We never receive, see, or store your data.

2. Sign in with Apple
If you sign in with Apple, the app stores an anonymous Apple-provided identifier on your device only. It is not transmitted to us (we have no servers to send it to). You may use the app as a guest without signing in; signing in is required only to add stocks.

3. Market prices
Stock prices are fetched from a third-party market data service. These requests are made directly from your device and contain only the stock symbols being looked up — never your identity, holdings, or portfolio. Prices may be delayed and are provided for information only.

4. Notifications
Summary notifications are optional, scheduled and delivered locally on your device. No notification data leaves your device.

5. Your control
You can delete any holding inside the app, or delete all app data at any time by deleting the app. Because we hold no copies, deletion on your device is complete deletion.

6. Data transfers
The app does not transfer your personal data outside Saudi Arabia or anywhere else, because it does not collect it in the first place.

7. Children
The app is not directed at children under 13.

8. Not investment advice
The app is for tracking and education only. Nothing in it constitutes investment advice or a recommendation to buy or sell any security.

9. Changes and contact
If the app's data practices ever change (for example, if a future version adds online features), this policy will be updated and your consent requested again. Questions: [TEAM EMAIL]

This policy is intended to comply with the Saudi Personal Data Protection Law (PDPL).
"""

    // MARK: Policy text (Arabic)
    static let policyAR = """
آخر تحديث: يونيو 2026

«رصّة» («التطبيق») هو تطبيق لمتابعة المحفظة الاستثمارية ولأغراض تثقيفية. توضح هذه السياسة البيانات التي يتعامل معها التطبيق وكيفية ذلك.

١. بياناتك تبقى على جهازك
جميع بياناتك — المراكز والعمليات والطابوق واللقطات والإعدادات — تُحفظ محليًا على جهازك فقط. لا يملك التطبيق خوادم ولا قاعدة بيانات للمستخدمين ولا أدوات تحليلات. نحن لا نستلم بياناتك ولا نطّلع عليها ولا نخزّنها.

٢. تسجيل الدخول عبر Apple
عند تسجيل الدخول عبر Apple، يحفظ التطبيق معرّفًا مجهولًا صادرًا من Apple على جهازك فقط، ولا يُرسل إلينا (فلا خوادم لدينا أساسًا). يمكنك استخدام التطبيق كزائر دون تسجيل دخول؛ التسجيل مطلوب فقط لإضافة الأسهم.

٣. أسعار السوق
تُجلب أسعار الأسهم من خدمة بيانات سوق خارجية. تتم هذه الطلبات مباشرة من جهازك وتتضمن رموز الأسهم المطلوبة فقط — لا هويتك ولا مراكزك ولا محفظتك. قد تكون الأسعار متأخرة وهي للعلم فقط.

٤. الإشعارات
إشعارات الملخص اختيارية، وتُجدول وتُسلَّم محليًا على جهازك. لا تغادر بيانات الإشعارات جهازك.

٥. تحكمك في بياناتك
يمكنك حذف أي مركز داخل التطبيق، أو حذف جميع بيانات التطبيق في أي وقت بحذف التطبيق نفسه. ولأننا لا نحتفظ بأي نسخ، فإن الحذف من جهازك حذف كامل.

٦. نقل البيانات
لا ينقل التطبيق بياناتك الشخصية خارج المملكة العربية السعودية أو إلى أي جهة أخرى، لأنه لا يجمعها أصلًا.

٧. الأطفال
التطبيق غير موجّه للأطفال دون سن 13 عامًا.

٨. ليس نصيحة استثمارية
التطبيق للمتابعة والتثقيف فقط. لا يُعد أي محتوى فيه نصيحة استثمارية أو توصية بشراء أو بيع أي ورقة مالية.

٩. التغييرات والتواصل
إذا تغيّرت ممارسات البيانات في التطبيق (مثلًا بإضافة ميزات عبر الإنترنت في إصدار قادم)، فسيتم تحديث هذه السياسة وطلب موافقتك مجددًا. للاستفسارات: [TEAM EMAIL]

أُعدّت هذه السياسة بما يتوافق مع نظام حماية البيانات الشخصية السعودي (PDPL).
"""
}