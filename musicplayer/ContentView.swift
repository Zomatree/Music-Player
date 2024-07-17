//
//  ContentView.swift
//  musicplayer
//
//  Created by Angelo on 17/07/2024.
//

import SwiftUI
import MusicKit

struct ContentView: View {
    @State var authState: MusicAuthorization.Status = MusicAuthorization.currentStatus
    @State var showPlayer = MusicAuthorization.currentStatus == .authorized
    
    var body: some View {
        if !showPlayer {
            VStack {
                switch authState {
                    case .notDetermined:
                        Text("Authorizing...")
                        ProgressView()
                            .frame(width: 32, height: 32)
                    case .denied:
                        Text("Denied Access, try again")
                        Image(systemName: "xmark")
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.red)
                    case .restricted:
                        Text("Restricted :(")
                    case .authorized:
                        Text("Authorized!")
                        Image(systemName: "checkmark")
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.green)
                }
            }
            .padding()
            .task {
                authState = await MusicAuthorization.request()
                
                if authState == MusicAuthorization.Status.authorized {
                    try! await Task.sleep(for: .seconds(1))
                    showPlayer = true
                }
            }
        } else {
            PlayerView()
                .ignoresSafeArea(.all)
        }
    }
}

#Preview {
    ContentView()
}
