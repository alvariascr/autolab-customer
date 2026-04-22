import 'package:flutter/material.dart';

class SearchBarOverlay extends StatelessWidget {
  const SearchBarOverlay({
    super.key,
    required this.showSearchBar,
    required this.controller,
  });

  final bool showSearchBar;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      top: showSearchBar ? 16 : -100,
      left: 16,
      right: 16,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: controller,
            autofocus: showSearchBar,
            decoration: const InputDecoration(
              icon: Icon(Icons.search),
              hintText: 'Buscar talleres...',
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
