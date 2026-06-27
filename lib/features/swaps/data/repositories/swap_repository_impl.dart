import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/swap_request.dart';
import '../../domain/repositories/swap_repository.dart';
import '../models/swap_request_model.dart';
import '../../../testing/data/models/test_participation_model.dart';
import '../../../chat/data/models/chat_room_model.dart';

class SwapRepositoryImpl implements SwapRepository {
  SwapRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('swap_requests');

  CollectionReference<Map<String, dynamic>> get _participations =>
      _db.collection('participations');

  CollectionReference<Map<String, dynamic>> get _apps =>
      _db.collection('apps');

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Canonical key for an app pair — order-independent.
  String _pairKey(String a, String b) => ([a, b]..sort()).join('_');

  /// Deterministic participation ID: unique per (appId, testerId).
  /// Using a fixed ID means a second write is a no-op rather than a duplicate.
  String _participationId(String appId, String testerId) =>
      '${appId}_$testerId';

  /// Deterministic chat room ID: unique per user pair regardless of direction.
  String _chatRoomId(String uid1, String uid2) =>
      'chat_${([uid1, uid2]..sort()).join('_')}';

  // ── Send swap request ────────────────────────────────────────────────────

  @override
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
  }) async {
    final id = const Uuid().v4();
    final model = SwapRequestModel(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromAppId: fromAppId,
      fromAppName: fromAppName,
      fromAppIconUrl: fromAppIconUrl,
      toUserId: toUserId,
      toAppId: toAppId,
      toAppName: toAppName,
      toAppIconUrl: toAppIconUrl,
      status: SwapStatus.pending,
      createdAt: Timestamp.now(),
    );
    final data = model.toFirestore();
    // Store a canonical pair key so queries can check both directions cheaply.
    data['swapPairKey'] = _pairKey(fromAppId, toAppId);
    await _col.doc(id).set(data);
  }

  // ── Fetch / watch ────────────────────────────────────────────────────────

  @override
  Future<List<SwapRequest>> fetchPendingReceived(String userId) async {
    final snap = await _col.where('toUserId', isEqualTo: userId).get();
    return snap.docs
        .map(SwapRequestModel.fromFirestore)
        .where((r) => r.status == SwapStatus.pending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<SwapRequest>> fetchSentRequests(String userId) async {
    final snap = await _col.where('fromUserId', isEqualTo: userId).get();
    return snap.docs
        .map(SwapRequestModel.fromFirestore)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Stream<List<SwapRequest>> watchReceivedRequests(String userId) {
    return _col.where('toUserId', isEqualTo: userId).snapshots().map((snap) {
      return snap.docs
          .map(SwapRequestModel.fromFirestore)
          .where((r) => r.status == SwapStatus.pending)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Stream<List<SwapRequest>> watchSentRequests(String userId) {
    return _col.where('fromUserId', isEqualTo: userId).snapshots().map((snap) {
      return snap.docs
          .map(SwapRequestModel.fromFirestore)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // ── Bidirectional duplicate guard ─────────────────────────────────────────

  @override
  Future<bool> hasPendingRequest({
    required String fromUserId,
    required String fromAppId,
    required String toAppId,
  }) async {
    // 1. Outgoing: I already sent a non-denied request targeting toAppId.
    final outSnap =
        await _col.where('fromUserId', isEqualTo: fromUserId).get();
    final hasOutgoing = outSnap.docs.any((doc) {
      final d = doc.data();
      return (d['status'] as String? ?? '') != 'denied' &&
          d['toAppId'] == toAppId;
    });
    if (hasOutgoing) return true;

    // 2. Incoming: someone already sent me a request for the SAME app pair
    //    in the reverse direction (they offer toAppId, want fromAppId).
    final inSnap =
        await _col.where('toUserId', isEqualTo: fromUserId).get();
    final hasIncoming = inSnap.docs.any((doc) {
      final d = doc.data();
      return (d['status'] as String? ?? '') != 'denied' &&
          d['fromAppId'] == toAppId &&
          d['toAppId'] == fromAppId;
    });
    if (hasIncoming) return true;

    // 3. Already participating as tester in toAppId (swap already completed).
    final partSnap =
        await _participations.where('testerId', isEqualTo: fromUserId).get();
    return partSnap.docs.any((doc) => doc.data()['appId'] == toAppId);
  }

  // ── Accept (idempotent transaction) ──────────────────────────────────────

  @override
  Future<void> acceptRequest({
    required SwapRequest request,
    required String ownerName,
    required String ownerOptInUrl,
    required String? ownerAppIconUrl,
  }) async {
    // Fetch fromApp's optInUrl before the transaction — queries not allowed
    // inside Firestore transactions.
    final fromAppDoc = await _apps.doc(request.fromAppId).get();
    final fromOptInUrl =
        fromAppDoc.data()?['optInUrl'] as String? ?? '';
    final now = Timestamp.now();

    // Deterministic IDs: if acceptRequest runs twice (race between two users
    // both accepting each other's request), the second transaction reads
    // existing docs and skips already-created participations / chat room.
    final p1Id = _participationId(request.toAppId, request.fromUserId);
    final p2Id = _participationId(request.fromAppId, request.toUserId);
    final chatId = _chatRoomId(request.fromUserId, request.toUserId);

    await _db.runTransaction((tx) async {
      final p1Snap = await tx.get(_participations.doc(p1Id));
      final p2Snap = await tx.get(_participations.doc(p2Id));
      final chatSnap = await tx.get(_db.collection('chats').doc(chatId));

      // Mark this request accepted.
      tx.update(_col.doc(request.id), {'status': 'accepted'});

      // Participation 1: requester (fromUser) tests owner's app (toApp).
      if (!p1Snap.exists) {
        tx.set(
          _participations.doc(p1Id),
          TestParticipationModel(
            id: p1Id,
            appId: request.toAppId,
            appName: request.toAppName,
            appOwnerName: ownerName,
            appOwnerId: request.toUserId,
            testerId: request.fromUserId,
            testerName: request.fromUserName,
            joinedAt: now,
            optInUrl: ownerOptInUrl,
            iconUrl: request.toAppIconUrl,
          ).toFirestore(),
        );
        tx.set(
          _apps.doc(request.toAppId),
          {'testerIds': FieldValue.arrayUnion([request.fromUserId])},
          SetOptions(merge: true),
        );
      }

      // Participation 2: owner (toUser) tests requester's app (fromApp).
      if (!p2Snap.exists) {
        tx.set(
          _participations.doc(p2Id),
          TestParticipationModel(
            id: p2Id,
            appId: request.fromAppId,
            appName: request.fromAppName,
            appOwnerName: request.fromUserName,
            appOwnerId: request.fromUserId,
            testerId: request.toUserId,
            testerName: ownerName,
            joinedAt: now,
            optInUrl: fromOptInUrl,
            iconUrl: request.fromAppIconUrl,
          ).toFirestore(),
        );
        tx.set(
          _apps.doc(request.fromAppId),
          {'testerIds': FieldValue.arrayUnion([request.toUserId])},
          SetOptions(merge: true),
        );
      }

      // Chat room — create only once, never overwrite existing conversation.
      if (!chatSnap.exists) {
        tx.set(
          _db.collection('chats').doc(chatId),
          ChatRoomModel.toFirestore(
            id: chatId,
            participantIds: [request.fromUserId, request.toUserId],
            participantNames: {
              request.fromUserId: request.fromUserName,
              request.toUserId: ownerName,
            },
            fromAppName: request.fromAppName,
            toAppName: request.toAppName,
            fromAppIconUrl: request.fromAppIconUrl,
            toAppIconUrl: request.toAppIconUrl,
            createdAt: now,
          ),
        );
      }
    });

    // Outside the transaction: deny the pending reverse request (if any) so
    // the other user no longer sees a stale "Accept" button.
    await _denyReversePendingRequests(
      acceptedId: request.id,
      fromAppId: request.fromAppId,
      toAppId: request.toAppId,
      toUserId: request.toUserId,
    );
  }

  // ── Deny ─────────────────────────────────────────────────────────────────

  @override
  Future<void> denyRequest(SwapRequest request) async {
    await _col.doc(request.id).update({'status': 'denied'});
  }

  // ── Private: clean up reverse duplicate after accept ──────────────────────

  Future<void> _denyReversePendingRequests({
    required String acceptedId,
    required String fromAppId,
    required String toAppId,
    required String toUserId,
  }) async {
    // The "toUser" (who just accepted) may have a pending outgoing request for
    // the same app pair in the reverse direction. Deny it so it disappears.
    final snap =
        await _col.where('fromUserId', isEqualTo: toUserId).get();
    final stale = snap.docs.where((doc) {
      if (doc.id == acceptedId) return false;
      final d = doc.data();
      return (d['status'] as String? ?? '') == 'pending' &&
          d['fromAppId'] == toAppId &&
          d['toAppId'] == fromAppId;
    }).toList();

    if (stale.isEmpty) return;
    final batch = _db.batch();
    for (final doc in stale) {
      batch.update(doc.reference, {'status': 'denied'});
    }
    await batch.commit();
  }
}
