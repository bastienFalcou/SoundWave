//
//  AudioContext.swift
//  Pods-SoundWave_Example
//
//  Created by Bastien Falcou on 4/27/19.
//  Inspired from https://stackoverflow.com/a/52280271
//

import Accelerate
import AVFoundation

public final class AudioContext {
	public let audioURL: URL
	public let totalSamples: Int
	public let asset: AVAsset
	public let assetTrack: AVAssetTrack

	private init(audioURL: URL, totalSamples: Int, asset: AVAsset, assetTrack: AVAssetTrack) {
		self.audioURL = audioURL
		self.totalSamples = totalSamples
		self.asset = asset
		self.assetTrack = assetTrack
	}

	public static func load(fromAudioURL audioURL: URL, completionHandler: @escaping (_ audioContext: AudioContext?) -> ()) {
		let asset = AVURLAsset(url: audioURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)])

		guard let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
			fatalError("Couldn't load AVAssetTrack")
		}

		asset.loadValuesAsynchronously(forKeys: ["duration"]) {
			var error: NSError?
			let status = asset.statusOfValue(forKey: "duration", error: &error)
			switch status {
			case .loaded:
				guard let formatDescriptions = assetTrack.formatDescriptions as? [CMAudioFormatDescription],
					let audioFormatDesc = formatDescriptions.first,
					let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc) else
				{
					break
				}
				let totalSamples = Int((asbd.pointee.mSampleRate) * Float64(asset.duration.value) / Float64(asset.duration.timescale))
				let audioContext = AudioContext(audioURL: audioURL, totalSamples: totalSamples, asset: asset, assetTrack: assetTrack)
				completionHandler(audioContext)
			case .failed, .cancelled, .loading, .unknown:
				print("Couldn't load asset: \(error?.localizedDescription ?? "Unknown error")")
				completionHandler(nil)
			@unknown default:
				print("Couldn't load asset, unknown default: \(error?.localizedDescription ?? "Unknown error")")
				completionHandler(nil)
			}
		}
	}

	public func render(targetSamples: Int = 100) -> [Float] {
		let sampleRange: CountableRange<Int> = 0..<self.totalSamples / 3

		guard let reader = try? AVAssetReader(asset: self.asset) else {
			fatalError("Couldn't initialize the AVAssetReader")
		}

		reader.timeRange = CMTimeRange(
			start: CMTime(value: Int64(sampleRange.lowerBound), timescale: self.asset.duration.timescale),
			duration: CMTime(value: Int64(sampleRange.count), timescale: self.asset.duration.timescale)
		)

		let outputSettingsDict: [String : Any] = [
			AVFormatIDKey: Int(kAudioFormatLinearPCM),
			AVLinearPCMBitDepthKey: 16,
			AVLinearPCMIsBigEndianKey: false,
			AVLinearPCMIsFloatKey: false,
			AVLinearPCMIsNonInterleaved: false
		]

		let readerOutput = AVAssetReaderTrackOutput(track: self.assetTrack, outputSettings: outputSettingsDict)
		readerOutput.alwaysCopiesSampleData = false
		reader.add(readerOutput)

		var channelCount = 1
		let formatDescriptions = self.assetTrack.formatDescriptions as! [CMAudioFormatDescription]
		for item in formatDescriptions {
			guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item) else {
				fatalError("Couldn't get the format description")
			}
			channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
		}

		let samplesPerPixel = max(1, channelCount * sampleRange.count / targetSamples)
		let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)

		var outputSamples = [Float]()
		var sampleBuffer = Data()

		// 16-bit samples
		reader.startReading()
		defer { reader.cancelReading() }

		while reader.status == .reading {
			guard let readSampleBuffer = readerOutput.copyNextSampleBuffer(),
				let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
					break
			}
			// Append audio sample buffer into our current sample buffer
			var readBufferLength = 0
			var readBufferPointer: UnsafeMutablePointer<Int8>?
			CMBlockBufferGetDataPointer(readBuffer,
										atOffset: 0,
										lengthAtOffsetOut: &readBufferLength,
										totalLengthOut: nil,
										dataPointerOut: &readBufferPointer)
			sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
			CMSampleBufferInvalidate(readSampleBuffer)

			let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
			let downSampledLength = totalSamples / samplesPerPixel
			let samplesToProcess = downSampledLength * samplesPerPixel

			guard samplesToProcess > 0 else { continue }

			processSamples(fromData: &sampleBuffer,
						   outputSamples: &outputSamples,
						   samplesToProcess: samplesToProcess,
						   downSampledLength: downSampledLength,
						   samplesPerPixel: samplesPerPixel,
						   filter: filter)
		}

		// Process the remaining samples at the end which didn't fit into samplesPerPixel
		let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
		if samplesToProcess > 0 {
			let downSampledLength = 1
			let samplesPerPixel = samplesToProcess
			let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)

			processSamples(fromData: &sampleBuffer,
						   outputSamples: &outputSamples,
						   samplesToProcess: samplesToProcess,
						   downSampledLength: downSampledLength,
						   samplesPerPixel: samplesPerPixel,
						   filter: filter)
		}

		guard reader.status == .completed || true else {
			fatalError("Couldn't read the audio file")
		}

		return self.percentage(outputSamples)
	}

	private func processSamples(fromData sampleBuffer: inout Data,
						outputSamples: inout [Float],
						samplesToProcess: Int,
						downSampledLength: Int,
						samplesPerPixel: Int,
						filter: [Float]) {
        sampleBuffer.withUnsafeBytes { (body: UnsafeRawBufferPointer) in
            var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
            let sampleCount = vDSP_Length(samplesToProcess)

            guard let samples = body.bindMemory(to: Int16.self).baseAddress else {
                return
            }

            // Convert 16bit int samples to floats
            vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)

            // Take the absolute values to get amplitude
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)

            // Get the corresponding dB, and clip the results
            getdB(from: &processingBuffer)

            // Downsample and average
            var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter, &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))

            // Remove processed samples
            sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)

            outputSamples += downSampledData
        }
	}

	private func getdB(from normalizedSamples: inout [Float]) {
		// Convert samples to a log scale
		var zero: Float = 32768.0
		vDSP_vdbcon(normalizedSamples, 1, &zero, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count), 1)

		// Clip to [noiseFloor, 0]
		var ceil: Float = 0.0
		var noiseFloorMutable: Float = -80.0 // TODO: CHANGE THIS VALUE
		vDSP_vclip(normalizedSamples, 1, &noiseFloorMutable, &ceil, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count))
	}

	private func percentage(_ array: [Float]) -> [Float] {
		guard let firstElement = array.first else {
			return []
		}
		let absArray = array.map { abs($0) }
		let minValue = absArray.reduce(firstElement) { min($0, $1) }
		let maxValue = absArray.reduce(firstElement) { max($0, $1) }
		let delta = maxValue - minValue
		return absArray.map { abs(1 - (delta / ($0 - minValue))) }
	}
}
