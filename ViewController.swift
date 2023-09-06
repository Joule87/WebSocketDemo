//
//  ViewController.swift
//  WebSocketDemo
//
//  Created by Julio Collado Perez on 9/6/23.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    @IBOutlet weak var numberLabel: UILabel!
    
    private var webSocketTask: URLSessionWebSocketTask?
    var randomNumber : String {
        "\(Int.random(in: 0...1000))"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
       setupWebsocket()
    }

    @IBAction func didTapPlayButton(_ sender: UIButton) {
        play()
    }
    
    @IBAction func didTapPauseButton(_ sender: UIButton) {
        pause()
    }
    
    @IBAction func didTapCancelButton(_ sender: UIButton) {
        cancel()
    }
    
    private func setupWebsocket() {
        let session = URLSession(configuration: .default,
                                 delegate: self,
                                 delegateQueue: OperationQueue())
        guard let url = URL(string: "wss://socketsbay.com/wss/v2/1/demo/M7") else {
            debugPrint("❌ BAD URL ERROR")
            return
        }
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
    }

}

//MARK: - Websocket Management

extension ViewController {
    private func send(message: String) {
        print("SEND PENDING")
        let workItem = DispatchWorkItem {
            self.webSocketTask?.send(.string(message), completionHandler: { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    debugPrint("❌ SEND ERROR: \(error.localizedDescription)")
                }
                print("SEND EXECUTED")
            })
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: workItem)
    }
    
    private func receive() {
        print("RECEIVE PENDING")
        let workItem = DispatchWorkItem {
            self.webSocketTask?.receive(completionHandler: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let value):
                    DispatchQueue.main.async {
                        if case let .string(value) = value {
                            print("RECEIVE EXECUTED")
                            self.numberLabel.text = value
                        }
                    }
                case .failure(let error):
                    debugPrint("❌ RECEIVE ERROR: \(error.localizedDescription)")
                }
                self.receive()
            })
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 1 , execute: workItem)
    }
    
    private func ping() {
        webSocketTask?.sendPing(pongReceiveHandler: { error in
            if let error = error {
                debugPrint("❌ PONG ERROR: \(error.localizedDescription)")
            }
        })
    }
    
    private func play() {
        webSocketTask?.resume()
    }
    
    private func pause() {
        webSocketTask?.suspend()
    }
    
    private func cancel() {
        webSocketTask?.cancel(with: .goingAway, reason: "user did stop conection".data(using: .utf8))
    }
}

extension ViewController: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        debugPrint("didOpenWithProtocol with state \(webSocketTask.state) and protocol \(`protocol` ?? "NONE")")
        receive()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        debugPrint("didCloseWith with state \(webSocketTask.state) and reason \(String(data: reason ?? Data(), encoding: .utf8) ?? "NONE")")
    }
}
