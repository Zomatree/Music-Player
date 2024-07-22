//
//  PlayerView.swift
//  musicplayer
//
//  Created by Angelo on 17/07/2024.
//

import SwiftUI
import MusicKit
import MediaPlayer

struct PlayerView: View {    
    @ObservedObject var queue = SystemMusicPlayer.shared.queue
    
    @State var title: String = ""
    @State var artist: String = ""
    @State var isPlaying: Bool = SystemMusicPlayer.shared.state.playbackStatus == .playing
    @State var currentImage: UIImage? = nil
    @State var progress: Double = 0.0
    @State var length: Double = 0.0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    init() {
        if let song = queue.currentEntry {
            getSongData(song: song)
        }
    }
    
    func getSongData(song: SystemMusicPlayer.Queue.Entry) {
        if case .song(let internalSong) = song.item {
            title = internalSong.title
            artist = internalSong.artistName
            length = internalSong.duration ?? 0.0
        }

    }
    
    func getSongInfo(song: SystemMusicPlayer.Queue.Entry) async {
        getSongData(song: song)
        await getImage(song: song)
    }
    
    func getImage(song: SystemMusicPlayer.Queue.Entry) async {
        if let url = song.artwork?.url(width: 256, height: 256),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data)
        {
            self.currentImage = image
        }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            if let currentSong = queue.currentEntry {
                let _ = print(currentSong)
                
                if let currentImage {
                    Image(uiImage: currentImage)
                        .frame(width: 256, height: 256)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                } else {
                    Rectangle()
                        .foregroundStyle(.gray)
                        .frame(width: 256, height: 256)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(radius: 4)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .center, spacing: 0) {
                        Text(verbatim: title)
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text(verbatim: artist)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white)
                    .truncationMode(.tail)
                    .lineLimit(1)
                    .padding(.bottom, 8)
                    
                    HStack {
                        Text(Int(progress), format: .timerCountdown)
                            .font(.caption)
                            .lineLimit(1)
                        
                        ProgressView(value: progress, total: length)
                            .tint(.white)
                            .padding(.top, 4)
                        
                        Text(Int(length), format: .timerCountdown)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    
                    HStack(alignment: .center) {
                        Button {
                            Task {
                                try! await SystemMusicPlayer.shared.skipToPreviousEntry()
                            }
                        } label: {
                            Image(systemName: "backward.fill")
                                .resizable()
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 32)
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                if isPlaying {
                                    SystemMusicPlayer.shared.pause()
                                } else {
                                    try! await SystemMusicPlayer.shared.play()
                                }
                                
                                isPlaying.toggle()
                            }
                            
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .resizable()
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                try! await SystemMusicPlayer.shared.skipToNextEntry()
                            }
                        } label: {
                            Image(systemName: "forward.fill")
                                .resizable()
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 32)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(width: 256)
            }
        }
        .padding(.vertical, 64)
        .padding(.horizontal, 128)
        .background {
            ZStack {
                if let currentImage {
                    Image(uiImage: currentImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                    
                Rectangle()
                    .foregroundStyle(.ultraThinMaterial)
            }
            .ignoresSafeArea(.all)
        }
        .ignoresSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Task {
                if let song = queue.currentEntry {
                    await getSongInfo(song: song)
                }
            }
        }
        .onReceive(queue.objectWillChange) { _ in
            progress = 0.0
            
            if let song = queue.currentEntry {
                Task {
                    await getSongInfo(song: song)
                }
            }
        }
        .onReceive(timer) { _ in
            progress = SystemMusicPlayer.shared.playbackTime
        }
        
    }
}
