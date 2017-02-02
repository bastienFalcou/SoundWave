//
//  AudioPlayerManager.swift
//  ela
//
//  Created by Bastien Falcou on 4/14/16.
//  Copyright © 2016 Fueled. All rights reserved.
//
// swiftlint:disable indentation_character

import Foundation
import AVFoundation

final class AudioPlayerManager: NSObject {
	static let shared = AudioPlayerManager()

	var isRunning: Bool {
		guard let audioPlayer = self.audioPlayer, audioPlayer.isPlaying else {
			return false
		}
		return true
	}

	private var audioPlayer: AVAudioPlayer?
	private var audioMeteringLevelTimer: Timer?

	// MARK: - Reinit and play from the beginning

	func play(at url: URL, with audioVisualizationTimeInterval: TimeInterval = 0.05) throws -> TimeInterval {
		if AudioRecorderManager.shared.isRunning {
			print("Audio Player did fail to start: AVFoundation is recording")
			throw AudioErrorType.alreadyRecording
		}

		if self.isRunning {
			print("Audio Player did fail to start: already playing a file")
			throw AudioErrorType.alreadyPlaying
		}

		if !URL.checkPath(url.path) {
			print("Audio Player did fail to start: file doesn't exist")
			throw AudioErrorType.audioFileWrongPath
		}

		try self.audioPlayer = AVAudioPlayer(contentsOf: url)
		self.setupPlayer(with: audioVisualizationTimeInterval)
		print("Started to play sound")

		return self.audioPlayer!.duration
	}

	func play(_ data: Data, with audioVisualizationTimeInterval: TimeInterval = 0.05) throws -> TimeInterval {
		try self.audioPlayer = AVAudioPlayer(data: data)
		self.setupPlayer(with: audioVisualizationTimeInterval)
		print("Started to play sound")

		return self.audioPlayer!.duration
	}
	
	private func setupPlayer(with audioVisualizationTimeInterval: TimeInterval) {
		if let player = self.audioPlayer {
			player.play()
			player.isMeteringEnabled = true
			player.delegate = self
			
			self.audioMeteringLevelTimer = Timer.scheduledTimer(timeInterval: audioVisualizationTimeInterval, target: self,
				selector: #selector(AudioPlayerManager.timerDidUpdateMeter), userInfo: nil, repeats: true)
		}
	}

	// MARK: - Resume and pause current if exists

	func resume() throws -> TimeInterval {
		if self.audioPlayer?.play() == false {
			print("Audio Player did fail to resume for internal reason")
			throw AudioErrorType.internalError
		}

		print("Resumed sound")
		return self.audioPlayer!.duration - self.audioPlayer!.currentTime
	}

	func pause() throws {
		if !self.isRunning {
			print("Audio Player did fail to start: there is nothing currently playing")
			throw AudioErrorType.notCurrentlyPlaying
		}

		self.audioPlayer?.pause()
		print("Paused current playing sound")
	}

	func stop() throws {
		if !self.isRunning {
			print("Audio Player did fail to stop: there is nothing currently playing")
			throw AudioErrorType.notCurrentlyPlaying
		}
		
		self.audioPlayer?.stop()
		print("Audio player stopped")
	}
	
	// MARK: - Private

	@objc private func timerDidUpdateMeter() {
		if self.isRunning {
			self.audioPlayer!.updateMeters()
			let averagePower = self.audioPlayer!.averagePower(forChannel: 0)
			let percentage: Float = pow(10, (0.05 * averagePower))
			NotificationCenter.default.post(name: .audioPlayerManagerMeteringLevelDidUpdateNotification, object: self, userInfo: [audioPercentageUserInfoKey: percentage])
		}
	}
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		NotificationCenter.default.post(name: .audioPlayerManagerMeteringLevelDidFinishNotification, object: self)
	}
}

extension Notification.Name {
	static let audioPlayerManagerMeteringLevelDidUpdateNotification = Notification.Name("AudioPlayerManagerMeteringLevelDidUpdateNotification")
	static let audioPlayerManagerMeteringLevelDidFinishNotification = Notification.Name("AudioPlayerManagerMeteringLevelDidFinishNotification")
}
