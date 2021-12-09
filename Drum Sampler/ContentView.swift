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
    var color = UIColor.lightGray

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
            DrumSample("OPEN HI HAT", file: "Samples/open_hihat_A#1.wav", note: 34),
            DrumSample("RIM-SHOT", file: "Samples/flam_click_snare_D2.wav", note: 38),
            DrumSample("PERC 1", file: "Samples/slappy_perc_ 13_B1.wav", note: 35),
            DrumSample("PERC 2", file: "Samples/slappy_perc_18_F1.wav", note: 29),
            DrumSample("HI HAT", file: "Samples/slappy_hat_10_F#1.wav", note: 30),
            DrumSample("CLAP", file: "Samples/clap_2_D#1.wav", note: 27),
            DrumSample("SNARE", file: "Samples/slappy_snare_27_D1.wav", note: 26),
            DrumSample("KICK", file: "Samples/slappy_kick_28_C1.wav", note: 24)
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
        .background(/*@START_MENU_TOKEN@*//*@PLACEHOLDER=View@*/Color(red: 0.361, green: 0.361, blue: 0.361)/*@END_MENU_TOKEN@*/)
        
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
