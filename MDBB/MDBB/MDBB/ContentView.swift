//
//  ContentView.swift
//  MDBB
//
//  Created by Nayeon Kim on 5/4/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var routineStore: RoutineStore
    @State private var showingAddRoutine = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: Theme.padding) {
                        ForEach(routineStore.routines) { routine in
                            RoutineCard(routine: routine)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRoutine = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddRoutine) {
                AddRoutineView(routineStore: routineStore)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct RoutineCard: View {
    let routine: Routine
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.smallPadding) {
            HStack {
                Text(routine.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.text)
                
                Spacer()
                
                Text(routine.formattedTotalDuration)
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
            
            HStack {
                Label("\(routine.streak) day streak", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(Theme.accent)
                
                Spacer()
                
                Text("\(routine.tasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RoutineStore())
    }
}
