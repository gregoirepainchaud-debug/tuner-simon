import Foundation

struct TuningFile: Decodable {
    let referencePitch: Int
    let pitchChoicesHz: [Int]
    let tunings: [Tuning]
}

struct Tuning: Decodable, Identifiable {
    let id: Int
    let name: String
    let serial: String
    let notes: [NoteTarget]
}

struct NoteTarget: Decodable {
    let key: Int              // touche 1...88 (1 = La0)
    let midi: Int             // 21...108
    let name: String          // nom français : La0, Do#3, ...
    let fundamentalCents: Double
    let fundamentalHz440: Double
    let listenPartial: Int    // partiel de référence (1 = fondamental)
    let partialTargetHz440: Double
    let partialStoredCents: Double?
}

enum TuningsLibrary {
    static let all: [Tuning] = {
        guard let url = Bundle.main.url(forResource: "tunings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(TuningFile.self, from: data) else {
            return []
        }
        return file.tunings
    }()
    static let pitchChoices: [Int] = [440, 441, 442, 443, 444]
}

/// Échelle non linéaire de la barre, validée par Grégoire :
/// -30→-10 : 10 % · -10→-1 : 15 % · -1→0 : 25 % · 0→+1 : 25 % · +1→+10 : 15 % · +10→+30 : 10 %
enum CentScale {
    private static let points: [(cents: Double, fraction: Double)] = [
        (-30, 0.00), (-10, 0.10), (-1, 0.25), (0, 0.50),
        (1, 0.75), (10, 0.90), (30, 1.00)
    ]
    static func fraction(forCents cents: Double) -> Double {
        let c = min(30, max(-30, cents))
        for i in 1..<points.count where c <= points[i].cents {
            let (c0, f0) = points[i - 1]
            let (c1, f1) = points[i]
            return f0 + (c - c0) / (c1 - c0) * (f1 - f0)
        }
        return 1.0
    }
    static let ticks: [Double] = [-30, -20, -10, -5, -1, 0, 1, 5, 10, 20, 30]
}

enum TrackingMode: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case demiTon = "Demi-ton"
    case bloque = "Bloqué"
    var id: String { rawValue }
}
