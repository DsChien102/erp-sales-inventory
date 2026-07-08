import 'package:flutter/material.dart';

void main() {
  DropdownMenu<String> menu = DropdownMenu<String>(
    dropdownMenuEntries: [],
    filterCallback: (entries, filter) => entries,
    searchCallback: (entries, query) => 0,
  );
}
