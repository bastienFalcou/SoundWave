//
//  ViewController.swift
//  SoundWave
//
//  Created by Bastien Falcou on 12/06/2016.
//  Copyright (c) 2016 Bastien Falcou. All rights reserved.
//

import UIKit
import SoundWave

class ViewController: UIViewController {
	enum AudioRecodingState {
		case ready
		case recording
		case recorded
		case playing
		case paused
		
		var buttonImage: UIImage {
			switch self {
			case .ready, .recording:
				return UIImage(named: "Record-Button")!
			case .recorded, .paused:
				return UIImage(named: "Play-Button")!
			case .playing:
				return UIImage(named: "Pause-Button")!
			}
		}
		
		var audioVisualizationMode: AudioVisualizationView.AudioVisualizationMode {
			switch self {
			case .ready, .recording:
				return .write
			case .paused, .playing, .recorded:
				return .read
			}
		}
		
		var showsProgress: Bool {
			switch self {
			case .ready, .recording:
				return true
			default:
				return false
			}
		}
		
		var showGlow: Bool {
			switch self {
			case .recorded, .playing, .paused:
				return true
			default:
				return false
			}
		}
	}
	
	@IBOutlet var audioVisualizationView: AudioVisualizationView!
	@IBOutlet var recordButton: UIButton!

	var currentState: AudioRecodingState = .ready {
		didSet {
			self.recordButton.setImage(self.currentState.buttonImage, for: UIControlState())
			//self.centerButton.showCircleProgressBar = self.currentState.showsProgress
			//self.centerButton.applyGlow(self.currentState.showGlow, color: UIColor.mainPurpleColor)
			self.audioVisualizationView.audioVisualizationMode = self.currentState.audioVisualizationMode
		}
	}
	
	fileprivate var chronometer: Chronometer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// TODO: Set value instead of 0.05 defined here
		/*
		self.viewModel.audioMeteringLevelSignal.observeValues { [weak self] soundIntensity in
			guard let this = self, self?.audioVisualizationView.audioVisualizationMode == .write else
			{
				return
			}
			this.audioVisualizationView.addMeteringLevel(soundIntensity)
		}
		
		self.viewModel.playingAudioDidFinishSignal.observeValues { [weak self] _ in
			self?.currentState = .recorded
			self?.audioVisualizationView.stop()
		}*/
	}
	
	/*
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if self.currentState == .playing {
			self.currentState = .recorded
			AudioPlayerManager.sharedManager.stop().start()
		}
		self.audioVisualizationView.stop()
		_ = self.viewModel.resetRecording()
	}
	*/
	
	// MARK: - Actions
	
	@IBAction func recordButtonDidTouchDown(_ sender: AnyObject) {
		self.currentState = .recording
		
		self.chronometer = Chronometer()
		self.chronometer?.start()
	}
	
	@IBAction func recordButtonDidTouchUpInside(_ sender: AnyObject) {
	}
}
