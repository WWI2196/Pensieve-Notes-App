import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //open a dialog box to add a new note
  void openNoteBox(){
    showDialog(context: context, builder: (context)=>AlertDialog(
      title: const Text("Add a new note"),
      content: TextField(
        decoration: const InputDecoration(
          hintText: "Enter your note here",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            //add note to database
          },
          child: const Text("Add"),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true, // Centers the title
        title: const Text(
          "Notes",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      body: Container(),
    );
  }
}