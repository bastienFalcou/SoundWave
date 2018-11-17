//
//  Chronometer.swift
//  Pods
//
//  Created by Bastien Falcou on 12/6/16.
//

import Foundation

public final class Chronometer: NSObject {
	private var timer: Timer?
	private var timeInterval: TimeInterval = 1.0

	public var isPlaying = false
	public var timerCurrentValue: TimeInterval = 0.0

	public var timerDidUpdate: ((TimeInterval) -> ())?
	public var timerDidComplete: (() -> ())?

	public init(withTimeInterval timeInterval: TimeInterval = 0.0) {
		super.init()

		self.timeInterval = timeInterval
	}

	public func start(shouldFire fire: Bool = true) {
		self.timer = Timer(timeInterval: self.timeInterval, target: self, selector: #selector(Chronometer.timerDidTrigger), userInfo: nil, repeats: true)
        RunLoop.main.add(self.timer!, forMode: .default)
		self.timer?.fire()
		self.isPlaying = true
	}

	public func pause() {
		self.timer?.invalidate()
		self.timer = nil
		self.isPlaying = false
	}

	public func stop() {
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
