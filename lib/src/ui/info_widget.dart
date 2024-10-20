import 'package:flutter/material.dart';

class InfoWidget extends StatefulWidget {
  final String title;
  final Widget child;
  final VoidCallback? toggleVisibility;
  final bool showVisibilityIcon;
  final bool showSettingsIcon;
  final bool showCloseIcon;

  InfoWidget({
    Key? key,
    required this.title,
    required this.child,
    this.toggleVisibility,
    this.showVisibilityIcon = true,
    this.showSettingsIcon = true,
    this.showCloseIcon = true,
  }) : super(key: key);

  @override
  _InfoWidgetState createState() => _InfoWidgetState();
}

class _InfoWidgetState extends State<InfoWidget> {
  bool _isHovered = false;
  bool _isVisible = true;
  double _height = 15;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Row(
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: 10.0, decoration: TextDecoration.none),
            ),
            _isHovered
                ? Row(
                    children: [
                      if (widget.showVisibilityIcon)
                        Container(
                          height: _height,
                          child: IconButton(
                            padding: EdgeInsets.all(0),
                            iconSize: 12,
                            splashRadius: 1,
                            icon: Icon(
                              _isVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => {
                              _isVisible = !_isVisible,
                              widget.toggleVisibility?.call()
                            },
                          ),
                        ),
                      if (widget.showSettingsIcon)
                        Container(
                          height: 12,
                          child: IconButton(
                            padding: EdgeInsets.all(0),
                            iconSize: 12,
                            splashRadius: 1,
                            icon: Icon(Icons.settings),
                            onPressed: _openSettingsDialog,
                          ),
                        ),
                      if (widget.showCloseIcon)
                        Container(
                          height: 12,
                          child: IconButton(
                            padding: EdgeInsets.all(0),
                            iconSize: 12,
                            splashRadius: 1,
                            icon: Icon(
                              _isVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: _closeWidget,
                          ),
                        ),
                    ],
                  )
                : widget.child,
          ],
        ),
      ),
    );
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings'),
          content: Text('Settings dialog content goes here.'),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _closeWidget() {
    setState(() {
      _isVisible = false;
    });
  }
}
