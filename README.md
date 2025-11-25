# 📺 Streaming Metadata Extractor (iOS – SwiftUI)

An iOS app built with SwiftUI that extracts metadata from streaming services using **non-public internal APIs**, authenticated WebView sessions, and **JavaScript injection**.

---

## 🚀 Features

- 🔐 Built-in **WebView login** for real streaming platforms  
- 📄 **Metadata extraction** from any video page:
  - Title  
  - Description  
  - Video ID  
  - Series / Season / Episode  
  - Release date  
  - Image URLs  
- 🧩 **JavaScript injection** to read:
  - JSON-LD (`application/ld+json`)
  - OpenGraph `<meta>` tags  
  - Twitter card metadata  
- 🍪 **Cookie extraction** from WKWebView  
- 🌐 **Call private/internal APIs** using cookies (no API keys required)  
- 📝 **Logs panel** & **raw JSON viewer**  
- 🖼️ **Image preview sheet**  
- 🔍 Expandable full-screen WebView  
- 🎨 Clean and responsive SwiftUI interface  

---

## 📸 Screenshot

<img width="250" height="600" alt="simulator_screenshot_4A2FF928-9526-42D5-9218-E6976B93F738" src="https://github.com/user-attachments/assets/d2782562-5212-44fa-adca-8ecf9d10d118" />

---

## 🛠 How It Works

### 1️⃣ Login Inside WebView  
Sign in to the streaming service inside the embedded WebView.  
Session cookies are stored automatically.

### 2️⃣ Browse Any Video Page  
Open any streaming site or video URL directly inside the app.

### 3️⃣ Extract Metadata  
Tap **Extract Metadata** → JavaScript extracts metadata from:
- JSON-LD blocks  
- OG meta tags  
- Twitter metadata  
- HTML attributes  
- URL patterns  

### 4️⃣ Copy Cookies & Call Private API  
Tap **Copy Cookies** → the app generates a valid `Cookie:` header.  
Paste an internal/private API URL (observed from devtools) and tap **Call Endpoint**.  
Response metadata is parsed and displayed.

---

## ⚠️ Disclaimer

This project does **not** bypass DRM or protected content.  
It uses:
- Your authenticated session  
- Metadata already exposed by the streaming service  
- API endpoints visible in browser network logs  

Use only with accounts you own.

---

## 📦 Installation

1. Clone the repository  
2. Open `.xcodeproj` in Xcode  
3. Build & run on iOS 15+  


