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

struct Routine: Identifiable, Codable {
    var id = UUID()
    var name: String
    var tasks: [Task]
    var streak: Int
    var lastCompleted: Date?
    var createdAt: Date
    var isActive: Bool
    
    var totalDuration: TimeInterval {
        tasks.reduce(0) { $0 + $1.duration }
    }
    
    var formattedTotalDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

class RoutineStore: ObservableObject {
    @Published var routines: [Routine] = []
    
    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        saveRoutines()
    }
    
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
            saveRoutines()
        }
    }
    
    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        saveRoutines()
    }
    
    private func saveRoutines() {
        // TODO: Implement persistence
    }
    
    private func loadRoutines() {
        // TODO: Implement loading from persistence
    }
} 