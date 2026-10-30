import 'package:flutter/material.dart';

/// Kullanıcının check-in sırasında seçtiği kısa anlık statü.
enum CheckInStatus {
  drinkingCoffee('Kahve içiyorum', Icons.local_cafe_outlined),
  working('Çalışıyorum', Icons.laptop_mac_outlined),
  socializing('Sosyalleşiyorum', Icons.groups_outlined),
  openToMeet('Tanışmaya açığım', Icons.waving_hand_outlined);

  const CheckInStatus(this.label, this.icon);

  final String label;
  final IconData icon;
}
