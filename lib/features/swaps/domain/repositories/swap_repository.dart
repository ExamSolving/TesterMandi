import '../entities/swap_request.dart';

abstract class SwapRepository {
  Future<void> sendSwapRequest({
    required String fromUserId,
    required String fromUserName,
    required String fromAppId,
    required String fromAppName,
    required String? fromAppIconUrl,
    required String toUserId,
    required String toAppId,
    required String toAppName,
    required String? toAppIconUrl,
  });

  Future<List<SwapRequest>> fetchPendingReceived(String userId);
  Future<List<SwapRequest>> fetchSentRequests(String userId);

  Future<void> acceptRequest({
    required SwapRequest request,
    required String ownerName,
    required String ownerOptInUrl,
    required String? ownerAppIconUrl,
  });

  Future<void> denyRequest(SwapRequest request);
  Future<void> cancelRequest(String requestId);

  /// True if sending a request from [fromAppId] → [toAppId] should be blocked.
  /// Checks: outgoing pending request, incoming pending request for the same
  /// pair, and whether the user is already a tester for [toAppId].
  Future<bool> hasPendingRequest({
    required String fromUserId,
    required String fromAppId,
    required String toAppId,
  });

  Stream<List<SwapRequest>> watchReceivedRequests(String userId);
  Stream<List<SwapRequest>> watchSentRequests(String userId);
}
