//
//  AudioVisualizationView.swift
//  Pods
//
//  Created by Bastien Falcou on 12/6/16.
//

import UIKit

class AudioVisualizationView: BaseNibView {
	enum AudioVisualizationMode {
		case read
		case write
	}

	var meteringLevelBarWidth: CGFloat = 3.0
	var meteringLevelBarInterItem: CGFloat = 2.0
	var meteringLevelBarCornerRadius: CGFloat = 2.0

	var audioVisualizationMode: AudioVisualizationMode = .read
	
	var audioVisualizationTimeInterval: TimeInterval = 0.05 // Time interval between each metering bar representation

	// Specify a `gradientPercentage` to have the width of gradient be that percentage of the view width (starting from left)
	// The rest of the screen will be filled by `self.gradientStartColor` to display nicely.
	// Do not specify any `gradientPercentage` for gradient calculating fitting size automatically.
	var currentGradientPercentage: Float?

	var meteringLevelsArray: [Float] = []	// Mutating recording array (values are percentage: 0.0 to 1.0)
	fileprivate(set) var meteringLevelsClusteredArray: [Float] = [] // Generated read mode array (values are percentage: 0.0 to 1.0)

	fileprivate var currentMeteringLevelsArray: [Float] {
		if !self.meteringLevelsClusteredArray.isEmpty {
			return meteringLevelsClusteredArray
		}
		return meteringLevelsArray
	}

	fileprivate var playChronometer: Chronometer?

	var meteringLevels: [Float]? {
		didSet {
			if let meteringLevels = self.meteringLevels {
				self.meteringLevelsClusteredArray = meteringLevels
				self.currentGradientPercentage = 0.0
				_ = self.scaleSoundDataToFitScreen()
			}
		}
	}

	static var audioVisualizationDefaultGradientStartColor: UIColor {
		return UIColor(red: 76.0 / 255.0, green: 62.0 / 255.0, blue: 127.0 / 255.0, alpha: 1.0)
	}
	
	static var audioVisualizationDefaultGradientEndColor: UIColor {
		return UIColor(red: 133.0 / 255.0, green: 112.0 / 255.0, blue: 190.0 / 255.0, alpha: 1.0)
	}
	
	@IBInspectable var gradientStartColor: UIColor = AudioVisualizationView.audioVisualizationDefaultGradientStartColor {
		didSet {
			self.setNeedsDisplay()
		}
	}

	@IBInspectable var gradientEndColor: UIColor = AudioVisualizationView.audioVisualizationDefaultGradientEndColor {
		didSet {
			self.setNeedsDisplay()
		}
	}

	override func draw(_ rect: CGRect) {
		super.draw(rect)

		if let context = UIGraphicsGetCurrentContext() {
			self.drawLevelBarsMaskAndGradient(inContext: context)
		}
	}

	func reset() {
		self.meteringLevels = nil
		self.currentGradientPercentage = nil
		self.meteringLevelsClusteredArray.removeAll()
		self.meteringLevelsArray.removeAll()
		self.setNeedsDisplay()
	}

	// MARK: - Record Mode Handling

	func addMeteringLevel(_ meteringLevel: Float) {
		guard self.audioVisualizationMode == .write else {
			fatalError("trying to populate audio visualization view in read mode")
		}

		self.meteringLevelsArray.append(meteringLevel)
		self.setNeedsDisplay()
	}

	func scaleSoundDataToFitScreen() -> [Float] {
		if self.meteringLevelsArray.isEmpty {
			return []
		}

		self.meteringLevelsClusteredArray.removeAll()
		var lastPosition: Int = 0

		for index in 0..<self.maximumNumberBars {
			let position: Float = Float(index) / Float(self.maximumNumberBars) * Float(self.meteringLevelsArray.count)
			var h: Float = 0.0

			if self.maximumNumberBars > self.meteringLevelsArray.count && floor(position) != position {
				let low: Int = Int(floor(position))
				let high: Int = Int(ceil(position))

				if high < self.meteringLevelsArray.count {
					h = self.meteringLevelsArray[low] + ((position - Float(low)) * (self.meteringLevelsArray[high] - self.meteringLevelsArray[low]))
				} else {
					h = self.meteringLevelsArray[low]
				}
			} else {
				for nestedIndex in lastPosition...Int(position) {
					h += self.meteringLevelsArray[nestedIndex]
				}
				let stepsNumber = Int(1 + position - Float(lastPosition))
				h = h / Float(stepsNumber)
			}

			lastPosition = Int(position)
			self.meteringLevelsClusteredArray.append(h)
		}
		self.setNeedsDisplay()
		return self.meteringLevelsClusteredArray
	}

	// PRAGMA: - Play Mode Handling

	func play(forDuration duration: TimeInterval) {
		guard self.audioVisualizationMode == .read else {
			fatalError("trying to read audio visualization in write mode")
		}

		guard self.meteringLevels != nil else {
			fatalError("trying to read audio visualization of non initialized sound record")
		}

		if let currentChronometer = self.playChronometer {
			currentChronometer.start() // resume current
			return
		}

		self.playChronometer = Chronometer(withTimeInterval: self.audioVisualizationTimeInterval)
		self.playChronometer?.start(shouldFire: false)

		self.playChronometer?.timerDidUpdate = { [weak self] timerDuration in
			guard let this = self else {
				return
			}
			
			if timerDuration >= duration {
				this.stop()
				return
			}
			
			this.currentGradientPercentage = Float(timerDuration) / Float(duration)
			this.setNeedsDisplay()
		}
	}

	func pause() {
		guard let chronometer = self.playChronometer, chronometer.isPlaying else {
			fatalError("trying to pause audio visualization view when not playing")
		}
		self.playChronometer?.pause()
	}

	func stop() {
		self.playChronometer?.stop()
		self.playChronometer = nil

		self.currentGradientPercentage = 1.0
		self.setNeedsDisplay()
		self.currentGradientPercentage = nil
	}

	// MARK: - Mask + Gradient

	fileprivate func drawLevelBarsMaskAndGradient(inContext context: CGContext) {
		if self.currentMeteringLevelsArray.isEmpty {
			return
		}

		context.saveGState()

		UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0.0)

		let maskContext = UIGraphicsGetCurrentContext()
		UIColor.black.set()

		self.drawMeteringLevelBars(inContext: maskContext!)

		let mask = UIGraphicsGetCurrentContext()?.makeImage()
		UIGraphicsEndImageContext()

		context.clip(to: self.bounds, mask: mask!)

		self.drawGradient(inContext: context)

		context.restoreGState()
	}

	fileprivate func drawGradient(inContext context: CGContext) {
		if self.currentMeteringLevelsArray.isEmpty {
			return
		}

		context.saveGState()

		let startPoint = CGPoint(x: 0.0, y: self.centerY)
		var endPoint = CGPoint(x: self.xLeftMostBar() + self.meteringLevelBarWidth, y: self.centerY)

		if let gradientPercentage = self.currentGradientPercentage {
			endPoint = CGPoint(x: self.frame.size.width * CGFloat(gradientPercentage), y: self.centerY)
		}

		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let colorLocations: [CGFloat] = [0.0, 1.0]
		let colors = [self.gradientStartColor.cgColor, self.gradientEndColor.cgColor]

		let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)

		context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))

		context.restoreGState()

		if self.currentGradientPercentage != nil {
			self.drawPlainBackground(inContext: context, fillFromXCoordinate: endPoint.x)
		}
	}

	fileprivate func drawPlainBackground(inContext context: CGContext, fillFromXCoordinate xCoordinate: CGFloat) {
		context.saveGState()

		let squarePath = UIBezierPath()

		squarePath.move(to: CGPoint(x: xCoordinate, y: 0.0))
		squarePath.addLine(to: CGPoint(x: self.frame.size.width, y: 0.0))
		squarePath.addLine(to: CGPoint(x: self.frame.size.width, y: self.frame.size.height))
		squarePath.addLine(to: CGPoint(x: xCoordinate, y: self.frame.size.height))

		squarePath.close()
		squarePath.addClip()

		self.gradientStartColor.setFill()
		squarePath.fill()

		context.restoreGState()
	}

	// MARK: - Bars

	fileprivate func drawMeteringLevelBars(inContext context: CGContext) {
		let offset = max(self.currentMeteringLevelsArray.count - self.maximumNumberBars, 0)

		for index in offset..<self.currentMeteringLevelsArray.count {
			self.drawBar(index - offset, meteringLevelIndex: index, isUpperBar: true, context: context)
			self.drawBar(index - offset, meteringLevelIndex: index, isUpperBar: false, context: context)
		}
	}

	fileprivate func drawBar(_ barIndex: Int, meteringLevelIndex: Int, isUpperBar: Bool, context: CGContext) {
		context.saveGState()

		var barPath: UIBezierPath!

		let xPointForMeteringLevel = self.xPointForMeteringLevel(barIndex)
		let heightForMeteringLevel = self.heightForMeteringLevel(self.currentMeteringLevelsArray[meteringLevelIndex])

		if isUpperBar {
			barPath = UIBezierPath(roundedRect: CGRect(x: xPointForMeteringLevel, y: self.centerY - heightForMeteringLevel,
				width: self.meteringLevelBarWidth, height: heightForMeteringLevel), cornerRadius: self.meteringLevelBarCornerRadius)
		} else {
			barPath = UIBezierPath(roundedRect: CGRect(x: xPointForMeteringLevel, y: self.centerY, width: self.meteringLevelBarWidth,
				height: heightForMeteringLevel), cornerRadius: self.meteringLevelBarCornerRadius)
		}

		UIColor.black.set()
		barPath.fill()

		context.restoreGState()
	}

	// MARK: - Points Helpers

	fileprivate var centerY: CGFloat {
		return self.frame.size.height / 2.0
	}

	fileprivate var maximumBarHeight: CGFloat {
		return self.frame.size.height / 2.0
	}

	fileprivate var maximumNumberBars: Int {
		return Int(self.frame.size.width / (self.meteringLevelBarWidth + self.meteringLevelBarInterItem))
	}

	fileprivate func xLeftMostBar() -> CGFloat {
		return self.xPointForMeteringLevel(min(self.maximumNumberBars - 1, self.currentMeteringLevelsArray.count - 1))
	}

	fileprivate func heightForMeteringLevel(_ meteringLevel: Float) -> CGFloat {
		return CGFloat(meteringLevel) * self.maximumBarHeight
	}

	fileprivate func xPointForMeteringLevel(_ atIndex: Int) -> CGFloat {
		return CGFloat(atIndex) * (self.meteringLevelBarWidth + self.meteringLevelBarInterItem)
	}
}
