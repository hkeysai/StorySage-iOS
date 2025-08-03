//
//  ContentView.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationRouter())
        .environmentObject(AudioPlayer())
}