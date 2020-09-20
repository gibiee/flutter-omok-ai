import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This app is designed only to work vertically, so we limit orientations to portrait up and down.
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    return new CupertinoApp(
      home: Home(),
      theme: CupertinoThemeData(primaryColor: Colors.blue),
    );
  }
}

class Home extends StatefulWidget {
  @override
  HomeState createState() => new HomeState();
}

class HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool _attackFirst = true;

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width;
    double _height = MediaQuery.of(context).size.height -
        CupertinoNavigationBar().preferredSize.height;

    print([_width, _height]);

    return WillPopScope(
      onWillPop: () {
        return btnBack();
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text("9x9 오목"),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Container(width: _width, height: 0),
              Container(
                width: _width * 0.9,
                height: _height * 0.1,
                color: Colors.orange,
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: _width * 0.25,
                  height: _height * 0.07,
                  child: CupertinoButton(
                    padding: EdgeInsets.all(0),
                    color: Colors.blue,
                    child: Text(
                      '게임 시작',
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () {
                      btnGameStart();
                    },
                  ),
                ),
              ),
              Container(
                width: _width,
                height: _height * 0.8,
                alignment: Alignment.center,
                //color: Colors.green,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/board.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                child: board_btns(_width, _height * 0.8),
              ),
              Container(
                width: _width,
                height: _height * 0.1,
                color: Colors.red,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget board_btns(double w, double h) {
    double _size = (w < h) ? w : h;

    return Container(
      width: _size,
      height: _size,
      //color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          for (int i = 0; i < 9; i++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                for (int j = 0; j < 9; j++)
                  FlatButton(
                    minWidth: _size * 0.07,
                    height: _size * 0.07,
                    onPressed: () {
                      print([i, j]);
                    },
                    child: null,
                    color: Colors.blue,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future btnBack() {
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("경고"),
          content: Text("앱을 종료하시겠습니까?"),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text("Yes"),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
            CupertinoDialogAction(
              child: Text("No"),
              onPressed: () {
                Navigator.pop(context);
              },
              isDestructiveAction: true,
            ),
          ],
        );
      },
    );
  }

  Future btnGameStart() {
    return showCupertinoDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: Text("게임 설정"),
              actions: <Widget>[
                Column(
                  children: [
                    Padding(padding: EdgeInsets.all(10)),
                    Text('난이도를 선택해주세요.', textAlign: TextAlign.center),
                    Padding(padding: EdgeInsets.all(5)),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoSegmentedControl(
                            children: {
                              0: Text('1'),
                              1: Text('2'),
                              2: Text('3'),
                              3: Text('4'),
                              4: Text('5'),
                              5: Text('6'),
                            },
                            groupValue: _selectedIndex,
                            onValueChanged: (value) {
                              setState(() => _selectedIndex = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(10)),
                  ],
                ),
                Column(
                  children: [
                    Padding(padding: EdgeInsets.all(3)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('선공(黑)'),
                        CupertinoSwitch(
                          value: _attackFirst,
                          onChanged: (v) => setState(() => _attackFirst = v),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(3)),
                  ],
                ),
                CupertinoDialogAction(
                  child: Text("확인"),
                  onPressed: () {
                    Navigator.pop(context);
                    print(_selectedIndex);
                    print(_attackFirst);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
