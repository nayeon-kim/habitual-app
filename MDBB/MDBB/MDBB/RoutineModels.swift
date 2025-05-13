import Foundation
import SwiftUI

struct Task: Identifiable, Codable {
    var id = UUID()
    var name: String
    var duration: TimeInterval
    var icon: String
    var color: String
    var order: Int
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct Routine: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var tasks: [Task]
    var streak: Int
    var lastCompleted: Date?
    var createdAt: Date
    var isActive: Bool
    var completionDates: [Date] = []
    
    var totalDuration: TimeInterval {
        tasks.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTotalDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func wasCompletedOn(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return completionDates.contains { completionDate in
            calendar.isDate(completionDate, inSameDayAs: date)
        }
    }
    
    static func == (lhs: Routine, rhs: Routine) -> Bool {
        lhs.id == rhs.id
    }
}

class RoutineStore: ObservableObject {
    @Published var routines: [Routine] = [] {
        didSet {
            saveRoutines()
        }
    }
    
    private let routinesFile = "routines.json"
    
    init() {
        loadRoutines()
    }
    
    func addRoutine(_ routine: Routine) {
        print("[DEBUG] Adding routine: \(routine.name), tasks: \(routine.tasks.count)")
        routines.append(routine)
        print("[DEBUG] Current routines: \(routines.map { $0.name })")
        // saveRoutines() now handled by didSet
    }
    
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            print("[DEBUG] Updating routine: \(routine.name)")
            print("[DEBUG] updateRoutine: completionDates=\(routine.completionDates), lastCompleted=\(String(describing: routine.lastCompleted))")
            routines[index] = routine
            // saveRoutines() now handled by didSet
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        print("[DEBUG] Deleting routine: \(routine.name)")
        routines.removeAll { $0.id == routine.id }
        // saveRoutines() now handled by didSet
    }
    
    private func saveRoutines() {
        do {
            let data = try JSONEncoder().encode(routines)
            let url = getDocumentsDirectory().appendingPathComponent(routinesFile)
            try data.write(to: url)
            print("[DEBUG] Routines saved to \(url)")
        } catch {
            print("[ERROR] Failed to save routines: \(error)")
        }
    }
    
    private func loadRoutines() {
        let url = getDocumentsDirectory().appendingPathComponent(routinesFile)
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Routine].self, from: data)
            routines = decoded
            print("[DEBUG] Routines loaded from \(url)")
        } catch {
            print("[DEBUG] No routines file found or failed to load: \(error)")
            routines = []
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 
