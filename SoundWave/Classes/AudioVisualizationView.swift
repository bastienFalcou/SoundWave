//
//  AudioVisualizationView.swift
//  Pods
//
//  Created by Bastien Falcou on 12/6/16.
//

import UIKit

public class AudioVisualizationView: BaseNibView {
	public enum AudioVisualizationMode {
		case read
		case write
	}

	@IBInspectable public var meteringLevelBarWidth: CGFloat = 3.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	@IBInspectable public var meteringLevelBarInterItem: CGFloat = 2.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	@IBInspectable public var meteringLevelBarCornerRadius: CGFloat = 2.0 {
		didSet {
			self.setNeedsDisplay()
		}
	}

	public var audioVisualizationMode: AudioVisualizationMode = .read
	
	public var audioVisualizationTimeInterval: TimeInterval = 0.05 // Time interval between each metering bar representation

	// Specify a `gradientPercentage` to have the width of gradient be that percentage of the view width (starting from left)
	// The rest of the screen will be filled by `self.gradientStartColor` to display nicely.
	// Do not specify any `gradientPercentage` for gradient calculating fitting size automatically.
	public var currentGradientPercentage: Float?

	private var meteringLevelsArray: [Float] = []	// Mutating recording array (values are percentage: 0.0 to 1.0)
	private var meteringLevelsClusteredArray: [Float] = [] // Generated read mode array (values are percentage: 0.0 to 1.0)

	private var currentMeteringLevelsArray: [Float] {
		if !self.meteringLevelsClusteredArray.isEmpty {
			return meteringLevelsClusteredArray
		}
		return meteringLevelsArray
	}

	private var playChronometer: Chronometer?

	public var meteringLevels: [Float]? {
		didSet {
			if let meteringLevels = self.meteringLevels {
				self.meteringLevelsClusteredArray = meteringLevels
				self.currentGradientPercentage = 0.0
				_ = self.scaleSoundDataToFitScreen()
			}
		}
	}

	static var audioVisualizationDefaultGradientStartColor: UIColor {
		return UIColor(red: 61.0 / 255.0, green: 20.0 / 255.0, blue: 117.0 / 255.0, alpha: 1.0)
	}
	static var audioVisualizationDefaultGradientEndColor: UIColor {
		return UIColor(red: 166.0 / 255.0, green: 150.0 / 255.0, blue: 225.0 / 255.0, alpha: 1.0)
	}
	
	@IBInspectable public var gradientStartColor: UIColor = AudioVisualizationView.audioVisualizationDefaultGradientStartColor {
		didSet {
			self.setNeedsDisplay()
		}
	}
	@IBInspectable public var gradientEndColor: UIColor = AudioVisualizationView.audioVisualizationDefaultGradientEndColor {
		didSet {
			self.setNeedsDisplay()
		}
	}

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

	override public func draw(_ rect: CGRect) {
		super.draw(rect)

		if let context = UIGraphicsGetCurrentContext() {
			self.drawLevelBarsMaskAndGradient(inContext: context)
		}
	}

	public func reset() {
		self.meteringLevels = nil
		self.currentGradientPercentage = nil
		self.meteringLevelsClusteredArray.removeAll()
		self.meteringLevelsArray.removeAll()
		self.setNeedsDisplay()
	}

	// MARK: - Record Mode Handling

	public func add(meteringLevel: Float) {
		guard self.audioVisualizationMode == .write else {
			fatalError("trying to populate audio visualization view in read mode")
		}

		self.meteringLevelsArray.append(meteringLevel)
		self.setNeedsDisplay()
	}

	public func scaleSoundDataToFitScreen() -> [Float] {
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

	public func play(for duration: TimeInterval) {
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

	public func pause() {
		guard let chronometer = self.playChronometer, chronometer.isPlaying else {
			fatalError("trying to pause audio visualization view when not playing")
		}
		self.playChronometer?.pause()
	}

	public func stop() {
		self.playChronometer?.stop()
		self.playChronometer = nil

		self.currentGradientPercentage = 1.0
		self.setNeedsDisplay()
		self.currentGradientPercentage = nil
	}

	// MARK: - Mask + Gradient

	private func drawLevelBarsMaskAndGradient(inContext context: CGContext) {
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

	private func drawGradient(inContext context: CGContext) {
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

	private func drawPlainBackground(inContext context: CGContext, fillFromXCoordinate xCoordinate: CGFloat) {
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

	private func drawMeteringLevelBars(inContext context: CGContext) {
		let offset = max(self.currentMeteringLevelsArray.count - self.maximumNumberBars, 0)

		for index in offset..<self.currentMeteringLevelsArray.count {
			self.drawBar(index - offset, meteringLevelIndex: index, isUpperBar: true, context: context)
			self.drawBar(index - offset, meteringLevelIndex: index, isUpperBar: false, context: context)
		}
	}

	private func drawBar(_ barIndex: Int, meteringLevelIndex: Int, isUpperBar: Bool, context: CGContext) {
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

	private var centerY: CGFloat {
		return self.frame.size.height / 2.0
	}

	private var maximumBarHeight: CGFloat {
		return self.frame.size.height / 2.0
	}

	private var maximumNumberBars: Int {
		return Int(self.frame.size.width / (self.meteringLevelBarWidth + self.meteringLevelBarInterItem))
	}

	private func xLeftMostBar() -> CGFloat {
		return self.xPointForMeteringLevel(min(self.maximumNumberBars - 1, self.currentMeteringLevelsArray.count - 1))
	}

	private func heightForMeteringLevel(_ meteringLevel: Float) -> CGFloat {
		return CGFloat(meteringLevel) * self.maximumBarHeight
	}

	private func xPointForMeteringLevel(_ atIndex: Int) -> CGFloat {
		return CGFloat(atIndex) * (self.meteringLevelBarWidth + self.meteringLevelBarInterItem)
	}
}
