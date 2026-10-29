import 'package:flutter_test/flutter_test.dart';
import 'package:fisherman_app/models/user_model.dart';
import 'package:fisherman_app/models/spot_model.dart';
import 'package:fisherman_app/models/catch_model.dart';
import 'package:fisherman_app/models/weather_model.dart';

void main() {
  group('FisherMan Data Models Unit Tests', () {
    test('UserModel parse and serialization', () {
      final json = {
        'id': 1,
        'username': 'diaoyu1',
        'nickname': '空军总司令',
        'avatar': 'https://example.com/avatar.jpg',
        'bio': '野钓三十载',
        'fishing_years': 15,
        'target_fish': '鲫鱼、青鱼',
        'stats': {
          'spotsCreated': 5,
          'catchesCount': 28,
          'totalWeightKg': 142.5,
          'maxWeightKg': 18.0,
          'badges': [
            {'id': 'monster_hunter', 'name': '巨物猎人', 'icon': '🦈'}
          ]
        }
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.nickname, '空军总司令');
      expect(user.fishingYears, 15);
      expect(user.stats.catchesCount, 28);
      expect(user.stats.maxWeightKg, 18.0);
      expect(user.stats.badges.length, 1);
      expect(user.stats.badges.first.name, '巨物猎人');

      final serialized = user.toJson();
      expect(serialized['username'], 'diaoyu1');
      expect(serialized['stats']['totalWeightKg'], 142.5);
    });

    test('SpotModel parse and coordinates', () {
      final json = {
        'id': 101,
        'name': '千岛湖羡山半岛野钓点',
        'description': '水质清澈，缓坡铧尖位出鱼极好',
        'lat': 29.5623,
        'lng': 119.0432,
        'water_type': '野钓',
        'charge_type': '免费',
        'fish_types': ['翘嘴', '鳙鱼', '青鱼'],
        'depth_meters': 5.5,
        'likes_count': 42,
        'is_favorited': true,
      };

      final spot = SpotModel.fromJson(json);
      expect(spot.id, 101);
      expect(spot.name, '千岛湖羡山半岛野钓点');
      expect(spot.lat, 29.5623);
      expect(spot.lng, 119.0432);
      expect(spot.waterType, '野钓');
      expect(spot.depthMeters, 5.5);
      expect(spot.fishTypes, contains('翘嘴'));
      expect(spot.isFavorited, isTrue);

      final copy = spot.copyWith(isFavorited: false, likesCount: 41);
      expect(copy.isFavorited, isFalse);
      expect(copy.likesCount, 41);
    });

    test('CatchModel parse and comment logic', () {
      final json = {
        'id': 501,
        'userId': 2,
        'userNickname': '路亚狂徒小林',
        'spotName': '千岛湖羡山半岛野钓点',
        'fishType': '翘嘴',
        'weightKg': 7.8,
        'lengthCm': 86.5,
        'fishingMethod': '路亚',
        'photoUrl': 'https://example.com/fish.jpg',
        'notes': '清晨一口爆截！',
        'likesCount': 89,
        'commentsCount': 1,
        'isLiked': true,
        'comments': [
          {
            'id': 1,
            'userId': 1,
            'userNickname': '空军总司令',
            'content': '太强了林大师！',
            'createdAt': '1小时前'
          }
        ]
      };

      final record = CatchModel.fromJson(json);
      expect(record.id, 501);
      expect(record.fishType, '翘嘴');
      expect(record.weightKg, 7.8);
      expect(record.fishingMethod, '路亚');
      expect(record.isLiked, isTrue);
      expect(record.comments.length, 1);
      expect(record.comments.first.userNickname, '空军总司令');
    });

    test('WeatherModel and barometric pressure rating', () {
      final json = {
        'temperature': '22°C',
        'pressure': '1013.2 hPa',
        'fishingScore': 92,
        'fishingStatus': '爆护指数极高',
        'advice': '黄金气压区间！',
        'hourlyForecast': [
          {
            'time': '06:00',
            'temperature': '18°C',
            'pressure': '1014.2 hPa',
            'biteIndex': '爆护'
          }
        ]
      };

      final weather = WeatherModel.fromJson(json);
      expect(weather.fishingScore, 92);
      expect(weather.fishingStatus, '爆护指数极高');
      expect(weather.hourlyForecast.first.time, '06:00');
    });
  });
}
