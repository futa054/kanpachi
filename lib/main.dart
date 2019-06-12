import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'dart:async';
import 'dart:core';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '買い物リスト',
      home: List(),
    );
  }
}

class List extends StatefulWidget {
  @override
  _MyList createState() => _MyList();
}

class _MyList extends State<List> {
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("リスト画面"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('memo').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot){
            if (!snapshot.hasData) return const Text('Loading...');
            return ListView.builder(
                itemCount: snapshot.data.documents.length,
                padding: const EdgeInsets.only(top: 10.0),
                itemBuilder: (context, index) =>
                  _buildListItem(context, snapshot.data.documents[index]),
            );
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            print("新規作成buttonを押しました！");

            Navigator.push(
              context,
              MaterialPageRoute(
                  settings: const RouteSettings(name: "/new"),
                  builder: (BuildContext context) => InputForm(null)
                ),
            );
          }
      ),
    );
  }
  
  Widget _buildListItem(BuildContext context, DocumentSnapshot document){
    var format = new DateFormat('yyyy年MM月dd日');
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.android),
            title: Text("【" + (document['getOrWant'] == "get"?"欲しい":"買う") + "】" + document['stuff']),
            subtitle: Text('CreateDate : ' + format.format(document['date'].toDate()) +
                "\nShop : " + document['shop']),
          ),
          ButtonTheme.bar(
            child: ButtonBar(
              children: <Widget>[
                FlatButton(
                  child: const Text("編集"),
                  onPressed: ()
                  {
                    print("編集button押しました？");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: const RouteSettings(name: "/edit"),
                          builder: (BuildContext context) => InputForm(document)
                        ),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class InputForm extends StatefulWidget {
  InputForm(this.document);
  final DocumentSnapshot document;
  @override
  _MyInputFormState createState() => _MyInputFormState();
}

class _FormData {
  String getOrWant = "get";
  String shop;
  String stuff;
  DateTime date = DateTime.now();
}

class _MyInputFormState extends State<InputForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();

  void _setGetOrWant(String value) {
    setState(() {
      _data.getOrWant = value;
    });
  }
  Future <DateTime> _selectTime(BuildContext context) {
    return showDatePicker(
        context: context,
        initialDate: _data.date,
        firstDate: DateTime(_data.date.year - 2),
        lastDate: DateTime(_data.date.year + 2));
  }
  @override
  Widget build(BuildContext context) {
    DocumentReference _mainReference;
    _mainReference = Firestore.instance.collection('memo').document();
    if (widget.document != null) {
      if (_data.shop == null && _data.stuff == null) {
        _data.getOrWant = widget.document['getOrWant'];
        _data.shop = widget.document['shop'];
        _data.stuff = widget.document['stuff'];
        _data.date = widget.document['date'].toDate();
      }
      _mainReference = Firestore.instance.collection('memo').document(widget.document.documentID);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物入力'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              print("保存buttonを押したよ");
              if(_formKey.currentState.validate()) {
                _formKey.currentState.save();
                _mainReference.setData(
                  {
                    'getOrWant': _data.getOrWant,
                    'shop': _data.shop,
                    'stuff': _data.stuff,
                    'date': _data.date
                  }
                );
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              print("さくじょぼたんおしたよ");
            },
          ),
        ],
      ),
      body: SafeArea(
          child:
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: <Widget>[

                RadioListTile(
                  value: "get",
                  groupValue: _data.getOrWant,
                  title: Text("買う"),
                  onChanged: (String value) {
                    print("買うをたっちしました");
                    _setGetOrWant(value);
                  },
                ),
                
                RadioListTile(
                  value: "want",
                  groupValue: _data.getOrWant,
                  title: Text("欲しい"),
                  onChanged: (String value) {
                    print("欲しいをたっちしました");
                    _setGetOrWant(value);
                  },
                ),

                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.shop),
                    hintText: 'Shop',
                  ),
                  onSaved: (String value) {
                    _data.shop = value;
                  },
                  validator: (value) {
                    if (value.isEmpty) {
                      return '店名は入力必須です。';
                    }
                  },
                ),
                
                TextFormField(
                  decoration: const InputDecoration(
                    icon: const Icon(Icons.shopping_basket),
                    hintText: 'Item',
                  ),
                  onSaved: (String value) {
                    _data.stuff = value;
                  },
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'アイテムは入力必須です。';
                    }
                  },
                ),
                
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("登録日:${_data.date.toString().substring(0,10)}"),
                ),

                RaisedButton(
                  child: const Text("登録日変更"),
                  onPressed: () {
                    print("登録日変更をタッチしました");
                    _selectTime(context).then((time){
                      if(time != null && time != _data.date) {
                        setState(() {
                          _data.date = time;
                        });
                      }
                    });
                  },
                ),
              ],
            ),
          ),
      ),
    );
  }
}