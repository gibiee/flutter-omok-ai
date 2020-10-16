import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

bool gameStart = false;

List black_moved = [];
List white_moved = [];
List forbidden = [];
List<dynamic> prev_moved = [-1, -1];
int hard_idx = 2;
bool player_is_black = true;
bool wait = false;

dynamic states_loc = null;

// String url = 'http://aesthetic-abbey-292511.df.r.appspot.com';
String url = 'http://35.247.28.193:80';

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
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width;
    double _height = MediaQuery.of(context).size.height -
        CupertinoNavigationBar().preferredSize.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return WillPopScope(
      onWillPop: () {
        return btnBack();
      },
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text("9x9 오목"),
        ),
        child: Scaffold(
          key: scaffoldKey,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Container(width: _width, height: 0),
                Container(
                  width: _width * 0.9,
                  height: _height * 0.1,
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
                  width: _width * 0.9,
                  height: _height * 0.8,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('images/board.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: board_btns(_width * 0.9, _height * 0.8),
                ),
                Container(
                  width: _width,
                  height: _height * 0.1,
                )
              ],
            ),
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
                  Stack(
                    children: <Widget>[
                      SizedBox(
                        width: _size * 0.07,
                        height: _size * 0.07,
                        child: Opacity(
                          opacity: checkList(black_moved, [i, j]) ? 1 : 0,
                          child: (() {
                            if (listEquals([i, j], prev_moved)) {
                              return Image.asset(
                                'images/black_prev.png',
                                fit: BoxFit.cover,
                              );
                            } else {
                              return Image.asset(
                                'images/black.png',
                                fit: BoxFit.cover,
                              );
                            }
                          })(),
                        ),
                      ),
                      SizedBox(
                        width: _size * 0.07,
                        height: _size * 0.07,
                        child: Opacity(
                          opacity: checkList(white_moved, [i, j]) ? 1 : 0,
                          child: (() {
                            if (listEquals([i, j], prev_moved)) {
                              return Image.asset(
                                'images/white_prev.png',
                                fit: BoxFit.cover,
                              );
                            } else {
                              return Image.asset(
                                'images/white.png',
                                fit: BoxFit.cover,
                              );
                            }
                          })(),
                        ),
                      ),
                      SizedBox(
                        width: _size * 0.07,
                        height: _size * 0.07,
                        child: Opacity(
                          opacity:
                              checkList(forbidden, [i, j]) && player_is_black
                                  ? 1
                                  : 0,
                          child: Image.asset(
                            'images/X.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: _size * 0.07,
                        height: _size * 0.07,
                        child: Opacity(
                          opacity: 0,
                          child: FlatButton(
                            onPressed: () async {
                              if (gameStart) {
                                if (wait == false) {
                                  if (checkList(black_moved, [i, j]) ||
                                      checkList(white_moved, [i, j]) ||
                                      (player_is_black &&
                                          checkList(forbidden, [i, j]))) {
                                    scaffoldKey.currentState.showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('그곳에는 돌을 놓을 수 없습니다')));
                                  } else {
                                    wait = true;
                                    // 플레이어가 돌을 둔 것을 렌더링
                                    setState(() {
                                      if (player_is_black) {
                                        black_moved.add([i, j]);
                                      } else {
                                        white_moved.add([i, j]);
                                      }
                                      prev_moved = [i, j];
                                    });

                                    // 플레이어가 돌을 둔 위치를 서버로 보냅니다.
                                    var response = await http.post(
                                      url + '/player_moved',
                                      headers: {
                                        "Content-Type":
                                            "application/json; charset=UTF-8"
                                      },
                                      body: jsonEncode(
                                        {
                                          'hard_idx': hard_idx,
                                          'player_moved': [i, j],
                                          'states_loc': states_loc,
                                        },
                                      ),
                                    );

                                    // print(response.body);

                                    // 서버로부터 AI가 데이터를 받습니다.
                                    // 1. AI가 둘 위치
                                    // 2. 금수 자리
                                    // 3. 게임이 끝났는지 여부
                                    var data = json.decode(response.body)
                                        as Map<String, dynamic>;

                                    // print(data);

                                    // AI가 돌을 둔 것을 렌더링
                                    setState(() {
                                      if (data['ai_moved'] != null) {
                                        if (player_is_black) {
                                          white_moved.add(data['ai_moved']);
                                        } else {
                                          black_moved.add(data['ai_moved']);
                                        }
                                        prev_moved = data['ai_moved'];
                                      }
                                      forbidden = data['forbidden'];
                                      states_loc = data['states_loc'];
                                    });

                                    if (data['message'] == 1) {
                                      scaffoldKey.currentState.showSnackBar(
                                          SnackBar(
                                              content: Text('플레이어가 이겼습니다!')));
                                      gameStart = false;
                                    } else if (data['message'] == 2) {
                                      scaffoldKey.currentState.showSnackBar(
                                          SnackBar(
                                              content: Text('인공지능이 이겼습니다!')));
                                      gameStart = false;
                                    }
                                    wait = false;
                                  }
                                }
                              } else {
                                scaffoldKey.currentState.showSnackBar(SnackBar(
                                    content: Text('게임 시작 버튼을 눌러주세요.')));
                              }
                            },
                            child: null,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  bool checkList(list, check) {
    for (var i = 0; i < list.length; i++) {
      if (listEquals(list[i], check)) {
        return true;
      }
    }
    return false;
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
              child: Text("확인"),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
            CupertinoDialogAction(
              child: Text("취소"),
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
                              0: Text('1'), // 2500
                              1: Text('2'), // 5000
                              2: Text('3'), // 7500
                              3: Text('4'), // 10000
                              4: Text('5'), // 12500
                              5: Text('6'), // 15000
                              6: Text('7'), // 17500
                              7: Text('8'), // 20000
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
                  onPressed: () async {
                    Navigator.pop(context);
                    hard_idx = _selectedIndex;
                    player_is_black = _attackFirst;
                    wait = player_is_black ? false : true;
                    gameStart = true;

                    black_moved = [];
                    white_moved = [];
                    forbidden = [];
                    prev_moved = [-1, -1];
                    states_loc = null;

                    if (player_is_black == false) {
                      var response = await http.post(
                        url + '/ai_first_moved',
                        headers: {
                          "Content-Type": "application/json; charset=UTF-8"
                        },
                        body: jsonEncode(
                          {
                            'hard_idx': hard_idx,
                          },
                        ),
                      );
                      var data =
                          json.decode(response.body) as Map<String, dynamic>;

                      print(data);

                      black_moved.add(data['ai_moved']);
                      prev_moved = data['ai_moved'];
                      states_loc = data['states_loc'];
                      wait = false;
                    }
                    super.setState(() {});
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
