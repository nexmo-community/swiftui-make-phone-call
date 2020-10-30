//
//  ContentView.swift
//  SwiftUICall
//
//  Created by Abdulhakim Ajetunmobi on 30/10/2020.
//

import SwiftUI
import NexmoClient
import AVFoundation

struct ContentView: View {
    @ObservedObject var callModel = CallModel()
    
    var body: some View {
        VStack {
            Text(callModel.status)
            
            if self.callModel.status == "Connected" {
                TextField("Enter a phone number", text: $callModel.number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .disabled(self.callModel.isCalling)
                    .padding(20)
                
                if !self.callModel.isCalling {
                    Button(action: { self.callModel.callNumber() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "phone")
                            Text("Call")
                        }
                    }
                }
                
                if self.callModel.isCalling {
                    Button(action: { self.callModel.endCall() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "phone")
                            Text("End Call")
                        }.foregroundColor(Color.red)
                    }
                }
            }
        }
        .animation(.default)
        .onAppear(perform: self.callModel.setup)
    }
}

final class CallModel: NSObject, ObservableObject, NXMClientDelegate {
    @Published var status: String = "Unknown"
    @Published var isCalling: Bool = false
    var number: String = ""
    
    private var call: NXMCall?
    private let audioSession = AVAudioSession.sharedInstance()
    
    func setup() {
        requestPermissionsIfNeeded()
        loginIfNeeded()
    }
    
    func requestPermissionsIfNeeded() {
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                print("Microphone permissions \(isGranted)")
            }
        }
    }
    
    func loginIfNeeded() {
        guard status != "Connected" else { return }
        NXMClient.shared.login(withAuthToken: "ALICE_JWT")
        NXMClient.shared.setDelegate(self)
    }
    
    func callNumber() {
        self.isCalling = true
        NXMClient.shared.call(number, callHandler: .server) { (error, call) in
            if error == nil {
                self.call = call
            }
        }
    }
    
    func endCall() {
        self.call?.hangup()
        self.call = nil
        self.isCalling = false
    }
    
    func client(_ client: NXMClient, didChange status: NXMConnectionStatus, reason: NXMConnectionStatusReason) {
        switch status {
        case .connected:
            self.status = "Connected"
        case .disconnected:
            self.status = "Disconnected"
        case .connecting:
            self.status = "Connecting"
        @unknown default:
            self.status = "Unknown"
        }
    }
    
    func client(_ client: NXMClient, didReceiveError error: Error) {
        self.status = error.localizedDescription
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
