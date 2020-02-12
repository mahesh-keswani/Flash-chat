import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {

  static const id = "chat_screen";

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  
  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async{

    try{
      final user = await _auth.currentUser();
      // if nobody is logged in then user will be null
      if(user != null){
        loggedInUser = user;
      }
    }
    catch(e){
      Alert(
        context: context,
        title: "Error",
        desc: e.toString()
      ).show();
    }
    
  }

  void getMessageStream() async{
    await for(var snapshot in _firestore.collection('messages').snapshots()){
      for (var message in snapshot.documents){
        print(message.data);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      style: TextStyle(
                        color: Colors.white
                      ),
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text' : messageText,
                        'sender' : loggedInUser.email
                      });
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot){

        if(snapshot.hasData){
          final messages = snapshot.data.documents.reversed;
          List<MessageBubble> messageWidgets = [];

          for(var message in messages){
            final messageText = message.data['text'];
            final sender = message.data['sender'];

            final currentUser = loggedInUser.email;
            final messageBubble = MessageBubble(sender: sender, text: messageText, isMe: currentUser == sender);
            messageWidgets.add(messageBubble);
          }
          return Expanded(
              child: ListView(
                reverse: true,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20.0),
                children: messageWidgets,
            ),
          );
        }
        else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class MessageBubble extends StatelessWidget {

  MessageBubble({this.sender, this.text, this.isMe});

  final sender;
  final text;
  bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end  : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              fontSize: 12.0,
              color: isMe ? Colors.white : Colors.grey
            ),
          ),
          Material(
            elevation: 5.0, // it gives box shadow,
            borderRadius: isMe ? BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)) : 
                          BorderRadius.only(topRight: Radius.circular(25), bottomRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              // for internal padding
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15.0,
                  color: isMe ? Colors.white : Colors.black
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}