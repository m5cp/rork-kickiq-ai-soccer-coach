import Foundation

@Observable
@MainActor
class CustomContentService {
    var library = CustomContentLibrary()

    private let storageKey = "kickiq_custom_content_library"

    init() {
        loadLibrary()
    }

    func loadLibrary() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(CustomContentLibrary.self, from: data) {
            library = decoded
        }
    }

    func saveLibrary() {
        if let data = try? JSONEncoder().encode(library) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func addDrills(_ items: [CustomDrillItem]) {
        library.drills.append(contentsOf: items)
        saveLibrary()
    }

    func addConditioning(_ items: [CustomConditioningItem]) {
        library.conditioning.append(contentsOf: items)
        saveLibrary()
    }

    func addBenchmarks(_ items: [CustomBenchmarkItem]) {
        library.benchmarks.append(contentsOf: items)
        saveLibrary()
    }

    func removeDrill(_ id: String) {
        library.drills.removeAll { $0.id == id }
        saveLibrary()
    }

    func removeConditioning(_ id: String) {
        library.conditioning.removeAll { $0.id == id }
        saveLibrary()
    }

    func removeBenchmark(_ id: String) {
        library.benchmarks.removeAll { $0.id == id }
        saveLibrary()
    }

    func importFromParseResult(_ result: PDFParseResult, fileName: String, contentType: CustomContentType) {
        switch contentType {
        case .drill:
            let drills = result.drills.map { parsed in
                CustomDrillItem(
                    name: parsed.name,
                    description: parsed.description,
                    duration: parsed.duration ?? "10 min",
                    difficulty: parseDifficulty(parsed.difficulty),
                    targetSkill: parsed.targetSkill ?? "General",
                    coachingCues: parsed.coachingCues ?? [],
                    reps: parsed.reps ?? "",
                    sourceFileName: fileName
                )
            }
            addDrills(drills)

        case .conditioning:
            let items = result.conditioning.map { parsed in
                CustomConditioningItem(
                    name: parsed.name,
                    description: parsed.description,
                    duration: parsed.duration ?? "10 min",
                    difficulty: parseDifficulty(parsed.difficulty),
                    focus: parsed.focus ?? "General",
                    coachingCues: parsed.coachingCues ?? [],
                    reps: parsed.reps ?? "",
                    sourceFileName: fileName
                )
            }
            addConditioning(items)

        case .benchmark:
            let items = result.benchmarks.map { parsed in
                CustomBenchmarkItem(
                    name: parsed.name,
                    category: parsed.category ?? "General",
                    instructions: parsed.instructions,
                    howToRecord: parsed.howToRecord,
                    unit: parsed.unit,
                    higherIsBetter: parsed.higherIsBetter ?? true,
                    sourceFileName: fileName
                )
            }
            addBenchmarks(items)
        }
    }

    func allCustomDrillsAsDrills() -> [Drill] {
        library.drills.map { $0.toDrill() }
    }

    func allCustomConditioningAsDrills() -> [Drill] {
        library.conditioning.map { $0.toDrill() }
    }

    func allCustomBenchmarksAsBenchmarkDrills() -> [BenchmarkDrill] {
        library.benchmarks.map { $0.toBenchmarkDrill() }
    }

    var totalCustomItems: Int {
        library.drills.count + library.conditioning.count + library.benchmarks.count
    }

    func deleteAll() {
        library = CustomContentLibrary()
        saveLibrary()
    }

    private func parseDifficulty(_ value: String?) -> DrillDifficulty {
        guard let value else { return .intermediate }
        let lower = value.lowercased()
        if lower.contains("begin") || lower.contains("easy") { return .beginner }
        if lower.contains("advan") || lower.contains("hard") { return .advanced }
        return .intermediate
    }
}
