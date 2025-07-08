import 'package:flutter/material.dart';

import 'package:openlist_config/config/config.dart';
import 'package:openlist_web_ui/l10n/generated/openlist_web_ui_localizations.dart';

class SystemPage extends StatefulWidget {
  SystemPage({ Key? key}) : super(key: key);

  @override
  _SystemPageState createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List _result = [];
    // AList固定信息
    _result.add("AListWebAPIBaseUrl: $AListWebAPIBaseUrl");
    _result.add("AListAPIBaseUrl: $AListAPIBaseUrl");
    _result.add("WebPageBaseUrl: $WebPageBaseUrl");
    _result.add("DDNS-GO Url: http://localhost:9876");
    _result.add("GATEWAY-GO Url: http://localhost:34323");

    final tiles = _result.map(
      (pair) {
        return ListTile(
          title: Text(
            pair,
          ),
        );
      },
    );
    List<ListTile> tilesList = tiles.toList();
    final divided = ListTile.divideTiles(
      context: context,
      tiles: tilesList,
    ).toList();

    return Scaffold(
      appBar: AppBar(title: Text("System"), actions: <Widget>[
      ]),
      body: ListView(children: divided),
    );
  }
}
