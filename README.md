App Glimpse :

<div align="center">

<img src="https://github.com/user-attachments/assets/dfcac47d-610a-4ab0-8992-698878a6cf2f" width="23%" />
<img src="https://github.com/user-attachments/assets/66483d58-e30f-4949-a4f9-060309134dc3" width="23%" />
<img src="https://github.com/user-attachments/assets/4165fcec-f2d8-4566-b3f3-cf8c127a63f2" width="23%" />
<img src="https://github.com/user-attachments/assets/1b45002f-497d-4800-b078-3291643c775a" width="23%" />

<br/><br/>

<img src="https://github.com/user-attachments/assets/1a4c8392-a4c0-4051-a377-4eae590c151d" width="23%" />
<img src="https://github.com/user-attachments/assets/0cde660a-f933-4424-8a9d-34bc13d103d0" width="23%" />
<img src="https://github.com/user-attachments/assets/484a8082-f9e2-475a-943a-9610f08eb7ab" width="23%" />

</div>

```
 ██████╗ █████╗ ██╗      ██████╗      █████╗ ██╗
██╔════╝██╔══██╗██║     ██╔═══██╗    ██╔══██╗██║
██║     ███████║██║     ██║   ██║    ███████║██║
██║     ██╔══██║██║     ██║   ██║    ██╔══██║██║
╚██████╗██║  ██║███████╗╚██████╔╝    ██║  ██║██║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝     ╚═╝  ╚═╝╚═╝
```

### 🥗 AI-Powered Calorie & Nutrition Tracker

**Snap a photo → Get instant nutrition data → Track your goals**

*Built for Indian food lovers. Powered by Mistral AI Vision.*

<br/>

[![Download](https://img.shields.io/badge/Download_APK-Latest-C1FF72?style=for-the-badge&logo=android&logoColor=black)](https://github.com/lalit127/calo_ai/releases)
[![Backend](https://img.shields.io/badge/Live_API-Railway-success?style=for-the-badge&logo=railway)](https://web-production-4b65.up.railway.app/docs)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

</div>

---

## ✨ What is Calo AI?

Calo AI is a **full-stack mobile nutrition tracker** that uses computer vision to identify food from photos and instantly calculate calories, macros, and nutritional data. It's designed with a focus on **Indian cuisine** — one of the most underserved food categories in existing nutrition apps.

No barcode scanning. No manual lookup. Just point your camera at your food and let AI do the rest.

---

## 📱 Features

### 🤖 AI Food Recognition
- **Snap any meal** — camera or gallery
- Powered by **Mistral Pixtral 12B** vision model
- Identifies ingredients, cooking method, and portion size
- Supports **35+ pre-seeded Indian dishes** with instant lookup (no AI cost)
- Falls back to full AI analysis for unknown foods, then **caches results forever**
- Confidence score shown on every result

### 🇮🇳 Indian Food First
- Trained reference data for 35+ common Indian foods (dal, biryani, roti, dosa, etc.)
- Accurate per-serving macros based on standard Indian portions
- `🇮🇳` badge shown automatically for Indian cuisine items
- Cuisine-aware text analysis with Indian food hints

### 📊 Nutrition Tracking
- Daily calorie ring with real-time remaining/over display
- Macro tracking — Protein, Carbs, Fat, Fiber
- Water intake logging with quick +250ml button
- Weekly bar chart with streak tracking
- Meal type categorization (Breakfast, Lunch, Dinner, Snack)

### 🔐 Authentication
- Email OTP login via **Supabase Auth** — no passwords
- 6-digit code, 60s resend timer
- Session persistence across app restarts
- Auto-routing: new user → Onboarding → Home

### 📝 Manual Entry & Text Analysis
- Describe your meal in text (e.g. *"2 rotis with dal makhani"*)
- Quick example chips for common meals
- Manual calorie/macro entry with portion size

### ⚙️ Personalization
- Onboarding flow: name, fitness goal, calorie & protein targets
- Quick presets: Cut (1500 kcal), Maintain (2000 kcal), Bulk (2600 kcal)
- Goals adjustable anytime in settings
- User profile stored in Supabase

---

## 🎯 Use Cases

| User | How They Use Calo AI |
|------|----------------------|
| 🏋️ **Fitness enthusiast** | Tracks every meal to hit protein & calorie targets for muscle gain or fat loss |
| 🍱 **Indian home cook** | Photos home-cooked meals — dal, sabzi, roti — and gets accurate macros |
| 🎓 **Student / hostel resident** | Logs mess food quickly using text description |
| 👨‍⚕️ **Health-conscious professional** | Monitors weekly trends and maintains calorie goals |
| 🤸 **Beginner dieter** | Uses preset goals and simple snap-to-log workflow |

---

## 🏗️ Tech Stack

### 📱 Mobile App (Flutter)

```
lib/
├── main.dart                  # App entry, auth gate, routing
├── providers/
│   └── app_providers.dart     # State management (ChangeNotifier)
├── screens/
│   ├── auth_screen.dart       # OTP login flow
│   ├── onboarding_screen.dart # First-time user setup
│   ├── home_screen.dart       # Dashboard with calorie ring
│   ├── camera_screen.dart     # Snap/text food analysis
│   ├── log_screen.dart        # Food log history
│   ├── stats_screen.dart      # Weekly charts & breakdown
│   └── setting_screen.dart    # Profile & goals
├── services/
│   ├── supabase_auth_service.dart  # Auth, session management
│   └── api_service.dart            # Railway backend API calls
└── models/
    └── food_entry.dart        # Data models
```

| Package | Purpose |
|---------|---------|
| `supabase_flutter` | Auth + direct DB queries |
| `provider` | State management |
| `http` | API calls to Railway backend |
| `image_picker` | Camera & gallery access |
| `shared_preferences` | Session & onboarding persistence |
| `sizer` | Responsive UI sizing |
| `intl` | Date formatting |

### ⚙️ Backend (Python + FastAPI)

```
calo_backend/
├── main.py                        # FastAPI app, all routes
├── app/
│   ├── models/
│   │   └── schemas.py             # Pydantic request/response models
│   └── services/
│       ├── mistral_service.py     # AI vision + smart caching
│       └── supabase_service.py    # DB operations (service role)
├── Procfile                       # Railway deployment
├── railway.json                   # Build config
└── requirements.txt
```

| Technology | Purpose |
|-----------|---------|
| **FastAPI** | Async REST API framework |
| **Mistral Pixtral 12B** | Food image analysis (vision model) |
| **Groq / Gemini** | Alternative AI providers (configurable) |
| **Supabase** | PostgreSQL DB + Auth + Storage |
| **httpx** | Async HTTP client |
| **Railway** | Cloud deployment, auto-deploy from GitHub |

### 🗄️ Database (Supabase / PostgreSQL)

```sql
Tables:
├── auth.users          -- Managed by Supabase Auth
├── public.users        -- User profiles & goals
├── public.food_logs    -- Daily meal entries (soft delete)
├── public.food_database -- AI nutrition cache (35+ pre-seeded)
├── public.water_logs   -- Daily water intake
└── public.weight_logs  -- Weight tracking history
```

---

## 🧠 AI Architecture

### Smart 2-Step Caching System

```
User uploads food photo
         │
         ▼
┌─────────────────────┐
│  Step 1: Name Only  │  ← Cheap AI call (minimal tokens)
│  Mistral identifies │    "What food is this?"
│  food name only     │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Step 2: DB Lookup  │  ← Zero AI cost
│  Check food_database│
│  table in Supabase  │
└────┬────────────────┘
     │
     ├── CACHE HIT ──────────────────────────────────►  Return instantly ⚡
     │   (dal tadka, biryani, roti etc.)                No AI cost
     │
     └── CACHE MISS ──────────────────────────────────► Full AI Analysis
         (unknown food)                                  │
                                                         ▼
                                                  Mistral Pixtral 12B
                                                  Full nutrition analysis
                                                         │
                                                         ▼
                                                  Save to food_database
                                                  (future requests = free)
```

### Why This Matters
- **Common Indian foods** (dal, roti, biryani) → answered instantly from DB, **0 AI tokens used**
- **New foods** → analyzed by AI once, then cached forever
- **Hit counter** tracks food popularity — most common foods load fastest
- **Confidence score** returned with every result

### AI Provider Support
Calo AI supports 3 vision AI providers, switchable via environment variable:

```bash
AI_PROVIDER=mistral   # Mistral Pixtral 12B (default, best accuracy)
AI_PROVIDER=groq      # Llama 4 Scout 17B (fastest, free tier)
AI_PROVIDER=gemini    # Gemini 1.5 Flash (Google, good fallback)
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x
- Python 3.11+
- Supabase account (free tier works)
- Mistral API key (or Groq/Gemini)
- Railway account (for backend deployment)

### 1. Clone the repos

```bash
# Flutter app
git clone https://github.com/lalit127/cal_ai.git

# Python backend
git clone https://github.com/lalit127/calo_backend.git
```

### 2. Set up Supabase

Run these SQL scripts in your Supabase SQL Editor:

```sql
-- Users table
create table public.users (
  id uuid primary key references auth.users(id),
  email text not null,
  name text,
  goal text default 'maintain',
  goal_calories int default 2000,
  goal_protein float default 150,
  goal_carbs float default 250,
  goal_fat float default 65,
  goal_water_ml int default 2500,
  updated_at timestamptz default now()
);

-- Food logs
create table public.food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  food_name text not null,
  meal_type text not null,
  calories int not null,
  protein_g float default 0,
  carbs_g float default 0,
  fat_g float default 0,
  fiber_g float default 0,
  image_url text,
  is_indian_food boolean default false,
  ai_confidence float,
  logged_at timestamptz default now(),
  deleted_at timestamptz,
  created_at timestamptz default now()
);

-- Water logs
create table public.water_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  amount_ml int not null,
  logged_at timestamptz default now()
);
```

Enable Row Level Security and add policies for each table.

### 3. Configure backend

```bash
cd calo_backend
cp .env.example .env
```

Edit `.env`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
SUPABASE_ANON_KEY=your-anon-key
MISTRAL_API_KEY=your-mistral-key
AI_PROVIDER=mistral
```

```bash
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 4. Configure Flutter app

In `lib/services/dart/api_service.dart`:
```dart
static const String baseUrl = 'https://your-railway-app.up.railway.app';
// or for local dev:
static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
```

In `lib/main.dart`:
```dart
const _supabaseUrl     = 'https://your-project.supabase.co';
const _supabaseAnonKey = 'your-anon-key';
```

```bash
flutter pub get
flutter run
```

### 5. Deploy backend to Railway

```bash
# Push to GitHub — Railway auto-deploys
git add -A && git commit -m "deploy" && git push origin main
```

Add environment variables in Railway dashboard under **Variables**.

---

## 📡 API Reference

Base URL: `https://web-production-4b65.up.railway.app`

> All endpoints except `/health` require `Authorization: Bearer <supabase_jwt>`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `GET` | `/users/me` | Get user profile |
| `PATCH` | `/users/me` | Update profile & goals |
| `POST` | `/food/analyze/image` | Analyze food photo (no save) |
| `POST` | `/food/analyze/text` | Analyze food by text |
| `POST` | `/food/log/image` | Snap + analyze + save |
| `POST` | `/food/log` | Manual food entry |
| `GET` | `/food/daily` | Today's nutrition summary |
| `GET` | `/food/weekly` | 7-day stats & streak |
| `DELETE` | `/food/log/{id}` | Soft delete entry |
| `POST` | `/users/me/water` | Log water intake |
| `GET` | `/users/me/water/today` | Today's water total |
| `POST` | `/users/me/weight` | Log weight |

📖 Interactive docs: [`/docs`](https://web-production-4b65.up.railway.app/docs)

---

## 🗺️ Roadmap

- [ ] Barcode scanner for packaged foods
- [ ] Meal planning & recipes
- [ ] Apple Health / Google Fit sync
- [ ] Push notifications for meal reminders
- [ ] Social features — share meals, leaderboards
- [ ] Offline mode with local SQLite cache
- [ ] iPad / tablet layout
- [ ] Web app (Flutter Web)

---

## 🤝 Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

```bash
# Fork the repo, then:
git checkout -b feature/your-feature
git commit -m "feat: add your feature"
git push origin feature/your-feature
# Open a Pull Request
```

---

## 📄 License

Feel Free to Use 😂

---

<div align="center">

Built with ❤️ by [lalit127](https://github.com/lalit127)

⭐ **Star this repo if you found it helpful!** ⭐

</div>
