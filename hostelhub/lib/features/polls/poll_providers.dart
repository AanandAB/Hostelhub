import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend_provider.dart';
import '../../data/models/poll.dart';
import '../../data/models/poll_response.dart';

final pollsProvider = FutureProvider.family<List<Poll>, String>(
    (ref, propertyId) => ref.watch(backendProvider).polls.listPolls(propertyId));

final pollResponsesProvider =
    FutureProvider.family<List<PollResponse>, String>(
        (ref, pollId) =>
            ref.watch(backendProvider).polls.listResponses(pollId));
