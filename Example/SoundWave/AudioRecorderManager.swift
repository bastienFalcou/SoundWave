//
//  AudioRecorderManager.swift
//  ela
//
//  Created by Bastien Falcou on 4/14/16.
//  Copyright © 2016 Fueled. All rights reserved.
//

import Foundation
import AVFoundation

let audioPercentageUserInfoKey = "percentage"

final class AudioRecorderManager: NSObject {
	let audioFileNamePrefix = "org.cocoapods.demo.SoundWave-Example-Audio-"
	let encoderBitRate: Int = 320000
	let numberOfChannels: Int = 2
	let sampleRate: Double = 44100.0

	static let shared = AudioRecorderManager()

	var isPermissionGranted = false
	var isRunning: Bool {
		guard let recorder = self.recorder, recorder.isRecording else {
			return false
		}
		return true
	}

	var currentRecordPath: URL?

	private var recorder: AVAudioRecorder?
	private var audioMeteringLevelTimer: Timer?

	func askPermission(completion: ((Bool) -> Void)? = nil) {
		AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
			self?.isPermissionGranted = granted
			completion?(granted)
			print("Audio Recorder did not grant permission")
		}
	}

	func startRecording(with audioVisualizationTimeInterval: TimeInterval = 0.05, completion: @escaping (URL?, Error?) -> Void) {
		func startRecordingReturn() {
			do {
				completion(try internalStartRecording(with: audioVisualizationTimeInterval), nil)
			} catch {
				completion(nil, error)
			}
		}
		
		if !self.isPermissionGranted {
			self.askPermission { granted in
				startRecordingReturn()
			}
		} else {
			startRecordingReturn()
		}
	}
	
	fileprivate func internalStartRecording(with audioVisualizationTimeInterval: TimeInterval) throws -> URL {
		if self.isRunning {
			throw AudioErrorType.alreadyPlaying
		}
		
		let recordSettings = [
			AVFormatIDKey: NSNumber(value:kAudioFormatAppleLossless),
			AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
			AVEncoderBitRateKey : self.encoderBitRate,
			AVNumberOfChannelsKey: self.numberOfChannels,
			AVSampleRateKey : self.sampleRate
		] as [String : Any]
		
		guard let path = URL.documentsPath(forFileName: self.audioFileNamePrefix + NSUUID().uuidString) else {
			print("Incorrect path for new audio file")
			throw AudioErrorType.audioFileWrongPath
		}
		
		try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with:.defaultToSpeaker)
		try AVAudioSession.sharedInstance().setActive(true)
		
		self.recorder = try AVAudioRecorder(url: path, settings: recordSettings)
		self.recorder!.delegate = self
		self.recorder!.isMeteringEnabled = true
		
		if !self.recorder!.prepareToRecord() {
			print("Audio Recorder prepare failed")
			throw AudioErrorType.recordFailed
		}
		
		if !self.recorder!.record() {
			print("Audio Recorder start failed")
			throw AudioErrorType.recordFailed
		}
		
		self.audioMeteringLevelTimer = Timer.scheduledTimer(timeInterval: audioVisualizationTimeInterval, target: self,
			selector: #selector(AudioRecorderManager.timerDidUpdateMeter), userInfo: nil, repeats: true)
		
		print("Audio Recorder did start - creating file at index: \(path.absoluteString)")
		
		self.currentRecordPath = path
		return path
	}

	func stopRecording() throws {
		self.audioMeteringLevelTimer?.invalidate()
		self.audioMeteringLevelTimer = nil
		
		if !self.isRunning {
			print("Audio Recorder did fail to stop")
			throw AudioErrorType.notCurrentlyPlaying
		}
		
		self.recorder!.stop()
		print("Audio Recorder did stop successfully")
	}

	func reset() throws {
		if self.isRunning {
			print("Audio Recorder tried to remove recording before stopping it")
			throw AudioErrorType.alreadyRecording
		}
		
		self.recorder?.deleteRecording()
		self.recorder = nil
		self.currentRecordPath = nil
		
		print("Audio Recorder did remove current record successfully")
	}

	@objc func timerDidUpdateMeter() {
		if self.isRunning {
			self.recorder!.updateMeters()
			let averagePower = recorder!.averagePower(forChannel: 0)
			let percentage: Float = pow(10, (0.05 * averagePower))
			NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidUpdateNotification, object: self, userInfo: [audioPercentageUserInfoKey: percentage])
		}
	}
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFinishNotification, object: self)
		print("Audio Recorder finished successfully")
	}

	func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
		NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFailNotification, object: self)
		print("Audio Recorder error")
	}
}

extension Notification.Name {
	static let audioRecorderManagerMeteringLevelDidUpdateNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidUpdateNotification")
	static let audioRecorderManagerMeteringLevelDidFinishNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFinishNotification")
	static let audioRecorderManagerMeteringLevelDidFailNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFailNotification")
}
