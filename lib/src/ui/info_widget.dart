import 'package:flutter/material.dart';

class InfoWidget extends StatefulWidget {
  final String title;
  final int? length;
  final Widget child;
  final VoidCallback? toggleVisibility;
  final VoidCallback? closeCallback;
  final void Function(int, int?)? saveCallback;
  final bool showVisibilityIcon;
  final bool showSettingsIcon;
  final bool showCloseIcon;

  InfoWidget({
    Key? key,
    required this.title,
    required this.child,
    this.length,
    this.toggleVisibility,
    this.closeCallback,
    this.saveCallback,
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
  final TextEditingController _lengthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _lengthController.text = widget.length?.toString() ?? '';
  }

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
                              setState(() {
                                _isVisible = !_isVisible;
                                widget.toggleVisibility?.call();
                              })
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
                              Icons.close,
                            ),
                            onPressed: widget.closeCallback?.call,
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
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Change Length:'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lengthController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        hintText: "Length",
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                var length =
                    int.tryParse(_lengthController.text) ?? widget.length;
                widget.saveCallback?.call(length!, widget.length);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
