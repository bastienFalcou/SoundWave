//
//  ViewController.swift
//  SoundWave
//
//  Created by Bastien Falcou on 12/06/2016.
//  Copyright (c) 2016 Bastien Falcou. All rights reserved.
//

import UIKit
import SoundWave

final class ViewController: UIViewController {
    enum AudioRecodingState {
        case ready
        case recording
        case recorded
        case playing
        case paused

        var buttonImage: UIImage {
            switch self {
            case .ready, .recording:
                return #imageLiteral(resourceName: "Record-Button")
            case .recorded, .paused:
                return #imageLiteral(resourceName: "Play-Button")
            case .playing:
                return #imageLiteral(resourceName: "Pause-Button")
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

    @IBOutlet private var recordButton: UIButton!
    @IBOutlet private var clearButton: UIButton!
    @IBOutlet private var audioVisualizationView: AudioVisualizationView!

    @IBOutlet private var optionsView: UIView!
    @IBOutlet private var optionsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var audioVisualizationTimeIntervalLabel: UILabel!
    @IBOutlet private var meteringLevelBarWidthLabel: UILabel!
    @IBOutlet private var meteringLevelSpaceInterBarLabel: UILabel!

    private let viewModel = ViewModel()

    private var currentState: AudioRecodingState = .ready {
        didSet {
            self.recordButton.setImage(self.currentState.buttonImage, for: .normal)
            self.audioVisualizationView.audioVisualizationMode = self.currentState.audioVisualizationMode
            self.clearButton.isHidden = self.currentState == .ready || self.currentState == .playing || self.currentState == .recording
        }
    }

    private var chronometer: Chronometer?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewModel.askAudioRecordingPermission()

        self.viewModel.audioMeteringLevelUpdate = { [weak self] meteringLevel in
            guard let self = self, self.audioVisualizationView.audioVisualizationMode == .write else {
                return
            }
            self.audioVisualizationView.add(meteringLevel: meteringLevel)
        }

        self.viewModel.audioDidFinish = { [weak self] in
            self?.currentState = .recorded
            self?.audioVisualizationView.stop()
        }
    }

    // MARK: - Actions

    @IBAction private func recordButtonDidTouchDown(_ sender: AnyObject) {
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

    @IBAction private func recordButtonDidTouchUpInside(_ sender: AnyObject) {
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

    @IBAction private func clearButtonTapped(_ sender: AnyObject) {
        do {
            try self.viewModel.resetRecording()
            self.audioVisualizationView.reset()
            self.currentState = .ready
        } catch {
            self.showAlert(with: error)
        }
    }

    @IBAction private func switchValueChanged(_ sender: AnyObject) {
        let theSwitch = sender as! UISwitch
        if theSwitch.isOn {
            self.view.backgroundColor = .mainBackgroundPurple
            self.audioVisualizationView.gradientStartColor = .audioVisualizationPurpleGradientStart
            self.audioVisualizationView.gradientEndColor = .audioVisualizationPurpleGradientEnd
        } else {
            self.view.backgroundColor = .mainBackgroundGray
            self.audioVisualizationView.gradientStartColor = .audioVisualizationGrayGradientStart
            self.audioVisualizationView.gradientEndColor = .audioVisualizationGrayGradientEnd
        }
    }

    @IBAction private func audioVisualizationTimeIntervalSliderValueDidChange(_ sender: AnyObject) {
        let audioVisualizationTimeIntervalSlider = sender as! UISlider
        self.viewModel.audioVisualizationTimeInterval = TimeInterval(audioVisualizationTimeIntervalSlider.value)
        self.audioVisualizationTimeIntervalLabel.text = String(format: "%.2f", self.viewModel.audioVisualizationTimeInterval)
    }

    @IBAction private func meteringLevelBarWidthSliderValueChanged(_ sender: AnyObject) {
        let meteringLevelBarWidthSlider = sender as! UISlider
        self.audioVisualizationView.meteringLevelBarWidth = CGFloat(meteringLevelBarWidthSlider.value)
        self.meteringLevelBarWidthLabel.text = String(format: "%.2f", self.audioVisualizationView.meteringLevelBarWidth)
    }

    @IBAction private func meteringLevelSpaceInterBarSliderValueChanged(_ sender: AnyObject) {
        let meteringLevelSpaceInterBarSlider = sender as! UISlider
        self.audioVisualizationView.meteringLevelBarInterItem = CGFloat(meteringLevelSpaceInterBarSlider.value)
        self.meteringLevelSpaceInterBarLabel.text = String(format: "%.2f", self.audioVisualizationView.meteringLevelBarWidth)
    }

    @IBAction private func optionsButtonTapped(_ sender: AnyObject) {
        let shouldExpand = self.optionsViewHeightConstraint.constant == 0
        self.optionsViewHeightConstraint.constant = shouldExpand ? 165.0 : 0.0
        UIView.animate(withDuration: 0.2) {
            self.optionsView.subviews.forEach { $0.alpha = shouldExpand ? 1.0 : 0.0 }
            self.view.layoutIfNeeded()
        }
    }
}
