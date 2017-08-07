import Foundation
import AudioKit

@objc open class CustomFFT: NSObject, EZAudioFFTDelegate {
    
    internal let bufferSize: UInt32 = 512
    internal var fft: EZAudioFFT?
    let freqRange = [40, 80, 120, 180, 300]
    open var freqMax = [Float](zeros: 6)
    open var freqDict = [Int](zeros: 6)
    open var fftData = [Double](zeros: 256) //old: 512
    
    public init(_ input: AKNode) {
        super.init()
        fft = EZAudioFFT(maximumBufferSize: vDSP_Length(bufferSize), sampleRate: Float(AKSettings.sampleRate), delegate: self)
        input.avAudioNode.installTap(onBus: 0, bufferSize: bufferSize, format: AudioKit.format) { [weak self] (buffer, time) -> Void in
            guard let strongSelf = self else { return }
            buffer.frameLength = strongSelf.bufferSize
            let offset = Int(buffer.frameCapacity - buffer.frameLength)
            let tail = buffer.floatChannelData?[0]
            strongSelf.fft!.computeFFT(withBuffer: &tail![offset],
                                       withBufferSize: strongSelf.bufferSize)
        }
    }
    
    func getIndex(_ freq: Int) -> Int {
        var i = 0
        while (freqRange[i] < freq) {
            i += 1
        }
        return i
    }
    
    /// Callback function for FFT computation
    @objc open func fft(_ fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>, bufferSize: vDSP_Length) {
        DispatchQueue.main.async { () -> Void in
//            for i in 0..<256 { //old: 512
//                let freq = Int(fft.frequency(at: vDSP_Length(i)))
//                if freq >= 30 && freq <= 300 {
//                    let magnitude = fft.frequencyMagnitude(at: vDSP_Length(i))
//                    let index = self.getIndex(freq)
//                    if magnitude > self.freqMax[index] {
//                        self.freqMax[index] = magnitude
//                        self.freqDict[index] = freq
//                    }
//                }
//            }
            for i in 0..<256 { //old: 512
                self.fftData[i] = Double(fftData[i])
            }
        }
    }
}
