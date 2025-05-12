import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material_model.dart'; // ← あなたのモデルに合わせて調整してね

final selectedMaterialProvider =
    StateProvider<PracticeMaterial?>((ref) => null);
