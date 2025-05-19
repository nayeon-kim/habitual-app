import SwiftUI

struct StreakCircleView: View {
    let date: Date
    let store: RoutineStore
    let dateFormatter: DateFormatter
    
    private var isCompleted: Bool {
        store.isRoutineCompleted(for: date)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 40, height: 40)
                }
            }
            
            Text(dateFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: RoutineStore
    @State private var selectedWeekOffset: Int = 0
    
    private var selectedDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: selectedWeekOffset, to: Date()) ?? Date()
    }
    
    private var weekStartDate: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? Date()
    }
    
    private var weekEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? Date()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    private var weekRangeText: String {
        "\(dateFormatter.string(from: weekStartDate)) - \(dateFormatter.string(from: weekEndDate))"
    }
    
    private var weekDates: [Date] {
        (0..<7).map { index in
            Calendar.current.date(byAdding: .day, value: index, to: weekStartDate) ?? Date()
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Add horizontal padding to all content
                    // Week Navigation
                    HStack {
                        Button(action: { selectedWeekOffset -= 1 }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text(weekRangeText)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { selectedWeekOffset += 1 }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .disabled(selectedWeekOffset >= 0)
                    }
                    .padding(.horizontal)
                    
                    // Streak Circles
                    HStack(spacing: 16) {
                        ForEach(weekDates, id: \.self) { date in
                            StreakCircleView(
                                date: date,
                                store: store,
                                dateFormatter: dateFormatter
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    VStack(spacing: 16) {
                        StatCard(title: "Current Streak", value: "\(store.currentStreak) days")
                        StatCard(title: "Best Streak", value: "\(store.bestStreak) days")
                        StatCard(title: "Completion Rate", value: "\(Int(store.completionRate * 100))%")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .padding(.horizontal, 16)
            }
            .navigationTitle("Weekly Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    SummaryView()
        .environmentObject(RoutineStore())
} 