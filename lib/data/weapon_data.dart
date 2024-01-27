import 'package:flutter_astroids/data/bullet_data.dart';

enum Weapons {
  pistol,
  uzi,
  shotgun,
  mines,
}

class WeaponData {
  BulletData bulletData;

  WeaponData(this.bulletData);
}
