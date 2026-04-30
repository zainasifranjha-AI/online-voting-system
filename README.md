# 🗳️ Online Voting System

A secure online voting system built using **Flutter (Frontend)** and **Laravel (Backend)**.

---

## 🚀 Features

- 🔐 User Registration & Login
- 🧑‍💼 Admin Panel (secure access)
- ➕ Add Candidates (Name, Position, Symbol Image)
- 🖼️ Image-based electoral symbols
- ⏳ Voting start & end time control
- 🗳️ One User = One Vote system
- 📊 Live Results
- 🏆 Winner Announcement
- 📋 Vote Tracking (who voted whom)

---

## 🛠 Tech Stack

- **Frontend:** Flutter (Web)
- **Backend:** Laravel (API)
- **Database:** MySQL
- **Hosting:** Railway & Vercel

---

## ⚙️ Setup Instructions

### 🔹 Backend (Laravel)

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan storage:link
php artisan serve