import 'package:room_reservation_mobile_app/app/models/profile.dart';
import 'package:room_reservation_mobile_app/app/network/route_builder.dart';

class UserService {
  Future<List<Profile>> getUsers({String? search}) async {
    final route = RouteBuilder(
      'User.list',
      queries: {if (search?.isNotEmpty ?? false) 'q': search},
    );
    final response = await route.get();

    final result = <Profile>[];

    if (response is! Map<String, dynamic>) {
      return result;
    }

    final data = response['data'];

    if (data is! List) {
      return result;
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => Profile.fromJson(json))
        .toList();
  }
}
