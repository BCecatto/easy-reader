import 'dart:io';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login_demo/services/authentication.dart';
import 'package:path_provider/path_provider.dart';
import './profile_page.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = new GlobalKey<FormState>();

  //firebase
  bool _isEmailVerified = false;

  //file picker
  String _fileName;
  String _path;

  //unzip
  bool _downloading;
  String _dir;
  String _errorMessage;
  List<String> _images, _tempImages;
  String _zipPath = '';
  String _localZipFileName = 'images.zip';

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _images = List();
    _tempImages = List();
    _downloading = false;
    _errorMessage = "";
    _fileName = "";
    _path = "";
    _initDir();
  }

  _initDir() async {
    if (null == _dir) {
      _dir = (await getApplicationDocumentsDirectory()).path;
    }
  }

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  Widget _showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new Center(
        child: Text(
          _errorMessage,
          style: TextStyle(
              fontSize: 17.0,
              color: Colors.red,
              height: 1.0,
              fontWeight: FontWeight.w300),
        ),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Future<File> _downloadFile(String _path, String url, String fileName) async {
    if (_path.isNotEmpty) {
      var file = File('$_path');
      return file;
    } else {
      var req = await http.Client().get(Uri.parse(url));
      var file = File('$_dir/$fileName');
      return file.writeAsBytes(req.bodyBytes);
    }
  }

  Future<void> _downloadZip() async {
    if (_validateAndSave()) {
      setState(() {
        _downloading = true;
      });
      try {
        _images.clear();
        _tempImages.clear();

        var zippedFile =
            await _downloadFile(_path, _zipPath, _localZipFileName);
        await unarchiveAndSave(zippedFile);

        setState(() {
          _images.addAll(_tempImages);
          _images.sort();
          _downloading = false;
        });
      } catch (e) {
        print('Error: $e');
        setState(() {
          _downloading = false;

          _errorMessage = e.message;
        });
      }
    }
  }

  unarchiveAndSave(var zippedFile) async {
    var bytes = zippedFile.readAsBytesSync();
    var archive = ZipDecoder().decodeBytes(bytes);
    for (var file in archive) {
      var fileName = '$_dir/${file.name}';
      if (file.isFile) {
        var outFile = File(fileName);
        _tempImages.add(outFile.path);
        outFile = await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content);
      }
    }
  }

  Widget _showCircularProgress() {
    if (_downloading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget buildList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _images.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.file(
                    File(_images[index]),
                    fit: BoxFit.fitWidth,
                  )));
        },
      ),
    );
  }

  void _checkEmailVerification() async {
    _isEmailVerified = await widget.auth.isEmailVerified();
    if (!_isEmailVerified) {
      _showVerifyEmailDialog();
    }
  }

  void _resentVerifyEmail() {
    widget.auth.sendEmailVerification();
    _showVerifyEmailSentDialog();
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Verify your account"),
          content: new Text("Please verify account in the link sent to email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Resent link"),
              onPressed: () {
                Navigator.of(context).pop();
                _resentVerifyEmail();
              },
            ),
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Verify your account"),
          content:
              new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  _signOut() async {
    try {
      Navigator.popUntil(
          context, ModalRoute.withName(Navigator.defaultRouteName));
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  Widget _showUrlInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30.0, 130.0, 30.0, 30.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.url,
        autofocus: false,
        decoration: new InputDecoration(hintText: 'Zip URL'),
        onSaved: (value) => _zipPath = value.trim(),
      ),
    );
  }

  String _imageUrl(var snapshot) {
    try {
      return snapshot["photoUrl"];
    } catch (e) {
      return 'https://cdn.business2community.com/wp-content/uploads/2017/08/blank-profile-picture-973460_640.png';
    }
  }

  Widget _drawerMenu() {
    return new Drawer(
      child: ListView(
        children: <Widget>[
          new UserAccountsDrawerHeader(
            accountEmail: new FutureBuilder(
              future: widget.auth.getCurrentUser(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return new Text(snapshot.data.email);
                } else {
                  return new Text('Loading...');
                }
              },
            ),
            currentAccountPicture: new StreamBuilder(
                stream: Firestore.instance
                    .collection('users')
                    .document(widget.userId)
                    .snapshots(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    return Image.network(
                        _imageUrl(snapshot.data),
                        width: 90.0,
                        height: 90.0,
                        fit: BoxFit.cover);
                  } else {
                    return new Container(width: 0.0, height: 0.0);
                  }
                }),
          ),
          ListTile(
            title: new Text('Perfil'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (BuildContext context) =>
                          new ProfilePage(auth: widget.auth)));
            },
          ),
          ListTile(
            title: new Text('New ZIP file'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (BuildContext context) => new HomePage(
                          auth: widget.auth,
                          userId: widget.userId,
                          onSignedOut: widget.onSignedOut)));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
      child: SizedBox(
        height: 40.0,
        child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: new Text('Process information...',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              FutureBuilder(
                  future: _downloadZip(),
                  builder: (context, snapshot) {
                    return AlertDialog(
                      title: new Text("Finished Download"),
                      content: new Text("Now you can see your manga"),
                      actions: <Widget>[
                        new FlatButton(
                          child: new Text("Dismiss"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  });
            }),
      ),
    );
  }

  void _openFileExplorer() async {
    try {
      _path = await FilePicker.getFilePath();
    } catch (e) {
      print("Unsupported operation" + e.toString());
    }
    if (!mounted) return;

    setState(() {
      _fileName = _path.split('/').last;
    });
  }

  Widget _selectPicker() {
    return new Padding(
      padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
      child: SizedBox(
        height: 40.0,
        child: new RaisedButton(
          elevation: 5.0,
          shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0)),
          color: Colors.blue,
          onPressed: () => _openFileExplorer(),
          child: new Text('Select a ZIP file',
              style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _showBody() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              if (_showSelect()) _showUrlInput(),
              if (_showSelect()) new Center(child: Text('OR')),
              _showSelect()
                  ? _selectPicker()
                  : new Center(
                      child: Text(_fileName,
                          style:
                              TextStyle(fontSize: 17.0, color: Colors.blue))),
              _buildButton()
            ],
          ),
        ));
  }

  bool _showSelect() {
    if (_fileName.isNotEmpty || _zipPath.isNotEmpty) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: new AppBar(
          title: new Text('Home'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
        drawer: _drawerMenu(),
        body: _downloading
            ? _showCircularProgress()
            : Container(
                child: Column(
                  children: <Widget>[
                    _images.isNotEmpty ? buildList() : _showBody(),
                    _showErrorMessage()
                  ],
                ),
              ));
  }
}
