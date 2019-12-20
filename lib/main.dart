import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: "xxx"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ProductList(),
    );
  }
}

class ProductList extends StatefulWidget {
  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  StreamController<List<DocumentSnapshot>> _streamController =
  StreamController<List<DocumentSnapshot>>();
  List<DocumentSnapshot> _products = [];

  bool _isRequesting = false;
  bool _isFinish = false;

  void onChangeData(List<DocumentChange> documentChanges) {
    var isChange = false;
    documentChanges.forEach((productChange) {
      print(
          "productChange ${productChange.type.toString()} ${productChange.newIndex} ${productChange.oldIndex} ${productChange.document}");

      if (productChange.type == DocumentChangeType.removed) {
        _products.removeWhere((product) {
          return productChange.document.documentID == product.documentID;
        });
        isChange = true;
      } else {

        if (productChange.type == DocumentChangeType.modified) {
          int indexWhere = _products.indexWhere((product) {
            return productChange.document.documentID == product.documentID;
          });

          if (indexWhere >= 0) {
            _products[indexWhere] = productChange.document;
          }
          isChange = true;
        }
      }
    });

    if(isChange) {
      _streamController.add(_products);
    }
  }

  @override
  void initState() {
    Firestore.instance
        .collection('products')
        .snapshots()
        .listen((data) => onChangeData(data.documentChanges));

    requestNextPage();
    super.initState();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.maxScrollExtent == scrollInfo.metrics.pixels) {
            requestNextPage();
          }
          return true;
        },
        child: StreamBuilder<List<DocumentSnapshot>>(
          stream: _streamController.stream,
          builder: (BuildContext context,
              AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
            if (snapshot.hasError) return new Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return new Text('Loading...');
              default:
                log("Items: " + snapshot.data.length.toString());
                return ListView.separated(
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.black,
                  ),
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: new ListTile(
                      title: new Text(snapshot.data[index]['name']),
                      subtitle: new Text(snapshot.data[index]['description']),
                    ),
                  ),
                );
            }
          },
        ));
  }

  void requestNextPage() async {
    if (!_isRequesting && !_isFinish) {
      QuerySnapshot querySnapshot;
      _isRequesting = true;
      if (_products.isEmpty) {
        querySnapshot = await Firestore.instance
            .collection('products')
            .orderBy('index')
            .limit(5)
            .getDocuments();
      } else {
        querySnapshot = await Firestore.instance
            .collection('products')
            .orderBy('index')
            .startAfterDocument(_products[_products.length - 1])
            .limit(5)
            .getDocuments();
      }

      if (querySnapshot != null) {
        int oldSize = _products.length;
        _products.addAll(querySnapshot.documents);
        int newSize = _products.length;
        if (oldSize != newSize) {
          _streamController.add(_products);
        } else {
          _isFinish = true;
        }
      }
      _isRequesting = false;
    }
  }
}
