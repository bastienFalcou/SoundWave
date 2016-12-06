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

	var audioMeteringLevelUpdate: ((Float) -> ())?
	var audioPlayerDidFinish: (() -> ())?

	fileprivate var audioPlayer: AVAudioPlayer?
	fileprivate var audioMeteringLevelTimer: Timer?

	// MARK: - Reinit and play from the beginning

	func play(at url: URL) throws -> TimeInterval {
		if AudioRecorderManager.shared.isRunning {
			print("Audio Player did fail to start: AVFoundation is recording")
			throw AudioErrorType.alreadyRecording
		}

		if self.isRunning {
			print("Audio Player did fail to start: already playing a file")
			throw AudioErrorType.alreadyPlaying
		}

		if !URL.checkPath(url.absoluteString) {
			print("Audio Player did fail to start: file doesn't exist")
			throw AudioErrorType.audioFileWrongPath
		}

		try self.audioPlayer = AVAudioPlayer(contentsOf: url)
		self.setupPlayer()
		print("Started to play sound")

		return self.audioPlayer!.duration
	}

	func play(_ data: Data) throws -> TimeInterval {
		try self.audioPlayer = AVAudioPlayer(data: data)
		self.setupPlayer()
		print("Started to play sound")

		return self.audioPlayer!.duration
	}
	
	func setupPlayer() {
		if let player = self.audioPlayer {
			player.play()
			player.isMeteringEnabled = true
			player.delegate = self
			
			self.audioMeteringLevelTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(AudioPlayerManager.timerDidUpdateMeter),
				userInfo: nil, repeats: true)
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

	@objc internal func timerDidUpdateMeter() {
		if self.isRunning {
			self.audioPlayer!.updateMeters()
			let averagePower = self.audioPlayer!.averagePower(forChannel: 0)
			let percentage: Float = pow(10, (0.05 * averagePower))
			self.audioMeteringLevelUpdate?(percentage)
		}
	}
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		self.audioPlayerDidFinish?()
	}
}

extension URL {
	static func checkPath(_ path: String) -> Bool {
		var directory: ObjCBool = ObjCBool(false)
		if FileManager.default.fileExists(atPath: path, isDirectory:&directory) {
			return !directory.boolValue
		}
		return false
	}
}
