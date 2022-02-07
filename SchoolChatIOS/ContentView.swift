//
//  ContentView.swift
//  SchoolChatIOS
//
//  Created by Константин Леонов on 07.12.2021.
//

import SwiftUI
import SocketIO

struct MiniView: View {
    let t: Int
    var body: some View {
        VStack {
            Text("Row \(t)")
        }
    }
}

struct ContentView: View {
    
    @StateObject var AuthOb: AuthObj = AuthObj()
    
    var body: some View {
        AuthView(AuthOb: AuthOb)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
