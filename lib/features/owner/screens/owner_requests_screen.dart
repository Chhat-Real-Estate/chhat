import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../requests/repositories/request_repository.dart';
import '../../requests/models/request_model.dart';
import '../../../core/utils/app_exceptions.dart';

const Color _blueDark = Color(0xFF1A237E);
const Color _blueLight = Color(0xFF3949AB);
const Color _bgColor = Color(0xFFF5F7F2);

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

class OwnerRequestsScreen extends StatefulWidget {
  const OwnerRequestsScreen({super.key});

  @override
  State<OwnerRequestsScreen> createState() => _OwnerRequestsScreenState();
}

class _OwnerRequestsScreenState extends State<OwnerRequestsScreen> {
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          flexibleSpace: Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_blueDark, _blueLight]))),
          title: const Text('Requests',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Incoming'), Tab(text: 'Sent')],
          ),
        ),
        body: userId == null
            ? const Center(child: CircularProgressIndicator(color: _blueDark))
            : TabBarView(
                children: [
                  IncomingRequestsTab(userId: userId!),
                  SentRequestsTab(userId: userId!),
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

// --- OWNER INCOMING TAB ---
class IncomingRequestsTab extends StatefulWidget {
  final String userId;
  const IncomingRequestsTab({super.key, required this.userId});
  @override
  State<IncomingRequestsTab> createState() => _IncomingRequestsTabState();
}

class _IncomingRequestsTabState extends State<IncomingRequestsTab> {
  late Stream<List<RequestModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = RequestRepository().getOwnerRequests(widget.userId);
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
                      height: 180,
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

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
              child: Text('Abhi koi active request nahi aayi',
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final isAccepted = req.status == 'accepted';
            final isPending = req.status == 'pending';

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
                              color: Color(0xFF1A237E))),
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
                  _TenantNameText(
                      tenantId: req.tenantId,
                      prefix: 'Tenant: ',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800)),
                  _buildTimeline(req),
                  if (isAccepted) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: req.tenantPhone.isEmpty ||
                                req.tenantPhone == 'Hidden'
                            ? null
                            : () {
                                // FIX: tenantPhone already +91 ke saath
                                // saved hai, dobara prefix mat lagao.
                                final number = req.tenantPhone.startsWith('+')
                                    ? req.tenantPhone
                                    : '+91${req.tenantPhone}';
                                launchUrl(Uri.parse('tel:$number'));
                              },
                        icon: const Icon(Icons.call,
                            color: Colors.white, size: 18),
                        label: Text(
                            req.tenantPhone.isEmpty ||
                                    req.tenantPhone == 'Hidden'
                                ? 'Tenant number available nahi hai'
                                : 'Call Tenant: ${req.tenantPhone}',
                            style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6))),
                      ),
                    )
                  ] else if (isPending) ...[
                    _OwnerAcceptRejectButtons(
                        requestId: req.id!, userId: widget.userId)
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- OWNER SENT TAB ---
class SentRequestsTab extends StatefulWidget {
  final String userId;
  const SentRequestsTab({super.key, required this.userId});
  @override
  State<SentRequestsTab> createState() => _SentRequestsTabState();
}

class _SentRequestsTabState extends State<SentRequestsTab> {
  late Stream<List<RequestModel>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = RequestRepository().getOwnerSentRequests(widget.userId);
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
                          borderRadius: BorderRadius.circular(12)))));
        }

        if (snapshot.hasError) {
          return Center(
              child: Text('Error loading requests.',
                  style: TextStyle(color: Colors.red.shade400)));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
              child: Text('Aapne koi active invite nahi bheja hai.',
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
                  _TenantNameText(
                      tenantId: req.tenantId,
                      prefix: 'Sent to: ',
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

// NAYA: Accept/Reject buttons - busy state dikhata hai, error catch karke
// user-friendly message dikhata hai (pehle button silently kuch nahi karta
// tha agar update fail ho jaye, isliye "stuck" jaisa lagta tha).
class _OwnerAcceptRejectButtons extends StatefulWidget {
  final String requestId;
  final String userId;
  const _OwnerAcceptRejectButtons(
      {required this.requestId, required this.userId});

  @override
  State<_OwnerAcceptRejectButtons> createState() =>
      _OwnerAcceptRejectButtonsState();
}

class _OwnerAcceptRejectButtonsState extends State<_OwnerAcceptRejectButtons> {
  bool _busy = false;

  Future<void> _respond(String status) async {
    setState(() => _busy = true);
    try {
      await RequestRepository()
          .updateRequestStatus(widget.requestId, status, widget.userId);
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
                    backgroundColor: const Color(0xFF1A237E)),
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

// NAYA: Tenant ka naam ek hi baar fetch karta hai (initState), timeout +
// retry ke saath — pehle "Loading..." kabhi stuck ho sakta tha agar fetch
// fail ho jaaye ya list rebuild baar-baar naya Future bana deta tha.
class _TenantNameText extends StatefulWidget {
  final String tenantId;
  final String prefix;
  final TextStyle style;
  const _TenantNameText(
      {required this.tenantId, required this.prefix, required this.style});

  @override
  State<_TenantNameText> createState() => _TenantNameTextState();
}

class _TenantNameTextState extends State<_TenantNameText> {
  String _name = 'Loading...';
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _error = false;
      _name = 'Loading...';
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tenantProfiles')
          .doc(widget.tenantId)
          .get()
          .timeout(const Duration(seconds: 5));
      final name = doc.exists
          ? (doc.data() as Map<String, dynamic>)['name'] as String?
          : null;
      if (mounted) {
        setState(() =>
            _name = (name == null || name.isEmpty) ? 'Unknown Tenant' : name);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _name = 'Tap to retry';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _error ? _fetch : null,
      child: Text('${widget.prefix}$_name',
          style: _error
              ? widget.style.copyWith(color: Colors.redAccent)
              : widget.style),
    );
  }
}
