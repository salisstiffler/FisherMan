import 'package:flutter_test/flutter_test.dart';
import 'package:fisherman_app/core/utils/fishing_share_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'share card generator produces a PNG image with fishing details',
    () async {
      final image = await FishingShareCard.render('翘嘴 · 2.4 kg', '渔获战报', [
        '钓点：钱塘江',
        '钓法：路亚',
      ]);

      expect(image.length, greaterThan(8));
      expect(image.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    },
  );
}
