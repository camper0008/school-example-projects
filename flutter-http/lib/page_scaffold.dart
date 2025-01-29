import 'package:flutter/material.dart';
import 'package:provider/single_child_widget.dart';

class PageScaffold extends SingleChildStatelessWidget {
  const PageScaffold({super.key, super.child});

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(Size(1000.0, double.infinity)),
          child: Padding(padding: EdgeInsets.all(16.0), child: child),
        ),
      ),
    );
  }
}
