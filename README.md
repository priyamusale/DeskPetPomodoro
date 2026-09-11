# DeskPet Pomodoro 🐾🍅

Welcome to DeskPet Pomodoro! This is a beautiful, aesthetic macOS Pomodoro timer and daily planner that features a cute virtual desk pet, a physical notebook aesthetic, and real-time coworking features.

<img width="162" height="178" alt="image" src="https://github.com/user-attachments/assets/40ede813-10f7-4c41-aa77-d2a4322fd1e9" />

## Features
- **Virtual Pet**: A cute pet that hangs out with you while you work. Feed it treats, watch it sleep, and earn coins!
- **Pomodoro Timer**: Classic 25-minute focus blocks with 5-minute short breaks and 15-minute long breaks.
- **Physical Planner Aesthetic**: A beautifully designed notebook interface for tracking your daily, weekly, and monthly tasks.
- **Coworking Mode**: Connect to a shared room using Firebase. If your friend or partner starts their Pomodoro timer, a glowing red heart (♡) appears over your pet's head in real-time so you know they are working with you!
- **Goals & Wagers**: Set long-term goals and check in with photo evidence.

## Getting Started

### Prerequisites
- macOS 14.0 or newer
- Xcode 15+ (if building from source)

### Installation
1. Clone this repository.
2. Open `DeskPetPomodoro.xcodeproj` in Xcode.
3. Build and run the app (`Cmd + R`).

### How to use Coworking Mode
1. Click the **Heart icon (♡)** at the bottom of the Pomodoro timer panel.
2. Enter a shared **Room Code** (e.g. `OUR_ROOM`).
3. Click **Join Room**.
4. When anyone in the same room starts their timer, a heart will appear over your pet!

## Privacy
Your privacy is fully protected. All of your goals, tasks, and planner notes are stored **locally** on your Mac using SwiftData. 
The *only* information sent to the internet (via Firebase) is a tiny anonymous signal that says whether your Pomodoro timer is actively ticking (true/false) when you are in a Coworking room.
