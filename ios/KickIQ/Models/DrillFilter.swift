import Foundation

nonisolated struct DrillFilter: Codable, Sendable, Equatable {
    var categories: Set<SkillCategory>
    var difficulties: Set<DrillDifficulty>
    var intensities: Set<DrillIntensity>
    var trainingModes: Set<TrainingMode>
    var equipment: Set<EquipmentType>
    var maxDurationMinutes: Int?
    var minDurationMinutes: Int?
    var searchText: String

    init(
        categories: Set<SkillCategory> = [],
        difficulties: Set<DrillDifficulty> = [],
        intensities: Set<DrillIntensity> = [],
        trainingModes: Set<TrainingMode> = [],
        equipment: Set<EquipmentType> = [],
        maxDurationMinutes: Int? = nil,
        minDurationMinutes: Int? = nil,
        searchText: String = ""
    ) {
        self.categories = categories
        self.difficulties = difficulties
        self.intensities = intensities
        self.trainingModes = trainingModes
        self.equipment = equipment
        self.maxDurationMinutes = maxDurationMinutes
        self.minDurationMinutes = minDurationMinutes
        self.searchText = searchText
    }

    var isEmpty: Bool {
        categories.isEmpty
        && difficulties.isEmpty
        && intensities.isEmpty
        && trainingModes.isEmpty
        && equipment.isEmpty
        && maxDurationMinutes == nil
        && minDurationMinutes == nil
        && searchText.isEmpty
    }

    var activeFilterCount: Int {
        var count = 0
        if !categories.isEmpty { count += 1 }
        if !difficulties.isEmpty { count += 1 }
        if !intensities.isEmpty { count += 1 }
        if !trainingModes.isEmpty { count += 1 }
        if !equipment.isEmpty { count += 1 }
        if maxDurationMinutes != nil || minDurationMinutes != nil { count += 1 }
        return count
    }

    func matches(_ drill: Drill) -> Bool {
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            let nameMatch = drill.name.localizedStandardContains(query)
            let descMatch = drill.description.localizedStandardContains(query)
            let skillMatch = drill.targetSkill.localizedStandardContains(query)
            if !nameMatch && !descMatch && !skillMatch { return false }
        }

        if !categories.isEmpty {
            if let resolved = drill.resolvedCategory {
                if !categories.contains(resolved) { return false }
            } else {
                return false
            }
        }

        if !difficulties.isEmpty, !difficulties.contains(drill.difficulty) { return false }
        if !intensities.isEmpty, !intensities.contains(drill.intensity) { return false }
        if !trainingModes.isEmpty, !trainingModes.contains(drill.trainingMode) { return false }

        if !equipment.isEmpty {
            let drillEquipment = Set(drill.equipment)
            if drillEquipment.isDisjoint(with: equipment) { return false }
        }

        if let min = minDurationMinutes, drill.durationMinutes < min { return false }
        if let max = maxDurationMinutes, drill.durationMinutes > max { return false }

        return true
    }

    static let `default` = DrillFilter()
}
