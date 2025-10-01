//
//  ContentView.swift
//  Haptics
//
//  Created by Ahmya Rivera on 9/30/25.
//

import SwiftUI
import AVFoundation   // for bg music + sfx
import UIKit          // for haptics

struct ContentView: View {
    enum Screen { case title, onboarding, match }  // simple router
    enum SwipeDir { case left, right }             // which way the card was thrown

    @State private var screen: Screen = .title
    @State private var vibe: Double = 0            // fake “match %” (still here if you want to use it)
    @StateObject private var sound = Sound()       // audio helper

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()   // calm background like the ref

            switch screen {
            case .title:
                TitleView(
                    onStart: {
                        Haptics.medium(); sound.playSFX("tap")
                        sound.playBGM("bgm_loop", volume: 0.35, pan: 0, rate: 1, loops: -1)
                        screen = .onboarding
                    },
                    onToggleMusic: {
                        Haptics.light()
                        if sound.isBGMPlaying { sound.stopBGM() }
                        else { sound.playBGM("bgm_loop", volume: 0.35, pan: 0, rate: 1, loops: -1) }
                    }
                )

            case .onboarding:
                OnboardingView(
                    onSkip: { screen = .match },
                    onDone: { screen = .match }
                )

            case .match:
                MatchView(
                    vibe: $vibe,
                    onBack: {
                        Haptics.light(); sound.playSFX("tap")
                        sound.stopBGM()
                        vibe = 0
                        screen = .title
                    },
                    onWin: {
                        Haptics.success(); sound.playSFX("win")
                    },
                    onTap: {
                        // tiny stereo wiggle so pills feel responsive
                        sound.playSFX("tap", volume: 0.9, pan: Float.random(in: -0.15...0.15), rate: 1.02)
                    },
                    onSwipe: { dir in
                        // swiping right feels like "yes", left is "nah"
                        sound.playSFX("swipe", volume: 0.9, pan: Float(dir == .right ? 0.2 : -0.2), rate: 1.0)
                        if dir == .right {
                            Haptics.medium()
                        } else {
                            Haptics.light()
                        }
                    }
                )
            }
        }
    }
}

// ============================ TITLE ============================

struct TitleView: View {
    let onStart: () -> Void
    let onToggleMusic: () -> Void
    @State private var breathing = false

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            // original sprite = mine (just shapes)
            FriendSpark(size: 130)
                .shadow(color: .orange.opacity(0.35), radius: 18, x: 0, y: 10)
                .scaleEffect(breathing ? 1.06 : 0.94)   // slow “breath” so it’s not static
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: breathing)
                .onAppear { breathing = true }

            VStack(spacing: 6) {
                Text("same • friends")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                Text("Meet people who get your oddly-specific interests.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                Button(action: onStart) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(.orange, in: Capsule())
                }
                .padding(.horizontal)

                Button(action: onToggleMusic) {
                    Label("Music On / Off", systemImage: "music.note.list")
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(.primary.opacity(0.06), in: Capsule())
                }
                .foregroundStyle(.primary)
            }

            Spacer()
            Text("SwiftUI • AVAudioPlayer • Haptics")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 14)
        }
        .padding(.top, 22)
    }
}

// ========================= ONBOARDING ==========================

struct OnboardingView: View {
    let onSkip: () -> Void
    let onDone: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardCard(
                    tag1: "cosplay", tag2: "board game nights",
                    title: "Swipe on tastes, not people.",
                    text: "We match you with friends who share the strangely specific stuff you love."
                ).tag(0)

                OnboardCard(
                    tag1: "theme parks", tag2: "sudoku",
                    title: "Shared quirks > small talk.",
                    text: "Pick a few interests and we’ll find your vibe-match."
                ).tag(1)

                OnboardCard(
                    tag1: "pineapple pizza", tag2: "mexican food",
                    title: "Chat about what matters.",
                    text: "When you match, conversations start from a mutual ‘yes!’"
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            HStack {
                Button("Skip") { Haptics.light(); onSkip() }
                    .foregroundStyle(.secondary)
                Spacer()
                Button(page == 2 ? "Continue" : "Next") {
                    Haptics.light()
                    if page < 2 { page += 1 } else { onDone() }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

struct OnboardCard: View {
    let tag1: String
    let tag2: String
    let title: String
    let text: String

    var body: some View {
        VStack {
            Spacer(minLength: 20)

            // header like the ad examples (logo text + pills)
            VStack(spacing: 14) {
                Text("same")
                    .font(.system(size: 30, weight: .black, design: .rounded))

                VStack(spacing: 10) {
                    Text("Meet someone who gets your love for")
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                    HStack {
                        TagPill(tag1)                         // unlabeled init so this compiles
                        Text("and").foregroundStyle(.secondary)
                        TagPill(tag2)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            // footer card like the reference UI
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.title3.bold())
                Text(text).foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding()
        }
    }
}

// pill style used everywhere
struct TagPill: View {
    let text: String
    // unlabeled init so I can write TagPill("cosplay")
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline.bold())
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.orange.opacity(0.18), in: Capsule())
    }
}

// ========================== MATCH ==============================

struct MatchView: View {
    @Binding var vibe: Double
    let onBack: () -> Void
    let onWin: () -> Void
    let onTap: () -> Void
    let onSwipe: (ContentView.SwipeDir) -> Void

    // fake profiles so it looks real but all assets are original
    @State private var profiles: [Profile] = Profile.samples

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .padding(10)
                        .background(.primary.opacity(0.06), in: Circle())
                }
                .foregroundStyle(.primary)

                Spacer()

                // % badge (kept from earlier version)
                HStack(spacing: 6) {
                    Circle().strokeBorder(.primary.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                        .overlay(Text("\(Int(vibe))").font(.caption.bold()))
                    Text("% vibe")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(8)
                .background(.primary.opacity(0.06), in: Capsule())
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 4) {
                Text("Swipe friends with your tastes").font(.title3.bold())
                Text("Right = yes • Left = maybe later").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // the new swipe deck lives here
            SwipeDeck(profiles: $profiles) { dir, _ in
                onSwipe(dir)
                // tiny reward if you say yes -> increment the vibe
                if dir == .right {
                    withAnimation(.spring) { vibe = min(vibe + 8, 100) }
                    if vibe >= 100 { onWin() }
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 10)
        }
    }
}

// model for a profile card
struct Profile: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let age: Int
    let distance: String
    let emoji: String     // using emoji as “photo” so it’s clearly fake/original
    let interests: [String]
    let gradient: [Color]

    // a few sample cards (totally fake)
    static let samples: [Profile] = [
        .init(name: "Elena", age: 25, distance: "1.3 mi", emoji: "📸",
              interests: ["mexican food","photo walks","thrift flips"],
              gradient: [.purple.opacity(0.25), .pink.opacity(0.15)]),
        .init(name: "Josh", age: 28, distance: "2.1 mi", emoji: "🎮",
              interests: ["board games","cosplay","retro gaming"],
              gradient: [.cyan.opacity(0.25), .blue.opacity(0.15)]),
        .init(name: "Maddie", age: 27, distance: "0.9 mi", emoji: "🍍",
              interests: ["pineapple pizza","sudoku","true crime"],
              gradient: [.orange.opacity(0.25), .yellow.opacity(0.15)]),
        .init(name: "Kai", age: 24, distance: "3.8 mi", emoji: "🎢",
              interests: ["theme parks","roller skating","modern art"],
              gradient: [.mint.opacity(0.25), .teal.opacity(0.15)])
    ]
}

// swipe deck view (top card is draggable, rest stack underneath)
struct SwipeDeck: View {
    @Binding var profiles: [Profile]
    let onSwipe: (ContentView.SwipeDir, Profile) -> Void

    // drag state for the top card
    @State private var dragOffset: CGSize = .zero
    private let swipeThreshold: CGFloat = 120 // how far before we count it

    var body: some View {
        ZStack {
            // draw from back to front so top is last
            ForEach(Array(profiles.enumerated()), id: \.element.id) { index, p in
                let isTop = index == 0
                ProfileCard(profile: p, isTop: isTop)
                    .offset(isTop ? dragOffset : .zero)
                    .rotationEffect(.degrees(isTop ? Double(dragOffset.width / 15) : 0))
                    .scaleEffect(isTop ? 1.0 : 0.96 - CGFloat(index-1) * 0.02)
                    .animation(.spring(response: 0.32, dampingFraction: 0.86), value: dragOffset)
                    .zIndex(Double(profiles.count - index))
                    .gesture(
                        isTop ? dragGesture(for: p) : nil
                    )
            }
        }
        .frame(height: 360)
    }

    // drag logic for the top card
    private func dragGesture(for profile: Profile) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                // decide if we swiped enough
                if value.translation.width > swipeThreshold {
                    swipe(.right, profile)
                } else if value.translation.width < -swipeThreshold {
                    swipe(.left, profile)
                } else {
                    // snap back if not far enough
                    dragOffset = .zero
                }
            }
    }

    private func swipe(_ dir: ContentView.SwipeDir, _ profile: Profile) {
        // fling it off-screen in the direction we threw
        let x = dir == .right ? 1000.0 : -1000.0
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            dragOffset = CGSize(width: x, height: 40)
        }
        // remove after animation and recycle to the back (endless deck)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let removed = profiles.removeFirst()
            profiles.append(removed)
            dragOffset = .zero
            onSwipe(dir, profile)
        }
    }
}

// visual for each profile (gradient “photo” + emoji + name + tags)
struct ProfileCard: View {
    let profile: Profile
    let isTop: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: profile.gradient, startPoint: .top, endPoint: .bottom))
                    .frame(height: 220)

                // emoji “photo” so the card feels personal but still fake/original
                Text(profile.emoji)
                    .font(.system(size: 56))
                    .padding(12)
            }

            HStack {
                Text("\(profile.name) \(profile.age)")
                    .font(.headline)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "location")
                    Text(profile.distance)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            // show up to 3 interest pills so it looks like the dribbble shot
            FlowPills(strings: Array(profile.interests.prefix(3)))
        }
        .padding(14)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(isTop ? 0.08 : 0.04), radius: isTop ? 10 : 6, x: 0, y: 6)
        .padding(.horizontal, isTop ? 0 : 10)
    }
}

// a simple “wrap” of pills (manual since I’m avoiding extra libs)
struct FlowPills: View {
    let strings: [String]
    var body: some View {
        // just stack horizontally; if it overflows, it’ll truncate (ok for demo)
        HStack(spacing: 8) {
            ForEach(strings, id: \.self) { s in TagPill(s) }
        }
    }
}

// ===================== ORIGINAL SPRITE =========================

struct FriendSpark: View {
    var size: CGFloat = 100
    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
                    .fill(AngularGradient(colors: [.orange, .yellow, .pink, .orange], center: .center))
                    .frame(width: size * 0.18, height: size * 0.28)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(i) * 60))
                    .blur(radius: 0.3)
            }
            Circle()
                .fill(RadialGradient(colors: [.white, .orange.opacity(0.7), .clear],
                                     center: .center, startRadius: 0, endRadius: size * 0.55))
                .frame(width: size * 0.62, height: size * 0.62)
        }
        .frame(width: size, height: size)
    }
}

// ==================== AUDIO + HAPTICS ==========================

final class Sound: ObservableObject {
    private var bgm: AVAudioPlayer?
    private var sfx: AVAudioPlayer?
    @Published var isBGMPlaying = false

    private func url(for name: String, ext: String = "wav") -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext)
    }

    // lecture flags: volume / pan / rate / numberOfLoops
    func playBGM(_ name: String, volume: Float = 0.4, pan: Float = 0,
                 rate: Float = 1.0, loops: Int = -1) {
        guard let url = url(for: name) else { print("BGM not found"); return }
        do {
            bgm = try AVAudioPlayer(contentsOf: url)
            bgm?.volume = max(0, min(volume, 1))
            bgm?.pan = max(-1, min(pan, 1))
            bgm?.rate = rate
            bgm?.numberOfLoops = loops          // -1 = infinite loop
            bgm?.enableRate = true
            bgm?.prepareToPlay()
            bgm?.play()
            isBGMPlaying = true
        } catch { print("BGM error: \(error)") }
    }

    func stopBGM() {
        bgm?.stop()
        bgm?.currentTime = 0
        isBGMPlaying = false
    }

    func playSFX(_ name: String, volume: Float = 0.9, pan: Float = 0, rate: Float = 1.0) {
        guard let url = url(for: name) else { print("SFX not found"); return }
        do {
            sfx = try AVAudioPlayer(contentsOf: url)
            sfx?.volume = max(0, min(volume, 1))
            sfx?.pan = max(-1, min(pan, 1))
            sfx?.rate = rate
            sfx?.enableRate = true
            sfx?.prepareToPlay()
            sfx?.play()
        } catch { print("SFX error: \(error)") }
    }
}

enum Haptics {
    static func light()   { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func medium()  { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}

#Preview {
    ContentView()
}

