//
//  ContentView.swift
//  Drum Sampler
//
//  Created by Michael Kazmerski on 11/8/21.
//
import AudioKit
import AudioKitUI
import AVFoundation
import Combine
import SwiftUI

struct DrumSample {
    var name: String
    var fileName: String
    var midiNote: Int
    var audioFile: AVAudioFile?
    var color = UIColor.black

    init(_ prettyName: String, file: String, note: Int) {
        name = prettyName
        fileName = file
        midiNote = note

        guard let url = Bundle.main.resourceURL?.appendingPathComponent(file) else { return }
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            Log("Could not load: $fileName")
        }
    }
}

class DrumsConductor: ObservableObject {
    // Mark Published so View updates label on changes
    @Published private(set) var lastPlayed: String = "None"

    let engine = AudioEngine()

    let drumSamples: [DrumSample] =
        [
            DrumSample("OPEN HI HAT", file: "Samples/open_hi_hat_A#1.wav", note: 34),
            DrumSample("HI TOM", file: "Samples/hi_tom_D2.wav", note: 38),
            DrumSample("MID TOM", file: "Samples/mid_tom_B1.wav", note: 35),
            DrumSample("LO TOM", file: "Samples/lo_tom_F1.wav", note: 29),
            DrumSample("HI HAT", file: "Samples/closed_hi_hat_F#1.wav", note: 30),
            DrumSample("CLAP", file: "Samples/clap_D#1.wav", note: 27),
            DrumSample("SNARE", file: "Samples/snare_D1.wav", note: 26),
            DrumSample("KICK", file: "Samples/bass_drum_C1.wav", note: 24)
        ]

    let drums = AppleSampler()

    func playPad(padNumber: Int) {
        drums.play(noteNumber: MIDINoteNumber(drumSamples[padNumber].midiNote))
        let fileName = drumSamples[padNumber].fileName
        lastPlayed = fileName.components(separatedBy: "/").last!
    }

    func start() {
        engine.output = drums
        do {
            try engine.start()
        } catch {
            Log("AudioKit did not start! \(error)")
        }
        do {
            let files = drumSamples.map {
                $0.audioFile!
            }
            try drums.loadAudioFiles(files)

        } catch {
            Log("Files Didn't Load")
        }
    }

    func stop() {
        engine.stop()
    }
}

struct PadsView: View {
    var conductor: DrumsConductor

    var padsAction: (_ padNumber: Int) -> Void
    @State var downPads: [Int] = []

    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { column in
                        ZStack {
                            Rectangle()
                                .fill(Color(self.conductor.drumSamples.map({ self.downPads.contains(where: { $0 == row * 4 + column }) ? .gray : $0.color })[getPadId(row: row, column: column)]))
                            Text(self.conductor.drumSamples.map({ $0.name })[getPadId(row: row, column: column)])
                                .foregroundColor(Color.red).fontWeight(.bold)
                            //Edit UI Pad text
                        }
                        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({_ in
                            if !(self.downPads.contains(where: { $0 == row * 4 + column })) {
                                self.padsAction(getPadId(row: row, column: column))
                                self.downPads.append(row * 4 + column)
                            }
                        }).onEnded({_ in
                            self.downPads.removeAll(where: { $0 == row * 4 + column })
                        }))
                    }
                }
            }
        }
        .navigationBarTitle(Text("Drum Pads")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.red)
                                )
        .onAppear {
            self.conductor.start()
        }
        .onDisappear {
            self.conductor.stop()
        }
    }
}

struct DrumsView: View {
    @StateObject var conductor = DrumsConductor()

    var body: some View {
        VStack(spacing: 2) {
            PadsView(conductor: conductor) { pad in
                self.conductor.playPad(padNumber: pad)
            }
        }
        .onAppear {
            self.conductor.start()
        }
        .onDisappear {
            self.conductor.stop()
        }
    }
}

private func getPadId(row: Int, column: Int) -> Int {
    return (row * 4) + column
}

struct DrumsView_Previews: PreviewProvider {
    static var previews: some View {
        DrumsView()
    }
}

/*class DrumSequencerConductor: ObservableObject {
    let engine = AudioEngine()
    let drums = MIDISampler(name: "Drums")
    let sequencer = AppleSequencer(filename: "Demo")

    @Published var tempo: Float = 120 {
        didSet {
            sequencer.setTempo(BPM(tempo))
        }
    }
    @Published var isPlaying = false {
        didSet {
            isPlaying ? sequencer.play() : sequencer.stop()
        }
    }

    init() {
        engine.output = drums
    }

    func randomize() {
        sequencer.tracks[2].clearRange(start: Duration(beats: 0), duration: Duration(beats: 4))
        for i in 0 ... 15 {
            sequencer.tracks[2].add(
                noteNumber: MIDINoteNumber(30 + Int(AUValue.random(in: 0 ... 1.99))),
                velocity: MIDIVelocity(AUValue.random(in: 80 ... 127)),
                position: Duration(beats: Double(i) / 4.0),
                duration: Duration(beats: 0.5))
        }
    }

    func start() {
        do {
            try engine.start()
        } catch {
            Log("AudioKit did not start! \(error)")
        }
        
        do {
            let bassDrumURL = Bundle.main.resourceURL?.appendingPathComponent("Samples/bass_drum_C1.wav")
            let bassDrumFile = try AVAudioFile(forReading: bassDrumURL!)
            let clapURL = Bundle.main.resourceURL?.appendingPathComponent("Samples/clap_D#1.wav")
            let clapFile = try AVAudioFile(forReading: clapURL!)
            let closedHiHatURL = Bundle.main.resourceURL?.appendingPathComponent("Samples/closed_hi_hat_F#1.wav")
            let closedHiHatFile = try AVAudioFile(forReading: closedHiHatURL!)
            let hiTomURL = Bundle.main.resourceURL?.appendingPathComponent("Samples/hi_tom_D2.wav")
            let hiTomFile = try AVAudioFile(forReading: hiTomURL!)
            let loTomURL = Bundle.main.resourceURL?.appendingPathComponent("Samples/lo_tom_F1.wav")
            let loTomFile = try AVAudioFile(forReading: loTomURL!)
            let midTomURL = Bundle.main.resourceURL?.appendingPathComponent("Samples/mid_tom_B1.wav")
            let midTomFile = try AVAudioFile(forReading: midTomURL!)
            let openHiHatURL = Bundle.main.resourceURL?.appendingPathComponent("Samples/open_hi_hat_A#1.wav")
            let openHiHatFile = try AVAudioFile(forReading: openHiHatURL!)
            let snareDrumURL = Bundle.main.resourceURL?.appendingPathComponent("Samples/snare_D1.wav")
            let snareDrumFile = try AVAudioFile(forReading: snareDrumURL!)

            try drums.loadAudioFiles([bassDrumFile,
                                      clapFile,
                                      closedHiHatFile,
                                      hiTomFile,
                                      loTomFile,
                                      midTomFile,
                                      openHiHatFile,
                                      snareDrumFile])
        

        } catch {
            Log("Files Didn't Load")
        }
        sequencer.clearRange(start: Duration(beats: 0), duration: Duration(beats: 100))
        sequencer.debug()
        sequencer.setGlobalMIDIOutput(drums.midiIn)
        sequencer.enableLooping(Duration(beats: 4))
        sequencer.setTempo(150)

        sequencer.tracks[0].add(noteNumber: 34, velocity: 0, position: Duration(beats: 0), duration: Duration(beats: 4))

        sequencer.tracks[1].add(noteNumber: 34, velocity: 0, position: Duration(beats: 2), duration: Duration(beats: 1))

        sequencer.tracks[2].add(noteNumber: 34, velocity: 0, position: Duration(beats: 2), duration: Duration(beats: 1))

       for i in 0 ... 7 {
            sequencer.tracks[3].add(
                noteNumber: 34,
                velocity: 0,
                position: Duration(beats: Double(i) / 2.0),
                duration: Duration(beats: 0.5))
        }

        sequencer.tracks[3].add(noteNumber: 34, velocity: 0, position: Duration(beats: 2), duration: Duration(beats: 1))
    }

    func stop() {
        engine.stop()
    }
}

struct DrumSequencerView: View {
    @StateObject var conductor = DrumSequencerConductor()

    var body: some View {
        VStack(spacing: 10) {
            Text(conductor.isPlaying ? "Stop" : "Play").onTapGesture {
                conductor.isPlaying.toggle()
            }
            Text("Randomize Hi-hats").onTapGesture {
                conductor.randomize()
            }
           
           ParameterSlider(text: "Tempo",
                            parameter: self.$conductor.tempo,
                            range: 60 ... 300).padding(5).frame(height: 100)
            NodeOutputView(conductor.drums)
            Spacer()
        }
        .navigationBarTitle(Text("Drum Sequencer"))
        .onAppear {
            self.conductor.start()
        }
        .onDisappear {
            self.conductor.stop()
        }
    }
}

struct DrumSequencerView_Previews: PreviewProvider {
    static var previews: some View {
        DrumSequencerView()
    }
}
*/

