import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

class FirestoreUpdate extends StatefulWidget {
  @override
  _FirestoreUpdateState createState() => _FirestoreUpdateState();
}

class _FirestoreUpdateState extends State<FirestoreUpdate> {
  List<DocumentSnapshot> _products = [];

  @override
  Widget build(BuildContext context) {
    Firestore.instance
        .collection('products')
        .snapshots()
        .listen((data) => onChangeData(data.documentChanges));
    return Container();
  }

  void requestNextPage() async {}

  void onChangeData(List<DocumentChange> documentChanges) {
    documentChanges.forEach((productChange) {
      print(
          "productChange ${productChange.type.toString()} ${productChange.newIndex} ${productChange.oldIndex} ${productChange.document}");

      if (productChange.type == DocumentChangeType.removed) {
        _products.removeWhere((product) {
          return productChange.document.documentID == product.documentID;
        });
      } else {
        if (productChange.type == DocumentChangeType.modified) {
          int indexWhere = _products.indexWhere((product) {
            return productChange.document.documentID == product.documentID;
          });

          if (indexWhere >= 0) {
            _products[indexWhere] = productChange.document;
          }
        }
      }
    });
  }
}
