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
	}
	
	@IBOutlet var recordButton: UIButton!
	@IBOutlet var clearButton: UIButton!
	@IBOutlet var audioVisualizationView: AudioVisualizationView!
	
	@IBOutlet var optionsView: UIView!
	@IBOutlet var optionsViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet var audioVisualizationTimeIntervalLabel: UILabel!
	@IBOutlet var meteringLevelBarWidthLabel: UILabel!
	@IBOutlet var meteringLevelSpaceInterBarLabel: UILabel!
	
	let viewModel = ViewModel()

	var currentState: AudioRecodingState = .ready {
		didSet {
			self.recordButton.setImage(self.currentState.buttonImage, for: UIControlState())
			self.audioVisualizationView.audioVisualizationMode = self.currentState.audioVisualizationMode
			self.clearButton.isHidden = self.currentState == .ready || self.currentState == .playing || self.currentState == .recording
		}
	}
	
	private var chronometer: Chronometer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.viewModel.askAudioRecordingPermission()
		
		self.viewModel.audioMeteringLevelUpdate = { [weak self] meteringLevel in
			guard let this = self, this.audioVisualizationView.audioVisualizationMode == .write else {
				return
			}
			this.audioVisualizationView.addMeteringLevel(meteringLevel)
		}
		
		self.viewModel.audioDidFinish = { [weak self] in
			self?.currentState = .recorded
			self?.audioVisualizationView.stop()
		}
	}
	
	// MARK: - Actions
	
	@IBAction func recordButtonDidTouchDown(_ sender: AnyObject) {
		if self.currentState == .ready {
			self.viewModel.startRecording { [weak self] soundRecord, error in
				if let error = error {
					self?.showAlert(with: error)
					return
				}
				
				self?.currentState = .recording
				
				self?.chronometer = Chronometer()
				self?.chronometer?.start()
			}
		}
	}
	
	@IBAction func recordButtonDidTouchUpInside(_ sender: AnyObject) {
		switch self.currentState {
		case .recording:
			self.chronometer?.stop()
			self.chronometer = nil
			
			self.viewModel.currentAudioRecord!.meteringLevels = self.audioVisualizationView.scaleSoundDataToFitScreen()
			self.audioVisualizationView.audioVisualizationMode = .read
		
			do {
				try self.viewModel.stopRecording()
				self.currentState = .recorded
			} catch {
				self.currentState = .ready
				self.showAlert(with: error)
			}
		case .recorded, .paused:
			do {
				let duration = try self.viewModel.startPlaying()
				self.currentState = .playing
				self.audioVisualizationView.meteringLevels = self.viewModel.currentAudioRecord!.meteringLevels
				self.audioVisualizationView.play(for: duration)
			} catch {
				self.showAlert(with: error)
			}
		case .playing:
			do {
				try self.viewModel.pausePlaying()
				self.currentState = .paused
				self.audioVisualizationView.pause()
			} catch {
				self.showAlert(with: error)
			}
		default:
			break
		}
	}
	
	@IBAction func clearButtonTapped(_ sender: AnyObject) {
		do {
			try self.viewModel.resetRecording()
			self.audioVisualizationView.reset()
			self.currentState = .ready
		} catch {
			self.showAlert(with: error)
		}
	}
	
	@IBAction func switchValueChanged(_ sender: AnyObject) {
		let theSwitch = sender as! UISwitch
		if theSwitch.isOn {
			self.view.backgroundColor = UIColor.mainBackgroundPurple
			self.audioVisualizationView.gradientStartColor = UIColor.audioVisualizationPurpleGradientStart
			self.audioVisualizationView.gradientEndColor = UIColor.audioVisualizationPurpleGradientEnd
		} else {
			self.view.backgroundColor = UIColor.mainBackgroundGray
			self.audioVisualizationView.gradientStartColor = UIColor.audioVisualizationGrayGradientStart
			self.audioVisualizationView.gradientEndColor = UIColor.audioVisualizationGrayGradientEnd
		}
	}
	
	@IBAction func audioVisualizationTimeIntervalSliderValueDidChange(_ sender: AnyObject) {
		let audioVisualizationTimeIntervalSlider = sender as! UISlider
		self.viewModel.audioVisualizationTimeInterval = TimeInterval(audioVisualizationTimeIntervalSlider.value)
		self.audioVisualizationTimeIntervalLabel.text = String(format: "%.2f", self.viewModel.audioVisualizationTimeInterval)
	}

	@IBAction func meteringLevelBarWidthSliderValueChanged(_ sender: AnyObject) {
		let meteringLevelBarWidthSlider = sender as! UISlider
		self.audioVisualizationView.meteringLevelBarWidth = CGFloat(meteringLevelBarWidthSlider.value)
		self.meteringLevelBarWidthLabel.text = String(format: "%.2f", self.audioVisualizationView.meteringLevelBarWidth)
	}
	
	@IBAction func meteringLevelSpaceInterBarSliderValueChanged(_ sender: AnyObject) {
		let meteringLevelSpaceInterBarSlider = sender as! UISlider
		self.audioVisualizationView.meteringLevelBarInterItem = CGFloat(meteringLevelSpaceInterBarSlider.value)
		self.meteringLevelSpaceInterBarLabel.text = String(format: "%.2f", self.audioVisualizationView.meteringLevelBarWidth)
	}
	
	@IBAction func optionsButtonTapped(_ sender: AnyObject) {
		let shouldExpand = self.optionsViewHeightConstraint.constant == 0
		self.optionsViewHeightConstraint.constant = shouldExpand ? 165.0 : 0.0
		UIView.animate(withDuration: 0.2) {
			self.optionsView.subviews.forEach { $0.alpha = shouldExpand ? 1.0 : 0.0 }
			self.view.layoutIfNeeded()
		}
	}
}
