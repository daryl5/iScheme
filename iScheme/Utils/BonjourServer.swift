//
//  BonjourServer.swift
//  iScheme
//
//  Created by lingwan on 2017/6/24.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

let kBonjourServiceType = "_schememanager._tcp."

final class BonjourClient: NSObject, GCDAsyncSocketDelegate {
    
    let socket: GCDAsyncSocket
    var name: String = "Client X" {
        didSet {
            ClientManager.manager.updateiOSDeviceName(with: self)
        }
    }
    
    init(socket: GCDAsyncSocket) {
        self.socket = socket
    }
    
    deinit {
        socket.disconnect()
    }
    
    func sendScheme(scheme: String) {
        guard !scheme.isEmpty, let data = scheme.data(using: .utf8) else {
            return
        }
        socket.write(data, withTimeout: -1, tag: 0)
    }
    
    //MARK: -
    //MARK: GCDAsyncSocketDelegate
    
    //remove self from device list
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        ClientManager.manager.removeiOSDevice(self)
    }
    
    //get device name
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        guard let name = String.init(data: data, encoding: .utf8) else {
            return
        }
        self.name = name
    }
}

enum BonjourServerState {
    case on
    case off
}

final class BonjourServer: NSObject, GCDAsyncSocketDelegate {
    
    static let sharedServer = BonjourServer()
    
    var state: BonjourServerState = .off
    
    private var service: NetService!
    private var socket: GCDAsyncSocket!
    
    deinit {
        socket.disconnect()
    }
    
    func start() {
        state = .on
        socket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        
        do {
            try socket.accept(onPort: 0)
            
            service = NetService(domain: "local.", type: kBonjourServiceType, name: Host.current().localizedName ?? "iScheme Mac", port: Int32(socket.localPort))
            service.publish()
        } catch {
            print(error)
        }
    }
    
    func stop() {
        state = .off
        socket.disconnect()
        service.stop()
        ClientManager.manager.removeAlliOSDevices()
    }
    
    //MARK: -
    //MARK: GCDAsyncSocketDelegate
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        let client = BonjourClient.init(socket: newSocket)
        newSocket.delegate = client
        
        let iOSClient = iOSDeviceClient.init(name: "Pending iOS Device", state: ClientState.init(booleanLiteral: true), bonjourClient: client)
        ClientManager.manager.addiOSDevice(client: iOSClient)
                
        //read device name
        newSocket.readData(withTimeout: -1, tag: 0)
    }
}
