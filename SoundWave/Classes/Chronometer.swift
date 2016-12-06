//
//  Chronometer.swift
//  Pods
//
//  Created by Bastien Falcou on 12/6/16.
//

import Foundation

final class Chronometer: NSObject {
	fileprivate var timer: Timer?
	fileprivate var timeInterval: TimeInterval = 1.0

	var isPlaying = false
	var timerCurrentValue: TimeInterval = 0.0

	var timerDidUpdate: ((TimeInterval) -> ())?
	var timerDidComplete: (() -> ())?
	
	override init() {
		super.init()
	}

	init(withTimeInterval timeInterval: TimeInterval) {
		super.init()

		self.timeInterval = timeInterval
	}

	func start(shouldFire fire: Bool = true) {
		self.timer = Timer(timeInterval: self.timeInterval, target: self, selector: #selector(Chronometer.timerDidTrigger), userInfo: nil, repeats: true)
		RunLoop.main.add(self.timer!, forMode: RunLoopMode.defaultRunLoopMode)
		self.timer?.fire()
		self.isPlaying = true
	}

	func pause() {
		self.timer?.invalidate()
		self.timer = nil
		self.isPlaying = false
	}

	func stop() {
		self.isPlaying = false
		self.timer?.invalidate()
		self.timer = nil
		self.timerCurrentValue = 0.0
		self.timerDidComplete?()
	}

	// MARK: - Private

	@objc fileprivate func timerDidTrigger() {
		self.timerDidUpdate?(self.timerCurrentValue)
		self.timerCurrentValue += self.timeInterval
	}
}
