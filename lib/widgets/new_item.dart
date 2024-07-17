import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/models/grocery_item.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;

class NewItem extends StatefulWidget{
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem>{
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _enteredCategory = categories[Categories.other]!;
  var _isSending = false;

  void _saveItem() async {
    if(_formKey.currentState!.validate()){
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      final url = Uri.https('flutter-prac-2d0ad-default-rtdb.firebaseio.com','shopping-list.json');

      final response = await http.post(url,headers: {
        'Content-Type': 'application/json'},
        body: json.encode({
          'name': _enteredName,
          'quantity': _enteredQuantity,
          'category': _enteredCategory.title
        },
        ),
      );
      final Map<String,dynamic> resData = json.decode(response.body);
      if(!context.mounted){
        return;
      }
      //// Store locally
      final dbPath = await sql.getDatabasesPath();
      final db = await sql.openDatabase(path.join(dbPath, 'bazaar.db'),onCreate: (db, version){
        return db.execute('CREATE TABLE bazaar_list(id TEXT PRIMARY KEY, name TEXT,quantity TEXT ,category TEXT)');
      },version: 1);
      db.insert('bazaar_list', {
        'id': resData.toString(),
        'name': _enteredName,
        'quantity': _enteredQuantity,
        'category': _enteredCategory.title
      });
      Navigator.of(context).pop(
        GroceryItem(id: resData.toString(), name: _enteredName, quantity: _enteredQuantity, category: _enteredCategory)
      );

    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Add a new item'),),
    body: Padding(
      padding: EdgeInsets.all(15),
      child: Form(
        key: _formKey,
        child: Column(children: [
          TextFormField(
            maxLength: 50,
            decoration: InputDecoration(
              label: Text('Name')
            ),
            validator: (value){
              if(value == null || value.isEmpty || value.trim().length <= 1 || value.trim().length > 50){
                return 'Must be between 1 to 50 characters';
              }
              return null;
            },
            onSaved: (value){
              _enteredName = value!;
            },
          ),
          Row(crossAxisAlignment:CrossAxisAlignment.end,children: [
            Expanded(
              child: TextFormField(initialValue: _enteredQuantity.toString(),
                keyboardType: TextInputType.number,
                validator: (value){
                  if(value == null || value.isEmpty || int.tryParse(value) == null || int.tryParse(value)! <= 0){
                    return 'Must be a valid positive number';
                  }
                  return null;
                },
                decoration:  InputDecoration(
                    label:  Text('Quantity')
                ),
                onSaved: (value){
                _enteredQuantity = int.parse(value!);
                },
              ),
            ),
            const SizedBox(width: 8,),
            Expanded(
              child: DropdownButtonFormField(items: [
                for(final category in categories.entries)
                  DropdownMenuItem(
                    value: category.value,
                      child: Row(children: [
                        Container(width: 16,height: 16,color: category.value.color,),
                        SizedBox(width: 6),
                        Text(category.value.title)
                      ],))
              ],
                  onChanged: (value){
                setState(() {
                  _enteredCategory = value!;
                });
              }),
            ),
          ],),
          const SizedBox(height: 30),
          Row(mainAxisAlignment: MainAxisAlignment.end,children: [
            TextButton(onPressed:
              _isSending ? null : () {
              _formKey.currentState!.reset();
              },
                child: const Text('Reset')),
            ElevatedButton(onPressed: _isSending ? null : _saveItem, child: _isSending ? const SizedBox(height: 16,width: 16,child: CircularProgressIndicator(),)
            : const Text('Add Item')),
          ],)
        ],),
      ),
    ),
    );
  }
}