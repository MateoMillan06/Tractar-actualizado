import 'package:flutter/material.dart';
import 'liquid_background.dart';
import 'liquid_glass_card.dart';

Widget vehicleTripScaffold(BuildContext context, String title, List<Widget> children) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(title),
    ),
    body: LiquidBackground(
      child: Center(
        child: SizedBox(
          width: 520,
          child: LiquidGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children
                    .map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: w,
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}