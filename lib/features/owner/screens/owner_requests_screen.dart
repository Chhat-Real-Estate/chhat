import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../requests/repositories/request_repository.dart';
import '../../requests/models/request_model.dart';

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

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('tenantProfiles')
                  .doc(req.tenantId)
                  .get(),
              builder: (ctx, tSnap) {
                String tenantName = 'Loading...';
                if (tSnap.hasData && tSnap.data!.exists) {
                  tenantName =
                      (tSnap.data!.data() as Map<String, dynamic>)['name'] ??
                          'Unknown Tenant';
                }

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
                      Text('Tenant: $tenantName',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800)),
                      _buildTimeline(req),
                      if (isAccepted) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final Uri url =
                                  Uri.parse('tel:+91${req.tenantPhone}');
                              launchUrl(url);
                            },
                            icon: const Icon(Icons.call,
                                color: Colors.white, size: 18),
                            label: Text('Call Tenant: +91 ${req.tenantPhone}',
                                style: const TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6))),
                          ),
                        )
                      ] else if (isPending) ...[
                        Row(
                          children: [
                            Expanded(
                                child: OutlinedButton(
                                    onPressed: () => RequestRepository()
                                        .updateRequestStatus(
                                            req.id!, 'rejected', widget.userId),
                                    style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.redAccent)),
                                    child: const Text('Reject',
                                        style: TextStyle(
                                            color: Colors.redAccent)))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: ElevatedButton(
                                    onPressed: () => RequestRepository()
                                        .updateRequestStatus(
                                            req.id!, 'accepted', widget.userId),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1A237E)),
                                    child: const Text('Accept',
                                        style:
                                            TextStyle(color: Colors.white)))),
                          ],
                        )
                      ],
                    ],
                  ),
                );
              },
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

            return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('tenantProfiles')
                    .doc(req.tenantId)
                    .get(),
                builder: (ctx, tSnap) {
                  String tenantName = 'Loading...';
                  if (tSnap.hasData && tSnap.data!.exists) {
                    tenantName =
                        (tSnap.data!.data() as Map<String, dynamic>)['name'] ??
                            'Unknown Tenant';
                  }

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
                        Text('Sent to: $tenantName',
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500)),
                        _buildTimeline(req),
                      ],
                    ),
                  );
                });
          },
        );
      },
    );
  }
}
