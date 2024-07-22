//
//  FormatStyle+TimerCountdown.swift
//  musicplayer
//
//  Created by Angelo on 22/07/2024.
//

import SwiftUI

struct TimerCountdownFormatStyle: FormatStyle {
    func format(_ value: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(value)) ?? ""
    }
}

extension FormatStyle where Self == TimerCountdownFormatStyle {
    static var timerCountdown: TimerCountdownFormatStyle { TimerCountdownFormatStyle() }
}
