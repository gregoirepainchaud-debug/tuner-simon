import SwiftUI

struct ContentView: View {
    private let tunings = TuningsLibrary.all

    @State private var tuningID: Int = TuningsLibrary.all.first?.id ?? 1
    @State private var pitchHz: Int = 440
    @State private var mode: TrackingMode = .bloque
    @State private var currentKey: Int = 49          // La4 au départ
    @State private var testCents: Double = 0          // ÉTAPE 1 : signal de test (pas encore d'audio)
    @State private var displayedCents: Double = 0     // aiguille amortie
    @State private var sweep = false
    @State private var sweepPhase: Double = 0

    private let tick = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    private var tuning: Tuning? { tunings.first { $0.id == tuningID } }
    private var note: NoteTarget? {
        guard let t = tuning, (1...88).contains(currentKey) else { return nil }
        return t.notes[currentKey - 1]
    }
    private var ratio: Double { Double(pitchHz) / 440.0 }
    private var inTune: Bool { abs(displayedCents) <= 0.1 }

    var body: some View {
        VStack(spacing: 8) {
            header
            readout
            TunerBar(cents: displayedCents)
                .frame(height: 110)
            controls
            PianoKeyboard(selectedKey: currentKey) { key in
                currentKey = key
                mode = .bloque
            }
            .frame(height: 105)
        }
        .padding(10)
        .background(Color.black)
        .onAppear { pitchHz = storedPitch(for: tuningID) }
        .onReceive(tick) { _ in
            if sweep {
                sweepPhase += 0.045
                testCents = 28 * sin(sweepPhase)
            }
            // Amortissement de l'aiguille : elle converge, sans changer la tolérance.
            displayedCents += (testCents - displayedCents) * 0.35
        }
    }

    // MARK: - Rangées

    private var header: some View {
        HStack(spacing: 16) {
            Menu {
                ForEach(tunings) { t in
                    Button("\(t.name) — \(t.serial)") {
                        tuningID = t.id
                        pitchHz = storedPitch(for: t.id)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "music.note.list")
                    Text(tuning.map { "\($0.name) · \($0.serial)" } ?? "Aucun accord")
                        .font(.headline)
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                }
                .foregroundColor(.white)
            }
            Spacer()
            Text("Pitch").foregroundColor(.gray)
            Picker("Pitch", selection: $pitchHz) {
                ForEach(TuningsLibrary.pitchChoices, id: \.self) { p in
                    Text("\(p)").tag(p)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            .onChange(of: pitchHz) { newValue in
                UserDefaults.standard.set(newValue, forKey: "pitch-\(tuningID)")
            }
        }
    }

    private var readout: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(note?.name ?? "—")
                .font(.system(size: 58, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                if let n = note {
                    Text("Partiel écouté : \(n.listenPartial) — cible \(fmt(n.partialTargetHz440 * ratio)) Hz")
                    Text("Fondamental : \(fmt(n.fundamentalHz440 * ratio)) Hz (\(signed(n.fundamentalCents)) cents à 440)")
                }
            }
            .font(.system(size: 15))
            .foregroundColor(.gray)
            Spacer()
            Text("\(signed(displayedCents)) cents")
                .font(.system(size: 40, weight: .semibold, design: .monospaced))
                .foregroundColor(inTune ? .green : .white)
        }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            Picker("Mode", selection: $mode) {
                ForEach(TrackingMode.allCases) { m in Text(m.rawValue).tag(m) }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            Button { step(-1) } label: { Image(systemName: "chevron.left").frame(width: 34, height: 30) }
                .buttonStyle(.bordered)
                .disabled(mode == .auto)
            Button { step(1) } label: { Image(systemName: "chevron.right").frame(width: 34, height: 30) }
                .buttonStyle(.bordered)
                .disabled(mode == .auto)

            Divider().frame(height: 28)
            Text("Test").foregroundColor(.gray)
            Slider(value: $testCents, in: -30...30, step: 0.1)
                .disabled(sweep)
            Toggle("Balayage", isOn: $sweep)
                .fixedSize()
        }
    }

    // MARK: - Aides

    private func step(_ delta: Int) {
        currentKey = min(88, max(1, currentKey + delta))
    }
    private func storedPitch(for id: Int) -> Int {
        let v = UserDefaults.standard.integer(forKey: "pitch-\(id)")
        return TuningsLibrary.pitchChoices.contains(v) ? v : 440
    }
    private func fmt(_ v: Double) -> String { String(format: "%.1f", v) }
    private func signed(_ v: Double) -> String { String(format: "%+.1f", v) }
}

// MARK: - Barre du tuner

struct TunerBar: View {
    let cents: Double
    private var inTune: Bool { abs(cents) <= 0.1 }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.12))
                // Zone centrale ±1 cent (moitié de la barre)
                Rectangle()
                    .fill(Color.green.opacity(0.10))
                    .frame(width: w * 0.5, height: h)
                    .offset(x: w * 0.25)
                ForEach(CentScale.ticks, id: \.self) { t in
                    let x = CentScale.fraction(forCents: t) * w
                    Rectangle()
                        .fill(t == 0 ? Color.green.opacity(0.7) : Color(white: 0.35))
                        .frame(width: t == 0 ? 2 : 1, height: h)
                        .offset(x: x)
                    Text(t == 0 ? "0" : "\(abs(Int(t)))")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .position(x: x, y: h - 9)
                }
                // Curseur : vert seulement entre -0,1 et +0,1 cent
                let x = CentScale.fraction(forCents: cents) * w
                Rectangle()
                    .fill(inTune ? Color.green : Color.white)
                    .frame(width: 4, height: h - 16)
                    .shadow(color: inTune ? .green : .white, radius: inTune ? 8 : 3)
                    .offset(x: x - 2, y: 0)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Clavier (88 touches, 3 octaves visibles, défilant)

private struct WhiteKey: Identifiable { let key: Int; let midi: Int; var id: Int { key } }
private struct BlackKey: Identifiable { let key: Int; let midi: Int; let whitesBefore: Int; var id: Int { key } }

struct PianoKeyboard: View {
    let selectedKey: Int
    let onSelect: (Int) -> Void

    private let whites: [WhiteKey]
    private let blacks: [BlackKey]

    init(selectedKey: Int, onSelect: @escaping (Int) -> Void) {
        self.selectedKey = selectedKey
        self.onSelect = onSelect
        var w: [WhiteKey] = [], b: [BlackKey] = [], count = 0
        for midi in 21...108 {
            let pc = midi % 12
            let key = midi - 20
            if [1, 3, 6, 8, 10].contains(pc) {
                b.append(BlackKey(key: key, midi: midi, whitesBefore: count))
            } else {
                w.append(WhiteKey(key: key, midi: midi)); count += 1
            }
        }
        whites = w; blacks = b
    }

    var body: some View {
        GeometryReader { geo in
            let whiteWidth = geo.size.width / 21      // 3 octaves = 21 blanches visibles
            let totalWidth = whiteWidth * 52
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        HStack(spacing: 0) {
                            ForEach(whites) { wk in
                                ZStack(alignment: .bottom) {
                                    Rectangle()
                                        .fill(wk.key == selectedKey ? Color.blue : Color(white: 0.92))
                                        .border(Color.black, width: 0.5)
                                    if wk.midi % 12 == 0 {
                                        Text("Do\(wk.midi / 12 - 1)")
                                            .font(.system(size: 9))
                                            .foregroundColor(.black.opacity(0.55))
                                            .padding(.bottom, 3)
                                    }
                                }
                                .frame(width: whiteWidth, height: geo.size.height)
                                .contentShape(Rectangle())
                                .onTapGesture { onSelect(wk.key) }
                                .id(wk.key)
                            }
                        }
                        ForEach(blacks) { bk in
                            Rectangle()
                                .fill(bk.key == selectedKey ? Color.blue : Color.black)
                                .border(Color(white: 0.4), width: 0.5)
                                .frame(width: whiteWidth * 0.62, height: geo.size.height * 0.62)
                                .offset(x: CGFloat(bk.whitesBefore) * whiteWidth - whiteWidth * 0.31)
                                .contentShape(Rectangle())
                                .onTapGesture { onSelect(bk.key) }
                        }
                    }
                    .frame(width: totalWidth, height: geo.size.height, alignment: .topLeading)
                }
                .onAppear { proxy.scrollTo(selectedKey, anchor: .center) }
                .onChange(of: selectedKey) { k in
                    withAnimation { proxy.scrollTo(k, anchor: .center) }
                }
            }
        }
    }
}
