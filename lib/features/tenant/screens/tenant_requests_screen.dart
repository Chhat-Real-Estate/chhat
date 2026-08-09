import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../requests/repositories/request_repository.dart';
import '../../requests/models/request_model.dart';
import '../../../core/utils/app_exceptions.dart';

// NAYA: Skeleton Animation
class _PulseSkeleton extends StatefulWidget {
  final Widget child;
  const _PulseSkeleton({required this.child});
  @override
  State<_PulseSkeleton> createState() => _PulseSkeletonState();
}

class _PulseSkeletonState extends State<_PulseSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: Tween(begin: 0.5, end: 1.0).animate(_controller),
        child: widget.child);
  }
}

class TenantRequestsScreen extends StatefulWidget {
  const TenantRequestsScreen({super.key});

  @override
  State<TenantRequestsScreen> createState() => _TenantRequestsScreenState();
}

class _TenantRequestsScreenState extends State<TenantRequestsScreen> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => userId = prefs.getString('userId'));
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
          backgroundColor: Color(0xFFF5F7F2),
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFC62828))));
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFC62828),
          elevation: 0,
          title: const Text('My Requests',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Sent (Aapne Bheja)'),
              Tab(text: 'Incoming (Owner Invite)')
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TenantSentTab(userId: userId!),
            _TenantIncomingTab(userId: userId!),
          ],
        ),
      ),
    );
  }
}

// --- SHARED TIMELINE WIDGET ---
Widget _buildTimeline(RequestModel req) {
  final isPending = req.status == 'pending';
  final isAccepted = req.status == 'accepted';
  final statusColor = isPending
      ? Colors.orange
      : (isAccepted ? Colors.green : Colors.redAccent);
  final dateStr = req.createdAt.toString().substring(0, 16);

  return Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200)),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.blue, size: 18),
            Expanded(
                child:
                    Container(height: 3, color: statusColor.withOpacity(0.4))),
            Icon(
                isPending
                    ? Icons.access_time_filled
                    : (isAccepted ? Icons.check_circle : Icons.cancel),
                color: statusColor,
                size: 18),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sent\n$dateStr',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(
                isPending
                    ? 'Pending\nWaiting...'
                    : (isAccepted ? 'Accepted\nDone' : 'Rejected\nClosed'),
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold)),
          ],
        )
      ],
    ),
  );
}

// --- TENANT SENT TAB ---
class _TenantSentTab extends StatefulWidget {
  final String userId;
  const _TenantSentTab({required this.userId});
  @override
  State<_TenantSentTab> createState() => _TenantSentTabState();
}

class _TenantSentTabState extends State<_TenantSentTab> {
  late Stream<List<RequestModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = RequestRepository()
        .getTenantSentRequests(widget.userId); // NAYA: API Optimization
  }

  Future<void> _deleteRequest(String reqId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title:
            const Text('Delete Request?', style: TextStyle(color: Colors.red)),
        content: const Text(
            'Kya aap sachme is request ko delete karna chahte hain? Ye dono taraf se hamesha ke liye delete ho jayegi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await RequestRepository().deleteRequest(
            reqId, widget.userId); // NAYA: Proper Backend Validation & Delete
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Request deleted permanently.'),
              backgroundColor: Colors.redAccent));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Delete failed. Check internet.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (context, index) => _PulseSkeleton(
              child: Container(
                  height: 140,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12))),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading requests.',
                  style: TextStyle(color: Colors.red.shade400)));
        }

        var requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
              child: Text('Aapne abhi tak koi request nahi bheji',
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Room: ${req.area}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _deleteRequest(req.id!)),
                    ],
                  ),
                  Text('Kiraya: ₹${req.rent}',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500)),
                  _buildTimeline(req),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- TENANT INCOMING TAB ---
class _TenantIncomingTab extends StatefulWidget {
  final String userId;
  const _TenantIncomingTab({required this.userId});
  @override
  State<_TenantIncomingTab> createState() => _TenantIncomingTabState();
}

class _TenantIncomingTabState extends State<_TenantIncomingTab> {
  late Stream<List<RequestModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = RequestRepository().getTenantIncomingRequests(widget.userId);
  }

  Future<void> _deleteRequest(String reqId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title:
            const Text('Delete Request?', style: TextStyle(color: Colors.red)),
        content: const Text(
            'Kya aap sachme is request ko delete karna chahte hain? Ye dono taraf se hamesha ke liye delete ho jayegi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await RequestRepository().deleteRequest(reqId, widget.userId);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Request deleted permanently.'),
              backgroundColor: Colors.redAccent));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Delete failed.')));
      }
    }
  }

  Future<void> _showReportDialog(String ownerId, String reqId) async {
    String? selectedReason;
    final confirm = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Report Owner?',
              style: TextStyle(
                  color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Owner ko report kyu karna chahte hain?',
                    style: TextStyle(fontSize: 14, color: Colors.black87)),
                RadioListTile<String>(
                    title: const Text('Agent/Broker nikla',
                        style: TextStyle(fontSize: 13)),
                    value: 'broker',
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFC62828),
                    onChanged: (v) => setDialogState(() => selectedReason = v)),
                RadioListTile<String>(
                    title: const Text('Galat room dikhaya',
                        style: TextStyle(fontSize: 13)),
                    value: 'fake',
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFC62828),
                    onChanged: (v) => setDialogState(() => selectedReason = v)),
                RadioListTile<String>(
                    title: const Text('Paise zyada maang raha hai',
                        style: TextStyle(fontSize: 13)),
                    value: 'money',
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFC62828),
                    onChanged: (v) => setDialogState(() => selectedReason = v)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selectedReason),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828)),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != null) {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': widget.userId,
        'reportedUserId': ownerId,
        'reason': confirm,
        'createdAt': FieldValue.serverTimestamp()
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Owner reported!'),
            backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => _PulseSkeleton(
                  child: Container(
                      height: 160,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)))));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading requests.',
                  style: TextStyle(color: Colors.red.shade400)));
        }

        var requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
              child: Text('Koi naya invite nahi aaya',
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final isPending = req.status == 'pending';
            final isAccepted = req.status == 'accepted';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Invite: ${req.area}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _deleteRequest(req.id!)),
                    ],
                  ),
                  Text('Kiraya: ₹${req.rent}',
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500)),
                  _buildTimeline(req),
                  if (isAccepted) ...[
                    _CallOwnerButton(ownerId: req.ownerId)
                  ] else if (isPending) ...[
                    _AcceptRejectButtons(
                        requestId: req.id!, userId: widget.userId)
                  ],
                  const Divider(),
                  GestureDetector(
                    onTap: () => _showReportDialog(req.ownerId, req.id!),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.flag, size: 14, color: Colors.redAccent),
                          SizedBox(width: 4),
                          Text('Report Owner',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold))
                        ]),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// NAYA: Call Owner button - ek hi baar fetch karta hai (initState), stuck
// "Loading..." aur double +91 dono bugs fix karta hai.
class _CallOwnerButton extends StatefulWidget {
  final String ownerId;
  const _CallOwnerButton({required this.ownerId});

  @override
  State<_CallOwnerButton> createState() => _CallOwnerButtonState();
}

enum _CallState { loading, ready, error }

class _CallOwnerButtonState extends State<_CallOwnerButton> {
  _CallState _state = _CallState.loading;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _fetchOwnerPhone();
  }

  Future<void> _fetchOwnerPhone() async {
    setState(() => _state = _CallState.loading);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.ownerId)
          .get()
          .timeout(const Duration(seconds: 5));
      final phone = doc.exists
          ? (doc.data() as Map<String, dynamic>)['phone'] as String?
          : null;
      if (phone == null || phone.isEmpty) {
        if (mounted) setState(() => _state = _CallState.error);
        return;
      }
      if (mounted) {
        setState(() {
          _phone = phone;
          _state = _CallState.ready;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = _CallState.error);
    }
  }

  void _call() {
    // FIX: 'phone' Firestore me already +91 ke saath saved hai, dobara
    // prefix mat lagao warna +91+91XXXXXXXXXX ban jaata hai.
    final number = _phone!.startsWith('+') ? _phone! : '+91$_phone';
    launchUrl(Uri.parse('tel:$number'));
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _CallState.error) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _fetchOwnerPhone,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Number nahi mila, dobara try karo'),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _state == _CallState.ready ? _call : null,
        icon: _state == _CallState.loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.call, color: Colors.white, size: 18),
        label: Text(_state == _CallState.loading ? 'Loading...' : 'Call Owner',
            style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
      ),
    );
  }
}

// NAYA: Accept/Reject buttons - busy state dikhata hai, error catch karke
// user-friendly message dikhata hai (pehle button silently kuch nahi karta
// tha agar update fail ho jaye, isliye "stuck" jaisa lagta tha).
class _AcceptRejectButtons extends StatefulWidget {
  final String requestId;
  final String userId;
  const _AcceptRejectButtons({required this.requestId, required this.userId});

  @override
  State<_AcceptRejectButtons> createState() => _AcceptRejectButtonsState();
}

class _AcceptRejectButtonsState extends State<_AcceptRejectButtons> {
  bool _busy = false;

  Future<void> _respond(String status) async {
    setState(() => _busy = true);
    try {
      String? myPhone;
      if (status == 'accepted') {
        final prefs = await SharedPreferences.getInstance();
        myPhone = prefs.getString('userPhone');
      }
      await RequestRepository().updateRequestStatus(
          widget.requestId, status, widget.userId,
          tenantPhone: myPhone);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mapToAppException(e).message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: OutlinedButton(
                onPressed: _busy ? null : () => _respond('rejected'),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent)),
                child: const Text('Reject',
                    style: TextStyle(color: Colors.redAccent)))),
        const SizedBox(width: 8),
        Expanded(
            child: ElevatedButton(
                onPressed: _busy ? null : () => _respond('accepted'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828)),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Accept',
                        style: TextStyle(color: Colors.white)))),
      ],
    );
  }
}
