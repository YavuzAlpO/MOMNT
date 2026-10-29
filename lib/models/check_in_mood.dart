import 'package:flutter/material.dart';

enum CheckInMood {
  justChillin("Just Chillin'", Icons.coffee_outlined),
  withMyCrew('With My Crew', Icons.groups_outlined),
  openToMeet('Open to Meet', Icons.waving_hand_outlined),
  letsTalk("Let's Talk", Icons.chat_bubble_outline);

  const CheckInMood(this.label, this.icon);

  final String label;
  final IconData icon;
}
