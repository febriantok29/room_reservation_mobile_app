import 'package:rapa_track_mobile_app/app/models/profile.dart';
import 'package:rapa_track_mobile_app/app/network/route_builder.dart';

class UserService {
  Future<List<Profile>> getUsers({
    String? search,
    int? perPage,
    int? page,
  }) async {
    final queries = <String, dynamic>{
      if (search?.isNotEmpty ?? false) 'q': search,
      if (perPage != null) 'per_page': perPage,
      if (page != null) 'page': page,
    };

    final route = RouteBuilder(
      'User.list',
      queries: queries.isNotEmpty ? queries : null,
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
