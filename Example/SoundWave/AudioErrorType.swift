//
//  AudioErrorType.swift
//  ela
//
//  Created by Bastien Falcou on 4/14/16.
//  Copyright © 2016 Fueled. All rights reserved.
//

import Foundation

enum AudioErrorType: Error {
	case alreadyRecording
	case alreadyPlaying
	case notCurrentlyPlaying
	case audioFileWrongPath
	case recordFailed
	case playFailed
	case recordPermissionNotGranted
	case internalError

	/*
	var error: Error {
		var userInfo: [AnyHashable: Any]!

		switch self {
		case .alreadyRecording:
			userInfo = [NSLocalizedDescriptionKey: "Already Recording",
				NSLocalizedFailureReasonErrorKey: "The application is currently recording sounds"]
		case .alreadyPlaying:
			userInfo = [NSLocalizedDescriptionKey: "Already Playing",
				NSLocalizedFailureReasonErrorKey: "The application is already playing a sound"]
		case .notCurrentlyPlaying:
			userInfo = [NSLocalizedDescriptionKey: "Not Currently Playing",
				NSLocalizedFailureReasonErrorKey: "The application is not currently playing"]
		case .audioFileWrongPath:
			userInfo = [NSLocalizedDescriptionKey: "Wrong Audio File Path",
				NSLocalizedFailureReasonErrorKey: "Invalid path for audio file"]
		case .recordFailed:
			userInfo = [NSLocalizedDescriptionKey: "Record Failed",
				NSLocalizedFailureReasonErrorKey: "Unable to record sound at the moment, please try again"]
		case .playFailed:
			userInfo = [NSLocalizedDescriptionKey: "Play failed",
				NSLocalizedFailureReasonErrorKey: "Unable to play sound at the moment, please try again"]
		case .recordPermissionNotGranted:
			userInfo = [NSLocalizedDescriptionKey: "Record Permission Not Granted",
				NSLocalizedFailureReasonErrorKey: "Unable to record sound because the permission has not been granted. This can be changed in your settings."]
		case .internalError:
			userInfo = [NSLocalizedDescriptionKey: "Error occured",
				NSLocalizedFailureReasonErrorKey: "An error occured while trying to process audio command, please try again"]
		}
		return Error(domain: AudioErrorType.audioErrorTypeDomain, code: self.rawValue, userInfo: userInfo)
	}
	*/
	static let audioErrorTypeDomain = "org.cocoapods.demo.SoundWave-Example.audioError"
}
