**Product Requirements Document (PRD): TimeTank**

## 1. Executive Summary

**Product Name:** TimeTank

**Platform:** iOS (Native)

**Core Value Proposition:** A premium, high-performance screen time utility that replaces rigid app blockers with flexible daily budgets, granular whitelisting, and a visceral 2D visual feedback loop (the "Focus Bowl").

**Target Aesthetic:** Dark mode, data-rich, professional, vector-based design (no cartoons or 3D mascots).

## 2. The Technology Stack End-to-End

This build completely avoids cross-platform wrappers to ensure deep system-level integration and zero battery drain.

### Application Layer (Frontend)

- **Language:** Swift
    
- **UI Framework:** SwiftUI
    
- **Graphics & Animation Engine:** SwiftUI `Canvas` and `Core Graphics`.
    
    - _Usage:_ To mathematically render the 2D circular fishbowl, the vector fish, and the dynamic "pollution" fluid level. This ensures smooth 60fps performance with a negligible memory footprint.
        
- **State Management:** `@Observable` (Swift's native reactive macros) and `@Environment` for seamless UI updates when screen time data shifts.
    

### System Integration Layer (Apple Screen Time APIs)

These native Apple APIs are strictly required to intercept app usage without running heavy background polling tasks.

- **FamilyControls (`AuthorizationCenter`):** For requesting the required `com.apple.developer.family-controls` entitlement and obtaining individual user authorization via FaceID or Passcode.
    
- **ManagedSettings (`ManagedSettingsStore`):** The enforcement layer. Used to apply UI "shields" (our custom speed bumps) over specific distraction apps based on the user's generated tokens.
    
- **DeviceActivity (`DeviceActivityMonitor`):** The event-driven trigger. Used to define the user's daily budget schedules. It wakes the app extension silently in the background _only_ when a time threshold is breached, guaranteeing extremely low battery consumption.
    

### Data & Persistence Layer

- **Database:** SwiftData
    
    - _Usage:_ Fast, local, on-device storage for time budgets, app tokens, unified focus metrics, and unlocked marketplace items (plants, fish silhouettes).
        
- **App Extension Sync:** UserDefaults / App Groups
    
    - _Usage:_ Sharing critical state data (like the current pollution level) between the main application and the strict 6MB memory limit of the `DeviceActivityMonitor` extension.
        

### DevOps, Security & Infrastructure

To maintain a professional, reliable deployment pipeline:

- **CI/CD Pipeline:** GitHub Actions. Automated workflows to run unit tests and deploy builds directly to TestFlight.
    
- **Security Auditing:** CodeQL integration within the repository to automatically scan Swift code for vulnerabilities before App Store submission.
    
- **Cloud Infrastructure:** Google Cloud. Only utilized if secure, anonymous analytics tracking or a remote config architecture is needed to adjust app behavior post-launch without requiring an app update.
    

## 3. Core Mechanics & Implementation Logic

### 3.1 Granular Whitelisting & Budgets

- **The User Flow:** Onboarding utilizes the `FamilyActivityPicker`. The user explicitly selects only the distraction apps (e.g., TikTok, Instagram). Utilities like Maps or authenticators are ignored entirely.
    
- **The Logic:** The user assigns a global "Time Budget" for the selected group. The `DeviceActivity` schedule is initialized to track only those specific tokens.
    

### 3.2 The "Speed Bump" Intercept

- **The Trigger:** When `DeviceActivity` detects that the time budget is exhausted, it signals `ManagedSettings` to drop a shield over the selected apps.
    
- **The UI:** Instead of a hard lockout, the custom Shield UI presents the "Mindful Pause" screen. The user can choose to bypass the shield, which immediately triggers a state change in the shared App Group data.
    

### 3.3 The 2D Fishbowl Dynamics (The "Pain")

- **Healthy State:** SwiftUI `Canvas` draws a smooth, dark blue gradient arc. The vector fish is animated along randomized, overlapping bezier paths (`Path`).
    
- **Pollution State:** If the app extension registers a shield bypass, SwiftData logs the deficit. The UI dynamically shifts the Canvas gradient to a harsh, dark hue and animates a black "fill" rising from the bottom of the bowl using a mathematical sine wave to simulate the fluid surface.
    

### 3.4 The "Currents" Economy

- **Earning:** A background task evaluates the user's success at local midnight. If the budget was respected, the local SwiftData model increments the `currentsBalance`.
    
- **Spending:** The UI presents a minimalist marketplace. Unlocking a new asset updates the active `EcosystemModel`, instructing the Canvas to render the new vector assets inside the bowl environment.
    

## 4. Development Phases

|**Phase**|**Milestone**|**Focus Areas**|
|---|---|---|
|**Phase 1**|OS Hooks & Entitlements|Configure Xcode capabilities. Obtain the `FamilyControls` entitlement. Build the `FamilyActivityPicker` onboarding flow.|
|**Phase 2**|Event-Driven Interception|Implement `DeviceActivityMonitor` extensions. Configure `ManagedSettings` shields. Ensure App Group data syncs correctly under extension memory limits.|
|**Phase 3**|The Vector Ecosystem|Build the SwiftUI `Canvas` rendering engine. Design the fluid math, fish behavior logic, and the dynamic color-shifting tied to the budget states.|
|**Phase 4**|Data & Progression|Integrate SwiftData. Build the daily evaluation logic, the unified score algorithm, and the marketplace UI.|
|**Phase 5**|Audit & Deployment|Run CodeQL audits via GitHub Actions. Deploy to TestFlight. Refine vector paths for maximum rendering performance.|


This is exactly how we build it. To ensure this passes strict security auditing like CodeQL and integrates cleanly into an automated GitHub Actions pipeline, the logic must be hyper-modular. We are strictly separating the heavy UI rendering in the main app from the lightweight, memory-constrained logic in the app extensions.

Here is the exact, end-to-end logic stack for **TimeTank**.

### 1. The Shared Data Layer (The Nervous System)

Apple’s architecture dictates that the main app and the background extensions run in completely separate sandboxes. The extension only gets ~6MB of memory.

**Logic Flow:**

- Create an **App Group** (e.g., `group.com.yourname.timetank`).
    
- Initialize a shared `UserDefaults` instance using this suite name.
    
- **Key Variables Stored Here:**
    
    - `selectedDistractionApps` (The user's specific tokenized selection).
        
    - `dailyBudgetMinutes` (Integer).
        
    - `pollutionLevel` (Float, from 0.0 to 1.0).
        
    - `currentsBalance` (Integer, the currency).
        

### 2. The Main App: Authorization & Setup

This is where the user interacts, sets their budget, and views their ecosystem.

**Logic Flow:**

- **On Launch:** Call `AuthorizationCenter.shared.requestAuthorization(for: .individual)`.
    
- **The Picker:** Present the native `FamilyActivityPicker`. The user selects TikTok, Instagram, etc.
    
- **Save Tokens:** Store the generated `FamilyActivitySelection` into the shared App Group.
    
- **Schedule Creation:** Configure a `DeviceActivitySchedule`.
    
    - Set the schedule interval from `00:00` to `23:59`.
        
    - Create a `DeviceActivityEvent` with a threshold equal to the user's `dailyBudgetMinutes`.
        
- **Initialization:** Call `DeviceActivityCenter.shared.startMonitoring(...)` passing in the schedule and the event.
    
- _Result:_ The main app now goes to sleep. It does zero background polling.
    

### 3. The Monitor Extension: Event-Driven Interception

This extension runs silently in the background and is only woken up by the iOS system when specific events occur.

**Logic Flow (`DeviceActivityMonitor`):**

- **`intervalDidStart`:** Fires at midnight. Logic: Read `pollutionLevel`. If `pollutionLevel == 0`, increment `currentsBalance` by 1. Reset `pollutionLevel` to 0. Clear any active shields.
    
- **`eventDidReachThreshold`:** Fires the exact millisecond the user hits their 45-minute TikTok limit.
    
    - Logic: Instantiate `ManagedSettingsStore()`.
        
    - Apply the shield: `store.shield.applications = sharedTokens`.
        
    - _Result:_ The user is immediately blocked with our custom UI the next time they open the app. The extension immediately terminates to save battery.
        

### 4. The Shield Extension: The "Speed Bump" & Bypass

This is where the psychological friction happens. We replace Apple's default "Time Limit Reached" screen with our dark-mode "Mindful Pause."

**Logic Flow (`ShieldConfigurationDataSource`):**

- Return a custom configuration. No sad mascots. Just stark typography: _"Your budget is spent. Bypassing will pollute the Current."_
    
- Provide two buttons: "Close App" (Primary) and "Ignore Limit" (Secondary).
    

**Logic Flow (`ShieldActionDelegate`):**

- **Handle "Close App" Tap:** Call `defer` to keep the shield active. The user walks away; the tank stays clean.
    
- **Handle "Ignore Limit" Tap:**
    
    - 1. Call `ManagedSettingsStore().shield.applications.remove(...)` to unblock the app.
            
    - 2. Update the shared state: `sharedDefaults.set(pollutionLevel + 0.2)`.
            
    - 3. _Crucial:_ Set a new micro-schedule in `DeviceActivityCenter` for 15 minutes. When that 15 minutes hits, the shield drops again, and if they bypass _again_, the pollution level increments further.
            

### 5. The Rendering Engine: The 2D Fishbowl (Main App UI)

When the user opens the main app, it reads the data from the App Group and renders the visual consequences.

**Logic Flow (SwiftUI `Canvas`):**

- **State Observation:** The view observes the `@AppStorage("pollutionLevel")` variable.
    
- **The Environment Rendering:**
    
    - Draw the base geometry: A rounded-rectangle or circular vector path with a thin 1px stroke.
        
    - **The Fluid Dynamics:** Use a `Path` with a sine wave function `y = A * sin(B * x + C) + D` to draw the water line.
        
    - **The Pollution Modifier:** The `pollutionLevel` dictates two things:
        
        1. _Gradient Shift:_ `Color.blue.blend(with: .black, percentage: pollutionLevel)`.
            
        2. _Fluid Height:_ The `D` variable in the sine wave drops lower or fills with dark vector shapes as the level increases.
            
- **The Entity Logic:**
    
    - The vector fish moves via a recurring `.onReceive(Timer)` that updates its X/Y coordinates based on random bezier control points.
        
    - _The Pain Mechanic:_ If `pollutionLevel > 0.5`, the timer slows down. The fish's animation duration increases, visually representing the struggle within the polluted ecosystem.
        

By strictly decoupling the `DeviceActivity` state logic from the SwiftUI `Canvas` rendering, you completely bypass the 6MB memory crash limit that plagues competitors, ensuring your app remains a lightweight, high-performance utility.

While the PRD is technically sound, there are a few critical "blind spots" in the iOS Screen Time development process that can completely derail a successful MVP if you aren't prepared for them.

Here are the missing elements required for a successful launch.

### 1. The Apple Entitlement Bureaucracy (Do This Now)

You cannot simply build an app using Screen Time APIs and ship it. You must apply for the `FamilyControls` entitlement directly from Apple, which requires a manual review process.

- **The Launch Blocker:** Developers have reported waiting weeks with pending distribution entitlement requests, effectively missing their launch windows. Apply for this entitlement immediately, even before the MVP is finished.
    
- **API Justification:** Apple now strictly enforces that you include an approved reason for utilizing these specific APIs. Your application must clearly articulate that you are building a productivity/screen-time tool.
    

### 2. The 6MB Extension Limit (The "Ghost Block" Culprit)

The PRD touches on keeping the App Extension lightweight, but you must architect your code around a hard ceiling.

- **The Constraint:** The `DeviceActivityMonitor` extension has an incredibly strict memory limit of 6MB.
    
- **The Risk:** If you attempt to initialize heavy frameworks (like a CoreData context or complex SwiftUI views) inside the monitor, iOS will instantly kill the process due to memory pressure. Rely exclusively on `UserDefaults` for passing data between the main app and the extension.
    

### 3. The 20-Schedule Limit

Because we are utilizing a dynamic budget approach, we must be careful with how we schedule the background monitoring.

- **The Constraint:** iOS only allows you to register approximately 20 to 21 monitoring activities or schedules before throwing system errors.
    
- **The Solution:** Do not allow users to create an infinite number of highly specific, individual app budgets. Group their selected apps into a single "Distractions" bucket with one unified schedule to ensure you stay well below the system limit.
    

### 4. Monetization (StoreKit Integration)

Our App Store copy promises "Honest Pricing," meaning we need a paywall built into the MVP to actually process that revenue.

- **The Setup:** Implement Apple's StoreKit 2 natively, or use a wrapper like RevenueCat to handle the receipt validation and unlock the premium marketplace items (like unique fish silhouettes or midnight themes).
    
- **Business Registration:** As you transition this from code to a launched product, ensure your App Store Connect developer account is registered under a digital business entity—like SplashShopUS LLC—rather than your personal name. This shields you from liability and establishes a premium presence on the App Store.
    

Here is the exact, comprehensive prompt you can feed directly into an AI coding agent (like Cursor, Claude, or ChatGPT) to build the complete MVP. It includes all the strict architectural constraints needed to survive Apple’s ecosystem in 2026.

Copy and paste everything below the line.

**System Prompt: iOS Native App Build – "TimeTank" (Screen Time Utility)**

You are an expert, senior iOS developer specializing in Swift, SwiftUI, and Apple's Screen Time APIs (`FamilyControls`, `ManagedSettings`, `DeviceActivity`).

Your task is to build the MVP for an iOS app called **TimeTank**, a premium screen time utility that replaces rigid app blockers with flexible daily budgets and a 2D visual feedback loop (the "Focus Bowl").

### 1. App Architecture & Project Configuration

- **Language:** Swift
    
- **UI Framework:** SwiftUI
    
- **App Group:** Create an App Group identifier (e.g., `group.com.splashshopus.timetank`) to share `UserDefaults` data between the main app and the extensions.
    
- **Entitlement:** The app requires the `FamilyControls` (Distribution) entitlement. The developer will submit the request to Apple under the SplashShopUS LLC developer account.
    
- **CI/CD & Security:** Configure the repository with GitHub Actions for automated TestFlight deployments and integrate CodeQL for automated Swift security auditing. Backend analytics or remote config will run on Google Cloud.
    

### 2. The Strict Extension Constraints (CRITICAL)

You must adhere to the following limitations when writing the extension logic. If you violate these, the iOS system will kill the app extensions instantly.

- **The 6MB Memory Limit:** The `DeviceActivityMonitor` extension is strictly limited by Apple to 6MB of RAM.
    
- **No Heavy Frameworks:** You must NOT initialize SwiftData, CoreData, or heavy UI components inside the `DeviceActivityMonitor`.
    
- **Data Passing:** All communication between the main app and the monitor extension must happen exclusively through the shared App Group `UserDefaults`.
    
- **Token Stability:** Be aware of token stability issues when fetching from `FamilyActivityPicker`; handle missing or changed tokens gracefully to prevent blank shield screens.
    

### 3. Core Logic Requirements

**Module 1: Authorization & Onboarding (Main App)**

- On launch, request `.individual` authorization via `AuthorizationCenter.shared`.
    
- Implement `FamilyActivityPicker` to allow users to select their specific distraction apps. Store the `FamilyActivitySelection` in the App Group `UserDefaults`.
    
- Provide a SwiftUI interface to set a `dailyBudgetMinutes` (Integer).
    

**Module 2: Event-Driven Monitoring (`DeviceActivityMonitor`)**

- Create a `DeviceActivitySchedule` that runs from 00:00 to 23:59.
    
- Set a `DeviceActivityEvent` threshold equal to `dailyBudgetMinutes`.
    
- In `intervalDidStart` (midnight): Read the `pollutionLevel` (Float) from `UserDefaults`. If 0.0, increment `currentsBalance` (Integer) by 1. Reset `pollutionLevel` to 0.0. Clear active shields.
    
- In `eventDidReachThreshold`: Instantiate a `ManagedSettingsStore` and apply a shield to the stored tokens. Immediately terminate to save memory and battery.
    

**Module 3: The Custom Shield (`ShieldConfiguration` & `ShieldAction`)**

- Design a minimalist, dark-mode `ShieldConfiguration`. Text: _"Your budget is spent. Bypassing will pollute the TimeTank."_ Two buttons: "Close App" (Primary) and "Ignore Limit" (Secondary).
    
- In `ShieldActionDelegate`:
    
    - If "Close App": `defer` the action (keep the shield).
        
    - If "Ignore Limit": Remove the app from `ManagedSettingsStore().shield.applications`. Add `0.2` to the `pollutionLevel` in `UserDefaults`. Set a new 15-minute micro-schedule in `DeviceActivityCenter` to drop the shield again.
        

**Module 4: The 2D Fishbowl UI (Main App)**

- Use SwiftUI `Canvas` to render a minimalist, vector-based circular fishbowl.
    
- **The Fish:** Draw a geometric vector path of a fish. Animate it moving continuously using a `Timer` and randomized bezier control points.
    
- **The Water/Pollution:** Use `@AppStorage("pollutionLevel")` to drive the canvas.
    
    - Draw the water surface using a sine wave function: `y = A * sin(B * x + C) + D`.
        
    - As `pollutionLevel` increases (from 0.0 to 1.0), lower the `D` value (raising the dark water level) and shift the gradient from oceanic blue to stark, high-contrast black/yellow.
        
    - If `pollutionLevel > 0.5`, dynamically increase the duration of the fish's animation to simulate sluggish movement.
        

**Execution Instructions:**

Begin by providing the complete Swift code for the **Shared App Group Data Model** and the **`DeviceActivityMonitor` Extension**, ensuring strict compliance with the 6MB memory limit.

Your Prompt:

You are a senior iOS engineer and Apple platform specialist with deep expertise in Screen Time APIs, Family Controls, and Swift development as of 2025–2026. I want you to research and synthesize the absolute best practices for building a Screen Time app for iOS using Swift, targeting the current and upcoming Apple ecosystem standards for 2026.

Investigate and cover the following areas with precision:

**API & Framework Usage**

- The correct, current way to implement `FamilyControls`, `ManagedSettings`, and `DeviceActivity` frameworks
- Any deprecations, replacements, or breaking changes introduced in recent iOS versions (iOS 17, 18, and any iOS 19 beta guidance)
- Entitlements and provisioning requirements specific to Screen Time apps (Family Controls entitlement, App Groups, etc.)

**Architecture & Code Structure**

- Recommended Swift and SwiftUI patterns for Screen Time apps (e.g., how to correctly structure the app extension vs. main app target)
- How to properly handle the `DeviceActivityMonitor` extension and avoid common lifecycle pitfalls
- Best practices for managing shared state between the main app and app extensions using App Groups

**Authorization & Privacy**

- The correct authorization flow for `AuthorizationCenter.shared.requestAuthorization(for:)` and how to handle edge cases (denial, parental approval, re-authorization)
- Privacy-sensitive data handling requirements Apple enforces for Screen Time apps

**Error Minimization**

- The most common runtime errors, crashes, and App Store rejection reasons specific to Screen Time apps — and how to prevent each one
- Correct entitlement configuration to avoid silent failures (a major source of bugs in this category)
- Testing strategies for Screen Time functionality, including simulator limitations and recommended device testing approaches

**App Store Compliance**

- Current App Store Review Guidelines that specifically affect Screen Time apps
- Required usage descriptions, entitlement justifications, and review notes Apple expects

Synthesize your findings into actionable, specific guidance — prioritize correctness and error prevention over general advice. Where Apple's documentation is known to be incomplete or misleading, flag it and provide the community-validated workaround. Reference the most current Swift and Xcode versions applicable for a 2026 release target.