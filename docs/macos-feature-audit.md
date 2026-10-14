# macOS 27 feature and performance audit

Research date: 2026-10-14. Scope: this Mac's macOS 27.0.1, compared with the
whole Sequoia 15 release family, including 15.x updates. Research uses Apple's
release notes and current, versioned user guides. Readings below were collected
on 2026-10-14, approximately 13:41–13:54 PDT. Availability, saved preferences,
and actual resource use are different observations. Priority: background CPU,
heat, and battery drain. The initial audit changed no feature settings, profiles,
or Nix configuration. Subsequent authorized changes are recorded below; no
build or activation was run.

Apple confirms **Golden Gate is macOS 27**; 27.0.1 contains bug fixes. The
current public documentation is available, so this audit does not rely on
pre-release speculation. [Apple release notes](https://support.apple.com/en-us/127257)

## Findings on this Mac

**No sustained heavy Apple AI workload was observed.** The strongest concrete
battery finding is reduced battery capacity. Some automatic features remain on,
and the existing profile does not cover every Golden Gate feature.

| Observation | Live result | Interpretation |
| --- | --- | --- |
| Hardware / OS | M1 MacBook Air (`MacBookAir10,1`), 8 GB RAM, macOS 27.0.1 build `26A434`; one internal display, 1440×900 logical resolution at 60 Hz | An 8 GB machine benefits from avoiding unnecessary concurrent work. No external-display workload was present. |
| Battery health | Maximum capacity **77%**, **651 cycles**, raw System Information condition **Check Battery** | Capacity loss directly reduces runtime. Battery evaluation/service is more consequential for restoring capacity than speculative AI tweaks. This does not establish that battery wear caused CPU slowdown. [Apple battery guidance](https://support.apple.com/en-gb/108376) |
| Power / thermals | Running on battery; Low Power Mode already enabled for battery and AC. `pmset -g therm` reported no recorded thermal or performance warning | Keep Low Power Mode for the stated battery priority. No thermal-throttling evidence captured; this is not a temperature measurement. [Power modes](https://support.apple.com/en-euro/101613) |
| CPU | Three interval samples: **81–93% total CPU idle** | No machine-wide CPU saturation during the sample. The user and audit were active, so this is not a controlled idle benchmark. |
| WindowServer | Roughly **13–14% CPU**, about **481 MB** in `top` | Possible visual-work optimization target. Per-process 100% means one CPU core; this was not 14% of all eight cores. Attribution to Liquid Glass requires an identical-workload comparison. |
| AI / photo services | Siri AI, modelmanagerd, generativeexperiencesd, photoanalysisd, mediaanalysisd, and sampled inference helpers showed **0.0% instantaneous CPU**; later samples were also quiet | Their presence does not prove AI is enabled or busy. Brief or future bursts remain possible. Do not disable shared daemons based on their names. |
| Search | Spotlight indexing enabled. `spotlightknowledged.updater` around **1.8–2.9% CPU** in sampled readings; ordinary indexers mostly quiet | Some background search work exists, but not a runaway indexer. Keep local search; consider exclusions only if sustained indexing is observed. |
| Memory | Approximately **2.6 GB compressed**, **1.4 GB swap used**, kernel pressure level `1`; no new swap-outs across the 15-second interval sample | Existing swap/compression is not proof of current thrashing. Watch growth during the actual slowdown. [Apple memory metrics](https://support.apple.com/guide/activity-monitor/view-memory-usage-actmntr1004/mac) |
| Browser / other apps | **31 Helium processes**, roughly **2.1 GiB summed RSS**; active Ghostty/Codex work; superwhisper also resident | Browser/app workload merits attention alongside OS features. Summed RSS may count shared pages more than once and excludes compressed/swapped memory; it is not unique physical footprint. |
| Storage / models | About **35 GiB available**. Spatial Photos assets occupy about **931 MB**. Other protected model directories could not be sized | Model storage is disk use, not equivalent resident RAM or CPU load. Removing models is not justified as an idle-performance fix here. |
| Sleep blockers | Active-turn Codex assertion; normal display-on/user-activity assertions; no kernel assertions | This audit itself prevents idle sleep while running. No Apple AI sleep blocker identified. |
| Recent sleep | Brief maintenance/SleepService wakes, commonly 2 seconds; the displayed battery charge stayed at 72% across the sampled sleeping period | No obvious prolonged wake loop in that excerpt. This is not a full overnight drain study. |

### Confirmed feature states

Effective preference reads used CoreFoundation; profile checks also required
`CFPreferencesAppValueIsForced`. Missing preferences are **unknown**, not false.

| Feature | Current state / evidence | Recommendation for this Mac |
| --- | --- | --- |
| Existing privacy/AI profile | **19/19 applied and enforced** via `just privacy-check` | Keep. Covers external integrations, Writing Tools, Genmoji, Image Playground, Mail/Notes/Safari summaries, Mail replies, Messages/notification summaries, inline predictions, Spatial Photos, Game Center, Music/Book Store, and Spotlight internet results. |
| Siri activation / voice trigger | `Assistant Enabled=false`, `VoiceTriggerUserEnabled=false`; Siri launch agent disabled. Siri AI process nevertheless resident and idle | Keep off. Process presence is not a reason to kill it. |
| ChatGPT user extension | `com.apple.siri.generativeassistantsettings:isEnabled=false`, plus enforced external-integration restrictions | Keep off. |
| Automatic Visual Look Up | Global `SSPreferencesVisualLookUpInSSSEnabled=false` | Keep off. Does not prove that every manually invoked Visual Intelligence operation has a separate restriction. |
| Legacy Apple Intelligence opt-in | Both stored numeric account entries false; `auto_opt_in=true`. Pinned module writes one hard-coded numeric account key | Do not interpret this as a verified global Golden Gate off switch, or interpret `auto_opt_in` alone as proof that inference is running. Prefer feature-specific controls. |
| **Finder filename suggestions** | **On**, directly read from Finder Settings → General: `SuggestNamesCheckBox=1` | **Disable if unwanted.** Automatic work on rename/save/edit; expected benefit modest and unmeasured. No verified writable Nix key found. |
| **Photos Enhanced Visual Search** | Initially **on**; subsequently set **off** in both the ordinary user domain and Photos' sandbox preferences, and declared in Nix (see follow-up below) | Keep off because Photos is unused. Separate from Siri Visual Look Up; existed in Sequoia. This setting does not establish that all photo analysis is disabled. |
| Reduced transparency / Liquid Glass tint | `reduceTransparency=true`, `EnhancedBackgroundContrastEnabled=1`, `NSGlassTintAmount=1` | Already simplified. Tint is not a complete glass-renderer disable switch. |
| **Reduce Motion** | **Off**, `com.apple.universalaccess:reduceMotion=false`; `com.apple.Accessibility:ReduceMotionEnabled=0` | **Enable** if less animation is acceptable. Low-risk visual simplification; evaluate benefit while interacting, not at idle. |
| Stage Manager | **Off**, `com.apple.WindowManager:GloballyEnabled=false` | No action. |
| **Aerial wallpaper / screen saver** | Aerial provider selected in WallpaperAgent's store; screen saver idle timeout **600 seconds**. Wallpaper helpers idle in sample | Optional: choose a still background and no screen saver. Battery display-off timeout is already 5 minutes, earlier than the 10-minute saver, so expected battery benefit is limited unless those conditions change. |
| Desktop widget visibility | Allowed: `StandardHideWidgets=false`, `StageManagerHideWidgets=false`. `chronod` idle | Remove widgets only if actually configured and unused. These flags do not prove there are active widgets. |
| Shortcuts automations | **Five enabled records** in both legacy/unified representations; five matched action records; **six recorded automation runs in last 24 hours** | No direct model/generation action found. Types were appearance changes, conditionals, and shell scripts. Shell script contents/callees were not inspected, so indirect AI calls remain unverified. Do not disable useful automations merely because Shortcuts gained AI. |
| Dictation / Voice Control / Live Speech | Dictation enabled; `CommandAndControlEnabled=0`; `liveSpeechEnabled=false` | Keep Dictation if used; an enabled shortcut is not evidence of continuous recording. Voice Control and Live Speech need no action. |
| Safari | Main Safari application not running. Search suggestions disabled; saved `ExtensionsEnabled=true` | Safari-specific AI states below remain unverified. Installed extension support alone does not establish a current browser workload. |
| Device management | No MDM enrollment; manually managed profile values nevertheless enforced | Declarative device-management controls cannot simply be pasted into the existing `.mobileconfig`. |

### States not established by this audit

These are explicit gaps, not assertions that the feature is on or off. During
the initial inspection, System Settings had a pending profile-install dialog;
it was preserved. The follow-up below confirms RemoveMacAI's values are now
enforced. Inactive apps
were not launched to generate a new workload. No messages, photos, browsing
history, or shortcut script contents were used to infer feature state.

| Feature / group | Why unresolved / next precise check |
| --- | --- |
| Safari tab topics, Notify Me monitors, AI-created extensions | No reliable explicit topic-mode value or monitor/extension inventory established. Inspect Safari → Settings → Tabs → Organize tabs; review monitors and Extensions. Daily telemetry timestamps are not proof a feature is enabled. |
| Siri per-app learning / Call Context | Main Siri off does not establish per-app learning state. Inspect Siri → App Access for used apps. |
| Phone voicemail suggestions, screening, Hold Assist | No explicit values established. Inspect Phone → Settings → Calls. |
| Journal prompts | Group-container `showFollowupPrompts` absent. Inspect Journal → Settings → General → Get Writing Prompts. |
| Spotlight clipboard history | Effective `PasteboardHistoryEnabled` absent. `PasteboardHistoryVersion=3` is a schema version, not enablement. Inspect Spotlight → Results from Clipboard. |
| iPhone widgets / Live Activities / notifications | `remoteWidgetsEnabled` absent; live-activity policy not established. Inspect General → AirDrop & Continuity and Notifications → Allow notifications from iPhone. |
| Live Translation / Messages backgrounds and poll suggestions | Per-conversation/app settings not read. `translationd` had no running PID in the service sample; that is runtime evidence only. |
| Reminders Auto-Categorize, AI suggestions; Mail priority/categories | App/per-list state not read; summary restrictions are insufficient evidence. Inspect the app-specific controls listed below. |
| Focus Intelligent Breakthrough & Silencing | Per-Focus configuration not established. Inspect each Focus; notification summaries off is a different setting. |
| Generated subtitles, Live Captions, Vocal Shortcuts, Dim flashing lights | No complete effective-state mapping established. Inspect the relevant Accessibility panes; preserve features actually needed. |
| Expanded Sensitive Content Warning / Communication Safety | Policy not inspected. Preserve useful protection; no performance case established for removing it. |
| Photos Extend/Reframe/Clean Up and Xcode predictive completion | No separate disable status established. Generative editing is user-triggered; Xcode was not running in the process sample. Existing Spatial Photos restriction is not evidence these other features are disabled. |

## What the profile check proves

`just privacy-check` validates the restrictions and managed preferences in this
repository's generated profile. It does not enumerate every AI capability added
by macOS, verify every ordinary user preference, check app-specific databases, or
measure performance. A passing result is valuable but is not an "all AI off"
certificate. See [profile ownership and checker scope](nix-plist-manager.md).

Golden Gate's documented controls are per feature: Siri, app summaries, Mail
replies, Phone suggestions, Journal prompts, and Screen Time capabilities.
Apple's macOS 27 guide does not document the former single Apple Intelligence
switch as a universal disable mechanism. Therefore an old private preference
called `appleIntelligence` cannot alone establish that the new features below
are disabled. [Apple's macOS 27 disable guide](https://support.apple.com/en-euro/guide/mac-help/mchlb2e44f94/27/mac/27)

## RemoveMacAI profile comparison and follow-up

At approximately 14:00 PDT on 2026-10-14, the existing read-only checker passed
**28/28 values** from `~/Downloads/RemoveMacAI.mobileconfig`: **24 functional
settings and four application markers**. It also passed **19/19 values** from
the previously exported m0nix profile. Every value matched and reported
`CFPreferencesAppValueIsForced=true`. These are effective-value checks; shared
values do not identify which installed profile supplies enforcement.

The screenshots match RemoveMacAI's generated profile. Compared with the
Nix profile at that time, it shared 15 functional settings and added these nine:

| Additional settings | Live result | Meaning |
| --- | --- | --- |
| `com.apple.applicationaccess:allowAssistant`; `com.apple.assistant.support:Assistant Enabled`; `com.apple.Siri:StatusMenuVisible` and `VoiceTriggerUserEnabled` | All **false and forced** | Siri was already off through ordinary preferences; these add profile enforcement. |
| Five `com.apple.MobileAsset:DownloadServerBaseURLOverride-…` preferences for `UAF.FM.CodeLM`, `UAF.FM.GenerativeModels`, `UAF.FM.Visual`, `UAF.Photos.MagicCleanup`, and `UAF.Photos.SpatialPhotosRelive` (each asset name prefixed `com.apple.MobileAsset.`) | All forced to `https://127.0.0.1:9/removemacai-blocked/` | RemoveMacAI redirects these asset downloads to a local endpoint intended to fail. Preference enforcement is verified; actual download attempts were not tested. |

The `io.github.omlahore.removemacai` domain is application bookkeeping:
`ai=true` means the profile includes AI-disabling settings; `installed=true`
marks its presence; empty `kept` means no catalog features were exempted; empty
`tweaks` means no optional tweaks were selected. These markers should not be
copied into a Nix-owned profile merely to make RemoveMacAI report ownership.
[RemoveMacAI profile implementation](https://github.com/omlahore/RemoveMacAI/blob/e0d3faeef05f41896db9e0e6f92cd0ef9c2b3fa2/Sources/removemacai/Profile.swift),
[feature and asset catalog](https://github.com/omlahore/RemoveMacAI/blob/e0d3faeef05f41896db9e0e6f92cd0ef9c2b3fa2/Sources/removemacai/Catalog.swift)

The five URL overrides are internal asset-service preferences, not documented
Apple feature restrictions. Their presence does not establish that existing
model files were deleted, resident processes stopped, or every Golden Gate AI
feature disabled. No performance benefit or retry overhead was measured. The
Finder and Photos findings above therefore remain separate controls to review.
The Nix profile also contains four service restrictions absent from this
RemoveMacAI AI-only profile: Book Store, Game Center, Apple Music, and Spotlight
internet results. This follow-up changed documentation only.

The subsequent Nix migration now declares all nine additions, bringing the
generated profile to **28 functional settings**: all 24 from RemoveMacAI plus
the four service restrictions. App bookkeeping is omitted. The existing setup
and check recipes cover the expanded profile automatically. See
[migration steps and verification](nix-plist-manager.md); matching live values
while both profiles are installed does not establish independent Nix ownership.

## Photos change and Spotlight follow-up

At the user's request on 2026-10-14, Enhanced Visual Search was disabled live
and declared under `system.defaults.CustomUserPreferences` in
`machines/m0nix/darwin.nix`. Both locations now contain boolean false for
`IPXDefaultEnhancedVisualSearchEnabled`:

- The ordinary `com.apple.photos.shareddefaults` preference domain.
- `~/Library/Containers/com.apple.Photos/Data/Library/Preferences/com.apple.photos.shareddefaults.plist`.

The second location matters: its value remained true after the ordinary domain
was changed. A CoreFoundation read outside Photos only verified the ordinary
domain. Nix now writes both, deriving the sandbox path from the configured user.
No rebuild, activation, profile replacement, or photo deletion was performed.
Photos did not remain open long enough to verify the Settings checkboxes, so
the UI state, iCloud Photos, and Memories controls remain unverified.

This switch disables Enhanced Visual Search landmark matching, not every local
face/object/Memory task or iCloud sync. Apple's Photos settings document separate
iCloud and Memories controls, but no single switch that disables all background
analysis. The installed `com.apple.photoanalysisd` launch-agent definition
schedules separate analysis, featured-content, and search-donation tasks, many
requiring external power. No shared photo/media service was disabled.
[Enhanced Visual Search](https://support.apple.com/en-ca/122033),
[Photos settings](https://support.apple.com/en-au/guide/photos/-pht5156cc968/mac)

Spotlight indexing remains enabled on `/`, `/System/Volumes/Data`, and
`/System/Volumes/Preboot`. At approximately 14:16 PDT, two interval CPU samples
showed `spotlightknowledged.updater` at **4.4% and 5.4% of one CPU core**,
`mds` at 0.0%, and total CPU approximately 90% idle. This is measurable work,
not evidence of sustained overheating or a measured battery-runtime penalty.

The index is a local database of filenames, metadata, and searchable content.
It updates when files change and after software updates, even if the Spotlight
interface is never opened. Finder and other applications can depend on it;
Alfred explicitly uses the same metadata index. Shell tools such as `rg`, `fd`,
and `find` search independently. [Apple indexing explanation](https://support.apple.com/en-au/102321),
[Finder search](https://support.apple.com/en-nz/guide/mac-help/-mh15155/mac),
[Alfred dependency](https://www.alfredapp.com/help/troubleshooting/indexing/spotlight/)

Recommendation: if Finder/Alfred indexed file search is also unused, a
reversible trial disabling volume indexing is reasonable. Otherwise exclude
high-churn directories through Spotlight → Search Privacy first. Hiding result
categories is not equivalent to disabling indexing. Apple's guide warns that
whole-disk exclusions also affect update notifications, and Time Machine has
indexing requirements of its own. Do not promise that one volume switch stops
every app's Core Spotlight or semantic-analysis task. No Spotlight settings
were changed. [Apple exclusion guidance](https://support.apple.com/en-ie/guide/mac-help/mchl1bb43b84/27/mac/27)

## Release baseline

Sequoia already had Writing Tools, ChatGPT integration, Image Playground,
Genmoji, Clean Up, natural-language Photos search, notification and transcript
summaries, Smart Reply, and Reduce Interruptions. Sequoia 15.4 added Mail
categories and memory-movie creation. iPhone Mirroring, window tiling, Safari
Highlights, and Math Notes also predate Tahoe. Do not label these as Golden
Gate-only background work. [Sequoia release history](https://support.apple.com/en-us/120283)

Tahoe 26 added Liquid Glass, the Phone and Journal apps, Games/Game Overlay,
Live Activities from iPhone, expanded Spotlight actions and clipboard history,
Live Translation, intelligent Shortcuts and Mac automations, and more AI inside
Messages and Reminders. Golden Gate inherits these additions. [Apple's Tahoe
announcement](https://www.apple.com/uk/newsroom/2025/06/macos-tahoe-26-makes-the-mac-more-capable-productive-and-intelligent-than-ever/),
[Tahoe release history](https://support.apple.com/en-us/122868)

Golden Gate adds Siri AI and its standalone conversation app, visual queries
about screenshots, Write with Siri, Finder filename suggestions, new Safari AI
tools, generated shortcuts and calendar editing, new photo editing tools, and
generated/translated video subtitles. Liquid Glass receives refinements and a
tint slider. [Apple's Golden Gate overview](https://www.apple.com/os/macos/),
[Golden Gate app tour](https://apps.apple.com/us/mac/story/id6794000017)

## New Golden Gate features to check individually

The recommendation column is an assessment of expected usefulness and work
avoided, **not a measured speedup**. No Apple benchmark found quantifies idle
CPU or memory savings for these switches.

| Feature | Supported disable/control | Assessment |
| --- | --- | --- |
| Siri AI, conversations, personal context, actions through Spotlight | System Settings → Siri → Turn Off Siri. For restrictions: Screen Time → Content & Privacy Restrictions → Siri → Allowed Siri Version → Don't Allow Siri. | Keep off for this user's preference. Siri Classic is an alternative if basic voice commands are wanted. A running Siri-named process does not itself establish that conversational Siri is enabled. [Siri on/off](https://support.apple.com/en-ie/guide/mac-help/mchlb66b4ad6/27/mac/27), [Screen Time controls](https://support.apple.com/en-ke/guide/mac-help/z25xrnykpuln/27/mac/27) |
| Visual Intelligence on screenshots | Disable Siri AI; independently switch off Siri → Automatic Visual Look Up. Screenshot queries otherwise require invoking Siri or its screenshot shortcut. | Keep automatic lookup off if unused. User-triggered screenshot analysis is distinct from continuous capture; the guide does not describe an always-running screen analysis loop. [Visual Intelligence](https://support.apple.com/en-gb/guide/mac-help/iphmk4p88mkuky/27/mac/27), [Siri settings](https://support.apple.com/en-ie/guide/mac-help/mchl3fd7fc15/mac) |
| Write with Siri and new writing feedback | Siri off; Screen Time → Content & Privacy Restrictions → Siri → block Writing Assistance. Existing Writing Tools restriction remains relevant to the older feature. | Keep off. Do not infer that blocking older Writing Tools proves every Siri AI entry point is blocked. [Write with Siri](https://support.apple.com/en-lamr/guide/mac-help/ipho54eqrx4ms3j/27/mac/27) |
| Finder filename suggestions | Finder → Settings → General → deselect Suggest file names. | Good disable candidate: automatic suggestions at rename/save/edit are unnecessary for this workflow. Actual performance benefit unmeasured. No verified Nix preference key established by this research. [Finder settings](https://support.apple.com/guide/mac-help/change-finder-settings-on-mac-mchlp2803/mac) |
| Safari automatic tab topics | Safari → Settings → Tabs → Organize tabs → Never. | Good disable candidate if Safari is used. "Show Related Tabs" still requests recommendations; Never is the documented off choice. Little relevance while Safari is unused. [Safari Tabs settings](https://support.apple.com/en-euro/guide/safari/ibrw1045/27.0/mac/27) |
| Safari Notify Me website monitoring | Inspect any user-created monitors. Page menu → Notify Me is the setup entry; its dialog controls check frequency. Apple guide examined does not specify a global off switch or monitor-removal path. | Periodic checks are worth removing if configured and unwanted. Feature availability alone does not mean any monitor exists. Removal UI must be verified locally before prescribing an exact click. [Notify Me](https://support.apple.com/en-ie/guide/safari/ak35p2kk9h5r/27.0/mac/27) |
| Safari AI-generated extensions | Safari → Settings → Extensions → disable unwanted extensions. Creation begins in Page menu → Describe Extension. | Audit installed extensions, not merely AI creation availability. An enabled extension can repeatedly process webpages; Apple explicitly warns about extensions that slow browsing. [Extensions guide](https://support.apple.com/en-ie/guide/safari/sfri32508/27.0/mac/27) |
| Phone voicemail suggestions | Phone → Settings → Calls → Suggestions in Voicemail off. | Disable if unused. Distinct from voicemail transcription and screening. Benefit conditional on receiving voicemail. [Phone settings](https://support.apple.com/guide/phoneapp/change-phone-settings-on-mac-phn29b80f4/1.0/mac/27) |
| Phone Call Context and cross-app suggestions | System Settings → Siri → App Access → select app → disable Learn from this application and Show Siri Suggestions in application as desired. | Useful privacy/automation reduction if suggestions are unwanted. Apple says suggestions default on; local app access needs separate verification. Disabling Siri's voice activation does not prove these app settings changed. [App access controls](https://support.apple.com/en-euro/guide/mac-help/mchl31570551/27/mac/27), [Call Context](https://support.apple.com/en-by/guide/phoneapp/phn28c9d643a/mac) |
| Journal writing prompts | Journal → Settings → General → Get Writing Prompts off. | Disable if Journal is used without prompts. Mere installation of Journal is not evidence of an ongoing workload. [Apple AI disable guide](https://support.apple.com/en-euro/guide/mac-help/mchlb2e44f94/27/mac/27) |
| Generated shortcuts and natural-language Calendar/Reminders editing | Avoid invoking creation/edit requests; inspect Shortcuts automations separately. No universal local off toggle for all these generation features was established. | Mostly action-driven. Low priority unless automatic execution is configured. Do not invent `defaults` keys to make the checker green. [Productivity features](https://support.apple.com/guide/mac-help/apple-intelligence-stay-organized-dom122pp864g/27/mac/27) |
| Photos Extend, Reframe, expanded Clean Up | Tools appear after opening a photo → Edit → Tools. No individual supported local disable switch found in the cited guide. | Leave alone for performance unless actually used. These edits are explicitly invoked; presence of their buttons is not evidence of ongoing generation. Spatial Photos playback restrictions do not establish that Reframe/Extend are disabled. [Photo editing controls](https://support.apple.com/en-gu/guide/photos/pht13f0918f0/mac) |
| Generated and translated video subtitles | System Settings → Accessibility → Subtitles and Captioning: review Show automatically when languages don't match, Show when muted, Show on skip back. Disable automatic triggers if unwanted; do not select translated/generated tracks during playback. | Potential processing during video playback. Keep if needed for accessibility. Turning off automatic display is not proof that every media-analysis job is disabled. [Generated subtitles](https://support.apple.com/en-hk/guide/mac-help/mchlc1cb8d54/mac) |
| Expanded sensitive-content detection | System Settings → Privacy & Security → Sensitive Content Warning. Communication Safety for children lives under Screen Time. Golden Gate adds gore/violence detection to the older nudity protections. | Local image/video analysis occurs for supported content. Keep protection if useful; do not disable parental controls merely for speculative speed. Optional on an adult account, with no measured idle saving established. [Sensitive Content Warning](https://support.apple.com/en-nz/105071), [Communication Safety](https://support.apple.com/en-us/105069) |
| New Shortcuts triggers and editor summaries | Inspect notification/screenshot triggers in Shortcuts → Automation. Existing shortcuts can be automatically summarized when opened in the editor; no separate documented summary-off switch found. | A notification or screenshot trigger can turn ordinary activity into repeated work. Review configured automations before blaming an idle framework. [Shortcuts 27 changes](https://support.apple.com/en-us/149045) |

## Tahoe additions inherited by Golden Gate

| Feature | Supported disable/control | Assessment |
| --- | --- | --- |
| Liquid Glass and transitions | Accessibility → Display → Reduce transparency on. Accessibility → Motion → Reduce motion on. Appearance → Liquid Glass controls tint, not a documented performance mode. | Sensible visual simplification on an 8 GB Mac if acceptable. Compare WindowServer during the same task before/after. No promised RAM saving. [Display](https://support.apple.com/en-ie/guide/mac-help/unac089/27/mac/27), [Motion](https://support.apple.com/en-euro/guide/mac-help/mchla3c4f1da/mac), [Appearance](https://support.apple.com/en-gb/guide/mac-help/mchlp1225/27/mac/27) |
| Spotlight clipboard history | System Settings → Spotlight → Results from Clipboard off; Clear Clipboard History clears saved history. Older Tahoe UI calls this Clipboard Search. | Disable if another clipboard tool is already used or history is unwanted. Primarily privacy/duplication reduction; measurable performance benefit not established. [Spotlight settings](https://support.apple.com/en-md/guide/mac-help/mchl54d95e8a/mac) |
| Spotlight actions, suggestions, semantic/personal search | Keep ordinary local search. Disable unused result categories and Siri separately. Use Search Privacy for large disposable/generated folders only when indexing measurements justify it. | Do not disable Spotlight wholesale. Hiding a category is documented as changing results, not proof that its background indexing stops. Siri integration in 27 is separate from the useful local search UI. [Search categories](https://support.apple.com/en-mt/guide/mac-help/mchl3e00eae9/27/mac/27), [Spotlight behavior](https://support.apple.com/guide/mac-help/find-what-you-need-with-spotlight-mchlp1008/27/mac/27) |
| Messages Live Translation | Per conversation: contact/group header → Automatically Translate off. | Turn off where not needed. Translation runs on device, but only configured conversations require it. [Translation controls](https://support.apple.com/en-gb/guide/mac-help/mchl58dfbdba/mac) |
| FaceTime/Phone Live Translation and captions | During a call, More → Live Translation / Live Captions; leave off if unused. Also inspect Accessibility → Live Captions. | Relevant during calls, not a reason to remove calling services at idle. Apple explicitly says Live Captions uses additional power. Keep needed accessibility features. [FaceTime](https://support.apple.com/en-asia/guide/facetime/fctmcd23d9be/mac), [system captions](https://support.apple.com/en-ie/guide/mac-help/mchla0b36db8/27/mac/27) |
| Intelligent Shortcuts and automations | Shortcuts → Automation → inspect enabled entries. Remove unwanted trigger from the shortcut. Review actions such as Use Model, summarization, and image generation. | High priority only if a repeated trigger runs expensive work. An unused shortcut is not continuous inference. Automations synced from another device arrive disabled according to Apple. [Automations](https://support.apple.com/en-gu/guide/shortcuts-mac/apdfbdbd7123/10.0/mac/27), [sync behavior](https://support.apple.com/guide/shortcuts-mac/intro-to-automation-shortcuts-apd690170742/mac) |
| Reminders suggestions and Auto-Categorize | Select each list → File → deselect Auto-Categorize, preserving sections if desired. Reminders → Settings → Adding Reminders controls suggestions while adding items. | Disable optional categorization if unused. Per-list state cannot be inferred from one global AI preference. Do not delete sections manually to disable this: that can remove reminders. [Auto-Categorize](https://support.apple.com/guide/reminders/manage-sections-in-reminder-lists-remn14bf0e77/mac), [settings](https://support.apple.com/guide/reminders/change-reminders-settings-remn4a9a4fe6/mac) |
| Messages poll suggestions and generated backgrounds | Inspect Messages settings for available controls; existing Image Playground restriction covers its image-generation capability. No separate documented global poll-suggestion switch found. | Generated backgrounds are requested actions; poll suggestions can inspect active conversations. Report unverified states, not "off" based on message summaries alone. [Messages AI features](https://support.apple.com/en-mk/guide/mac-help/mchl00c5b2c3/mac) |
| Phone Call Screening, Hold Assist, Live Voicemail | Phone → Settings → Calls exposes Hold Assist Detection, Live Voicemail, Screen Unknown Callers, and Call Filtering. | Keep useful screening. These primarily act on calls, so disabling them is a weak idle-performance optimization. Call Context and voicemail suggestions above are separate. [Phone settings](https://support.apple.com/guide/phoneapp/change-phone-settings-on-mac-phn29b80f4/1.0/mac/27) |
| Live Activities from iPhone | System Settings → Notifications → Allow notifications from iPhone → Allow Live Activities from iPhone off. | Disable if unused; this removes a source of periodic UI updates. Does not require breaking Handoff or Universal Clipboard. Control appears after iPhone Mirroring setup. [Continuity notifications](https://support.apple.com/en-ie/120684) |
| Games app and Game Overlay | Keep unused Games app closed. In a full-screen game, Command-Escape → Game Overlay → Settings → Game Mode toggles per-game optimization. | Do not disable Game Mode for generic speed: it prioritizes the active game and exits with the game/fullscreen. Game Mode itself dates to Sonoma; the new overlay is Tahoe. Game Center restriction is separate. [Game Mode](https://support.apple.com/en-lamr/105118) |
| Foundation Models in third-party apps/widgets | Disable the specific app's optional AI/background features; remove unused widgets. No blanket guarantee from turning off Siri. | Framework availability alone is not CPU consumption. Apple confirms apps/widgets can run models in background and may be rate limited under load. Identify the requesting app before suppressing a shared service. [Apple engineering discussion](https://developer.apple.com/videos/play/wwdc2026/8016/) |

## Older features still relevant to an AI/performance audit

| Feature | Control and recommendation |
| --- | --- |
| Enhanced Visual Search in Photos | Already present in Sequoia. Photos → Settings → General → Enhanced Visual Search off if landmark search is unwanted. Apple describes local embedding generation and privacy-preserving server matching. This is separate from Siri Automatic Visual Look Up and does not disable all Photos analysis. [Apple explanation](https://support.apple.com/en-ca/122033) |
| Photos people/pets, duplicates, memories, search and library sync | Distinguish background library analysis from generative editing. No supported all-analysis kill switch established. Keep normal library services; investigate sustained CPU and whether a library import/sync is underway before changing them. Photos deliberately organizes memories and supports a system library with iCloud updates. [Photos guide](https://support.apple.com/guide/photos/welcome/mac), [system library](https://support.apple.com/guide/photos/photo-library-overview-pht211de786/12.0/mac/27) |
| Focus Intelligent Breakthrough & Silencing | System Settings → Focus → select each Focus → turn this feature off if unwanted. Reduce Interruptions always enables it, so use a conventional Focus instead. Notification-summary restrictions do not prove this classifier is off. [Focus controls](https://support.apple.com/en-ge/guide/mac-help/mchl613dc43f/mac) |
| Mail priority and categories | These predate Golden Gate. Summary/smart-reply restrictions do not automatically mean classification is disabled. Inspect Mail's own category/priority controls; hiding a view is not sufficient proof that background classification stops. [Sequoia history](https://support.apple.com/en-us/120283), [current AI productivity guide](https://support.apple.com/guide/mac-help/apple-intelligence-stay-organized-dom122pp864g/27/mac/27) |
| Desktop and Notification Center widgets | Remove unused widgets via their context menu → Remove Widget. Desktop & Dock → Widgets controls desktop visibility and iPhone widgets. Hiding desktop widgets does not establish that Notification Center widgets were removed. Prefer removing unused widgets over disabling WidgetKit services. [Widget controls](https://support.apple.com/en-gb/guide/mac-help/mchl52be5da5/mac) |
| Aerial/video wallpapers and screen savers | System Settings → Wallpaper → choose a still picture or color. Wallpaper → Screen Saver changes the saver; Lock Screen controls display-off timing. Aerial wallpaper animates on lock/unlock and in its saver, so do not describe every aerial desktop as continuously playing video. [Wallpaper behavior](https://support.apple.com/en-ng/guide/mac-help/mchlp3013/mac), [screen saver](https://support.apple.com/en-ie/guide/mac-help/mchl4b68853d/27/mac/27) |
| iPhone Mirroring and ordinary iPhone notifications | Sequoia features. Turn unwanted mirroring notifications off in Notifications → Allow notifications from iPhone. Remove Mac pairing from iPhone → Settings → General → AirPlay & Continuity → iPhone Mirroring if entirely unused. Keep Handoff if Universal Clipboard is wanted. [Mirroring](https://support.apple.com/en-us/120421) |
| Accessibility audio/video processing | Inspect Live Captions, Voice Control, Vocal Shortcuts, and Motion → Dim flashing lights. Turn off only unused features. New generated subtitles are distinct from pre-existing captions; Dim flashing lights processes compatible media in real time. Vehicle Motion Cues is unavailable on M1 MacBook Air, so it is not a candidate on this machine. [Motion capabilities](https://support.apple.com/en-euro/guide/mac-help/mchla3c4f1da/mac), [Live Captions](https://support.apple.com/en-ie/guide/mac-help/mchla0b36db8/27/mac/27) |
| Password security recommendations | Keep Detect Compromised Passwords enabled in Passwords → Settings. This useful monitoring predates Golden Gate. No supported evidence found that disabling it addresses this slowdown; reports of AI-assisted password changes do not establish constant password-generation work. [Password recommendations](https://support.apple.com/en-ie/guide/passwords/mchl506a0d14/mac) |

## Recommended order

1. For battery runtime, investigate the **77% capacity / Check Battery** finding.
   Keep Low Power Mode. Reduced capacity is confirmed; an AI-caused drain is not.
2. Disable unwanted Finder filename suggestions and Photos Enhanced Visual
   Search. Enable Reduce Motion. These are confirmed states with clear controls,
   but their performance benefits have not been measured.
3. Consider a still wallpaper; remove unused widgets. Expected battery benefit
   is limited when the display already sleeps before the aerial saver starts.
4. Resolve remaining automatic-feature states: Safari topics/monitors, per-app
   learning, Focus classification, generated subtitles, Journal prompts, and
   Phone suggestions. Avoid treating missing preference keys as off.
5. Compare actual CPU, memory pressure, swap rate, and app activity during the
   reported slowdown, with the same browser tabs, display, and interaction.
   The sampled system was not CPU-saturated. Browser/app workload deserves at
   least as much attention as unused generative-editing buttons.
6. Keep the 19 enforced settings, useful local search, photo-library services,
   iCloud synchronization, security updates, and Game Mode. Do not boot out
   shared Apple daemons or delete model caches without a measured reason.

## Declarative configuration limits

Use nix-plist-manager where the pinned module actually owns a supported
preference. Use `system.defaults.CustomUserPreferences` only after identifying
the real domain/key/type and checking the live effective value. An arbitrary
`defaults write` succeeds even if no application reads that key.

Keep profile payloads in Nix and derive the existing checker from the generated
profile. Documented Apple user-interface controls without a verified preference
mapping should remain explicit manual checks. App databases, per-conversation
translation, per-list categorization, and Shortcuts triggers need their own
checks; a generic CFPreferences loop cannot prove their state.

The profile format and per-domain enforcement requirements remain documented in
[nix-plist-manager.md](nix-plist-manager.md). Do not silently substitute a
declarative-device-management declaration for a manually installable profile.

### Verified Nix mappings for a later change

Checked against locked nix-plist-manager `4ef635b8` and nix-darwin `4cff07de`.
These are proposals, **not applied changes**. Paths in the table are relative
to `programs.nix-plist-manager.options.applications`.

| Feature | Declaration | Important boundary |
| --- | --- | --- |
| Reduce Motion | `systemSettings.accessibility.motion.reduceMotion = true;` | Writes both accessibility domains, with the correct integer/boolean types. [Pinned source](https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/systemSettings/accessibility.nix#L366) |
| Spotlight clipboard history | `systemSettings.spotlight.resultsFromClipboard = false;` | Writes `com.apple.Spotlight:PasteboardHistoryEnabled=false`. Current state still unverified. [Pinned source](https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/systemSettings/spotlight.nix#L67) |
| Desktop widgets | `systemSettings.desktopAndDock.widgets.showWidgets.onDesktop = false;` | Hides desktop widgets; does not remove Notification Center widgets. Optional `inStageManager=false` exists too. [Pinned source](https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/systemSettings/desktop-and-dock/widgets.nix) |
| iPhone widgets | `systemSettings.general.airDropAndContinuity.iPhoneWidgets = false;` | Writes `com.apple.chronod:remoteWidgetsEnabled=false`; activation restarts `chronod`. [Pinned source](https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/systemSettings/general/airdrop-and-continuity.nix#L42) |
| Still wallpaper / no saver | `systemSettings.wallpaper.color = "Black";` and `systemSettings.wallpaper.startScreenSaver = "Never";` | Photo alternative exists. WallpaperAgent store and ByHost screen-saver settings require their own checks. [Pinned source](https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/systemSettings/wallpaper.nix#L229) |
| Journal prompts | `journal.getWritingPrompts = false;` | Writes `showFollowupPrompts=false` to the Journal group-container plist; ordinary domain reads can miss this location. [Pinned source](https://github.com/SushyDev/nix-plist-manager/blob/4ef635b8b2f4c88929ea7d1a8a941acbab5de719/lib/options/applications/journal.nix#L23) |

Photos Enhanced Visual Search has no typed option in either locked module.
It is now declared through `system.defaults.CustomUserPreferences` for both the
ordinary domain and Photos' sandbox path in `machines/m0nix/darwin.nix`.
Both were set false live; the Settings UI could not be verified. This is a
private preference mapping, not a documented Apple management key.
Finder's checkbox identifier `SuggestNamesCheckBox` is an accessibility ID,
not a preference key. Its binary's `__suggestFileNames` string did not have a
readable value in Finder or global preferences; no write command is justified.
Siri per-app learning likewise has no verified declarative mapping here.

## Verification gaps

This research establishes feature availability and documented controls. It
does not establish that every feature is currently enabled, that a missing
preference means disabled, or that every proposed change saves CPU/RAM.
Public Apple sources examined provide no comprehensive per-feature idle-cost
table. No shutdown command, model deletion, preference write, activation, or
build was performed for this research.

The inventory covers relevant AI and system additions with observed states and
explicit gaps; it does not certify every new feature disabled. No controlled
Sequoia-versus-Golden-Gate benchmark, overnight battery study, or before/after
toggle experiment was performed. Recheck after updates and during the actual
heat/drain episode. Use Activity Monitor's Energy tab for longer-running app
comparisons; the short CPU sample is not an energy measurement.

Verification performed: current profile check; effective CFPreferences reads;
Finder checkbox inspection through native accessibility; scoped preference and
wallpaper-store reads; aggregate, read-only Shortcuts metadata; four `top`
samples (first discarded for interval CPU); `ps`, `vm_stat`, `memory_pressure`,
`sysctl`, `pmset`, `df`, `mdutil`, and filtered System Information reports.
No broad service disabling, cache deletion, app removal, or profile installation.
