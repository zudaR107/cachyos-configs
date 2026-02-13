// user.js — portable Firefox preferences
//
// Installation
// 1) Close Firefox completely.
// 2) Locate your active profile directory:
//    - Open Firefox -> Settings -> Help -> More troubleshooting information (about:support)
//    - In "Profile Folder", click "Open Folder" (or "Open Directory").
// 3) Copy this file as `user.js` into that profile directory (next to `prefs.js`).
// 4) Start Firefox.
//
// Notes
// - `user.js` is applied on Firefox startup and writes values into the profile preferences.
// - If you change the same settings in about:config/UI, they can be overwritten on the next start
//   as long as the preference is present in `user.js`.
// - If you use multiple profiles, place a separate `user.js` into each target profile folder.

//
// Privacy and telemetry
//
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.server", "");
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);

//
// HTTPS and security
//
user_pref("dom.security.https_only_mode", true);

//
// New Tab page content
//
user_pref("browser.newtabpage.activity-stream.feeds.system.topstories", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

//
// UI and appearance
//
user_pref("layout.css.prefers-color-scheme.content-override", 1); // 0=OS default, 1=light, 2=dark
user_pref("font.name.serif.x-western", "Ubuntu Mono");
user_pref("font.size.variable.x-western", 14);

//
// Startup behavior
//
user_pref("browser.startup.page", 3); // 0=blank, 1=home, 3=restore previous session

//
// Downloads
//
user_pref("browser.download.lastDir", "~/Downloads");

//
// PDF viewer accessibility
//
user_pref("pdfjs.enableAltText", true);
user_pref("pdfjs.enableAltTextForEnglish", true);

//
// Optional: disable Pocket integration
//
user_pref("extensions.pocket.enabled", false);

//
// Optional: reduce URL bar tip prompts
//
user_pref("browser.urlbar.tipShownCount.searchTip_onboard", 0);
