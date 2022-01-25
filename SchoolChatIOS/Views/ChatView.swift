//
//  ChatView.swift
//  SchoolChatIOS
//
//  Created by Константин Леонов on 07.12.2021.
//

import SwiftUI

final class ChatViewModel: ObservableObject {
    
    @Published private(set) var messages: [Message] = []
    @Published var scroll = false
    
    var chat_id: Int64 = 0
    var manager = SocketIOManager()
    
    func connect() {
        manager.observeMessages(completionHandler: NewMsg)
        manager.recieve_chat_msgs(completionHandler: getMessages)
        request_users()
    }
    
    func request_users() {
        
    }
    
    private func NewMsg(incoming: Message) {
        print("recieved")
        if (incoming.chat_id == chat_id) && (!incoming.deleted_all){
            messages.append(incoming)
            scroll.toggle()
        }
    }
    
    func sendMessage(message: Message) {
        manager.send(message: message)
    }
    
    func getMessages(incoming: [String:Any]) {
//        print(incoming.last?["user_name"])
        let msg = incoming
//        for msg in incoming {
            messages.append(Message(id: Int64(msg["id"] as! String)!, chat_id: Int64(msg["chat_id"] as! String)!, user_id: Int64(msg["user_id"] as! String)!, text: msg["text"] as! String, attachments: msg["attachments"] as? [String:Any] ?? [:], deleted_all: msg["deleted_all"] as? Bool ?? false, deleted_user: msg["deleted_user"] as? Bool ?? false, edited: msg["edited"] as? Bool ?? false, time: (msg["updatedAt"] as! String).JSDateToDate(), service: msg["service"] as? Bool ?? false))
//        }
        scroll.toggle()
    }
    
    func requestMessages() {
        manager.requestChatMsgs(user_id: USER!.id, chat_id: chat_id)
    }
}

struct ChatView: View {
    
    @State private var message = ""
    @ObservedObject var back: NavigationBeetweenChats
    @StateObject private var model: ChatViewModel = ChatViewModel()
    @State private var lastMessageUUID: UUID?
    @State private var isFirst: Bool = true
    
    @State var LinkToInfo = false
    
    var chat: Chat

    private func onAppear() {
        if !LinkToInfo {
            model.chat_id = chat.id
            model.connect()
            model.requestMessages()
        }
        LinkToInfo = false
        back.Allower = false
    }
    
    private func ScrollToMessage(messageUUID: UUID, anchor: UnitPoint? = nil, shouldAnimate: Bool, scrollReader: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(shouldAnimate ? Animation.easeIn : nil) {
                scrollReader.scrollTo(messageUUID, anchor: anchor)
            }
        }
    }
    
    private func send_button() {
        if !message.isEmpty {
            model.sendMessage(message: Message(id: Int64(model.messages.count), chat_id: model.chat_id, user_id: USER?.id ?? 0, text: message, attachments: [:], deleted_all: false, deleted_user: false, edited: false, time: Date.now, service: false))
            message = ""
        }
    }
    
    let columns = [GridItem(.flexible(minimum: 10))]
    
    private func contextButton(text: String, img: String) -> some View{
        return HStack {
            Text(text)
            Spacer()
            Image(systemName: img)
        }
    }
    
    private func reply(msg: Message) {
        print("reply", chat.name)
    }
    
    private func copy(msg: Message) {
        print("copy")
        UIPasteboard.general.string = msg.text
        // TODO: Add success notification (optional)
    }
    
    private func delete(for_all: Bool, msg: Message) {
        print("delete")
    }
    
    private func ctxMenu(message: Message) -> some View {
        return
            Group {
                Button(action: {
                    reply(msg: message)
                }) {
                    contextButton(text: "Reply", img: "arrowshape.turn.up.right")
                }
                
                Button(action: {
                    copy(msg: message)
                }) {
                    contextButton(text: "Copy", img: "doc.on.doc")
                }
                
                Button(role: .destructive) {
                    delete(for_all: false, msg: message)
                } label: {
                    contextButton(text: "Delete for me", img: "trash")
                }
                if (message.user_id == USER?.id || chat.creator == USER?.id || chat.admins.contains(USER!.id)) {
                    Button(role: .destructive) {
                        delete(for_all: true, msg: message)
                    } label: {
                        contextButton(text: "Delete for all", img: "trash")
                    }
                }
            }
    }
    
    private func MessagesView() -> some View {
        ForEach(model.messages) { message in
            Spacer()
                .frame(height: 2)
            MessageView(message: message, ctxmenu: AnyView(ctxMenu(message: message)))
                .id(message.InternalId)
            }
        }
    
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                ScrollViewReader { scrollReader in
                    VStack {
                    MessagesView()
                        .onChange(of: model.scroll) { _ in
                            lastMessageUUID = model.messages.last?.InternalId
                            ScrollToMessage(messageUUID: lastMessageUUID!, anchor: nil, shouldAnimate: !isFirst, scrollReader: scrollReader)
                            if isFirst {
                                isFirst = !isFirst
                            }
                        }
                    }
                }
            }
            if (chat.left) {
                Text("You cannot send messages to this channel")
            } else {
                HStack {
                    TextField("Message", text: $message, onEditingChanged: {_ in}, onCommit: send_button)
                        .padding(10)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(5)
                    Button(action: send_button) {
                        Image(systemName: "arrow.turn.up.right")
                            .font(.system(size: 20))
                    }
                    .padding()
                    .disabled(message.isEmpty)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: leadingBtn)
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
    }
    
    private func onDisappear() {
        if LinkToInfo {
            return
        }
        back.toggler.toggle()
    }
    
    var leadingBtn: some View {
        HStack {
            NavigationLink(destination: ChatInfoView(chat: chat)) {
                HStack {
                    ChatPicture(chat: chat, frameRadius: 40)
                        .frame(width: 40, height: 40)
                        .padding(.horizontal, 0)
                    Text(chat.name)
                        .bold()
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 3)
                }
            }
            .simultaneousGesture(TapGesture().onEnded{
                print("aboba")
                LinkToInfo = true
            })
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(back: NavigationBeetweenChats(), chat: Chat(id: 2, name: "Test Chat", creator: 2, picture_url: "", deleted: false, hasLastMsg: true, last_msg_text: "Aboba", last_msg_user: 1, last_msg_time: Date.now, last_msg_username: "", admins: [], left: false, users: []))
    }
}

