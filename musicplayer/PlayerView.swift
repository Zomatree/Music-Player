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
    
    @State var isPlaying: Bool = SystemMusicPlayer.shared.state.playbackStatus == .playing
    @State var backgroundColor: Color = .black
    @State var foregroundColor: Color = .white
    @State var secondaryForegroundColor: Color = .gray
    @State var currentImage: UIImage? = nil
    @State var progress: Double = 0.0
    @State var length: Double = 0.0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    func getSongInfo(song: SystemMusicPlayer.Queue.Entry) async {
        if case .song(let internalSong) = song.item {
            
            length = internalSong.duration ?? 0.0
        }
        
        await getImage(song: song)
    }
    
    func getImage(song: SystemMusicPlayer.Queue.Entry) async {
        if let url = song.artwork?.url(width: 256, height: 256),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data)
        {
            self.currentImage = image
            image.getColors() { colors in
                if let colors {
                    backgroundColor = Color(uiColor: colors.background)
                    
                    var r: CGFloat = 0
                    var g: CGFloat = 0
                    var b: CGFloat = 0
                    
                    colors.background.getRed(&r, green: &g, blue: &b, alpha: nil)
                    
                    let isLight = (0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)) > 0.5
                    
                    foregroundColor = Color(uiColor: colors.primary) //isLight ? .black : .white
                    secondaryForegroundColor = isLight ? .gray : .white
                }
            }
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
                
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: currentSong.title)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(foregroundColor)
                            .truncationMode(.tail)
                            .lineLimit(1)
                        
                        if let subtitle = currentSong.subtitle {
                            Text(verbatim: subtitle)
                                .foregroundStyle(secondaryForegroundColor)
                                .font(.subheadline)
                                .truncationMode(.tail)
                                .lineLimit(1)
                        }
                        
                        ProgressView(value: progress, total: length)
                            .tint(foregroundColor)
                            .padding(.top, 4)
                            .frame(width: 192)
                    }
                    
                    HStack(alignment: .center, spacing: 32) {
                        Button {
                            Task {
                                try! await SystemMusicPlayer.shared.skipToPreviousEntry()
                                //self.currentSong = musicPlayer.queue.currentEntry
                            }
                        } label: {
                            Image(systemName: "backward.fill")
                                .resizable()
                                .foregroundStyle(foregroundColor)
                                .frame(width: 38, height: 32)
                        }
                        
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
                                .foregroundStyle(foregroundColor)
                                .frame(width: 42, height: 42)
                        }
                        
                        Button {
                            Task {
                                try! await SystemMusicPlayer.shared.skipToNextEntry()
                                //self.currentSong = musicPlayer.queue.currentEntry
                            }
                        } label: {
                            Image(systemName: "forward.fill")
                                .resizable()
                                .foregroundStyle(foregroundColor)
                                .frame(width: 38, height: 32)
                        }
                    }
                }
                .frame(width: 256)
            }
        }
        .padding(.vertical, 64)
        .padding(.horizontal, 128)
        .background {
            ZStack {
                Rectangle()
                    .foregroundStyle(backgroundColor)
                    
                Rectangle()
                    .background(.ultraThinMaterial)
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
