import 'dart:convert';
import 'dart:developer';

import 'package:openlist_api/openlist_api.dart';
import 'package:openlist_config/config/config.dart';
import 'package:openlist_config/keys/keys.dart';
import 'package:openlist_web_ui/pages/common/appInfo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:openlist_web_ui/pages/web/fullScreenWeb.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:openlist_config/config/global.dart';
import 'package:openlist_web_ui/l10n/generated/openlist_web_ui_localizations.dart';
import 'package:openlist_utils/init.dart';

GlobalKey<WebScreenState> webGlobalKey = GlobalKey();

class WebScreen extends StatefulWidget {
  const WebScreen({super.key, required this.startUrl});

  final String startUrl;

  @override
  State<StatefulWidget> createState() {
    return WebScreenState();
  }
}

class WebScreenState extends State<WebScreen> {
  InAppWebViewController? _webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    allowsInlineMediaPlayback: true,
    allowBackgroundAudioPlaying: true,
    iframeAllowFullscreen: true,
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    useShouldOverrideUrlLoading: true,
  );

  double _progress = 0;
  String? _url;
  String? _currentUrl;
  // String _url = "http://localhost:8889";
  // String _url = "http://localhost:15244";
  // String _url = "https://baidu.com";
  bool _canGoBack = false;

  bool favorite = false;

  onClickNavigationBar() {
    log("onClickNavigationBar");
    _webViewController?.reload();
  }

  @override
  void initState() {
    super.initState();
    // Future.delayed(Duration(seconds: 1),(){_webViewController?.reload();});
  }

  @override
  void dispose() {
    _webViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_canGoBack,
        onPopInvoked: (didPop) async {
          log("onPopInvoked $didPop");
          if (didPop) return;
          _webViewController?.goBack();
        },
        child: Scaffold(
          appBar: AppBar(
            // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text("OpenList"),
            actions: _getActions(),
          ),
          body: Column(children: <Widget>[
            // SizedBox(height: MediaQuery.of(context).padding.top),
            // LinearProgressIndicator(
            //   value: _progress,
            //   backgroundColor: Colors.grey[200],
            //   valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            // ),
            Expanded(
              child: InAppWebView(
                initialSettings: settings,
                initialUrlRequest: URLRequest(url: WebUri(widget.startUrl)),
                onWebViewCreated: (InAppWebViewController controller) {
                  _webViewController = controller;
                },
                onLoadStart: (InAppWebViewController controller, Uri? url) {
                  log("onLoadStart $url");
                  setState(() {
                    _progress = 0;
                  });
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  log("shouldOverrideUrlLoading ${navigationAction.request.url}");

                  var uri = navigationAction.request.url!;
                  if (![
                    "http",
                    "https",
                    "file",
                    "chrome",
                    "data",
                    "javascript",
                    "about"
                  ].contains(uri.scheme)) {
                    log("shouldOverrideUrlLoading ${uri.toString()}");
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }

                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },
                onReceivedError: (controller, request, error) async {
                // TODO
                //   print(request.url);
                //   print(request.url.path);
                //   if (request.url.toString() == APIBaseUrl) {
                //     _webViewController?.reload();
                //     setState(() {
                //
                //     });
                //   }
                },
                onDownloadStartRequest: (controller, url) async {
                  Get.showSnackbar(GetSnackBar(
                    title: OpenListWebUiLocalizations.of(context).downloadThisFile,
                    message: url.suggestedFilename ??
                        url.contentDisposition ??
                        url.toString(),
                    duration: const Duration(seconds: 3),
                    mainButton: Column(children: [
                      TextButton(
                        onPressed: () {
                          launchUrlString(url.url.toString());
                        },
                        child: Text(OpenListWebUiLocalizations.of(context).download),
                      ),
                    ]),
                    onTap: (_) {
                      Clipboard.setData(
                          ClipboardData(text: url.url.toString()));
                      Get.closeCurrentSnackbar();
                      Get.showSnackbar(GetSnackBar(
                        message: OpenListWebUiLocalizations.of(context).copiedToClipboard,
                        duration: const Duration(seconds: 1),
                      ));
                    },
                  ));
                },
                onLoadStop:
                    (InAppWebViewController controller, Uri? url) async {
                  // setState(() {
                  //   _progress = 0;
                  // });
                  _currentUrl = url.toString();
                  if (!tokenSetted) {
                    tokenSetted = true;
                    await controller.webStorage.localStorage
                        .setItem(key: 'token', value: token);
                    // await controller.reload();
                    // Future.delayed(Duration(milliseconds: 20));
                    // await controller.reload();
                    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.startUrl)));
                  }
                },
                onProgressChanged:
                    (InAppWebViewController controller, int progress) {
                  setState(() {
                    _progress = progress / 100;
                    if (_progress == 1) _progress = 0;
                  });
                  controller.canGoBack().then((value) => setState(() {
                        _canGoBack = value;
                      }));
                  _checkFavorite();
                },
                onUpdateVisitedHistory: (InAppWebViewController controller,
                    WebUri? url, bool? isReload) {
                  _url = url.toString();
                },
              ),
            ),
          ]),
        ));
  }

  _changePassword(){
    TextEditingController passwordController =
    TextEditingController.fromValue(TextEditingValue(text: ""));
    showDialog(context: context, builder: (_){
      return AlertDialog(
          title: Text(OpenListWebUiLocalizations.of(context).modify_password),
          content: SizedBox(
              width: 250,
              height: 200,
              child: ListView(
                children: <Widget>[
                  Text("username: admin", style: TextStyle(fontSize: 16),),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10.0),
                      labelText: OpenListWebUiLocalizations.of(context).password,
                      helperText:
                      OpenListWebUiLocalizations.of(context).password,
                    ),
                  ),
                ],
              )),
          actions: <Widget>[
            TextButton(
              child: Text(OpenListWebUiLocalizations.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(OpenListWebUiLocalizations.of(context).modify),
              onPressed: () async {
                // TODO
                var backgrounService = BackgrounService(AListWebAPIBaseUrl);
                await backgrounService.setAdminPassword(passwordController.text);
                Navigator.of(context).pop();
              },
            )
          ]);
    });
  }

  _goToFullScreen() async {
    var url = await _webViewController?.getUrl();
    Navigator.push(context, MaterialPageRoute(builder: (ctx) {
      return FullScreenWeb(key: UniqueKey(),startUrl: url!.toString(),);
    }));
  }

  _openInBrowser() async {
    var url = await _webViewController?.getUrl();
    launchUrlString(url!.toString());
  }

  _favorite() async {
    var title = await _webViewController?.getTitle();
    var url = await _webViewController?.getUrl();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 换另一个标志，只有用户设置过的才不重置密码，因为不卸载安装新的开发版密码不正确
    if (!prefs.containsKey(FAVORITE_KEY)) {
      prefs.setStringList(FAVORITE_KEY, [jsonEncode({"title":title,"url":url!.toString()})]);
    }else{
      List<String> favorites = prefs.getStringList(FAVORITE_KEY)!;
      favorites.add(jsonEncode({"title":title,"url":url!.toString()}));
      prefs.setStringList(FAVORITE_KEY, favorites);
    }
    _checkFavorite();
  }

  _unFavorite() async {
    var title = await _webViewController?.getTitle();
    var url = await _webViewController?.getUrl();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 换另一个标志，只有用户设置过的才不重置密码，因为不卸载安装新的开发版密码不正确
    if (!prefs.containsKey(FAVORITE_KEY)) {
      _checkFavorite();
      return;
    }else{
      List<String> favorites = prefs.getStringList(FAVORITE_KEY)!;
      for (var value in favorites) {
        Map<String,dynamic> f = jsonDecode(value);
        if (f["url"] == url!.toString()) {
          favorites.remove(value);
          prefs.setStringList(FAVORITE_KEY, favorites);
          _checkFavorite();
          return;
        }
      }
    }
  }

  Future _checkFavorite() async {
    var url = await _webViewController?.getUrl();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(FAVORITE_KEY)) {
      setState(() {
        favorite = false;
      });
      return;
    }else{
      List<String> favorites = prefs.getStringList(FAVORITE_KEY)!;
      for (var value in favorites) {
        Map<String,dynamic> f = jsonDecode(value);
        if (f["url"] == url!.toString()) {
          setState(() {
            favorite = true;
          });
          return;
        }
      }
      setState(() {
        favorite = false;
      });
      return;
    }
  }

  List<Widget>? _getActions() {
    List<Widget>? actions = [
      // IconButton(onPressed: (){_changeDataPath();}, icon: Icon(Icons.file_copy_outlined)),
      IconButton(onPressed: (){_changePassword();}, icon: Icon(Icons.password)),
      IconButton(onPressed: (){_webViewController?.reload();}, icon: Icon(Icons.refresh)),
      IconButton(onPressed: (){_goToFullScreen();}, icon: Icon(Icons.fullscreen)),
      IconButton(onPressed: (){_openInBrowser();}, icon: Icon(Icons.open_in_browser))
    ];
    if (favorite) {
      actions.add(
        IconButton(onPressed: (){_unFavorite();}, icon: Icon(Icons.favorite,color: Colors.red,)),
      );
    }else{
      actions.add(
        IconButton(onPressed: (){_favorite();}, icon: Icon(Icons.favorite_border)),
      );
    }
    return actions;
  }
}
