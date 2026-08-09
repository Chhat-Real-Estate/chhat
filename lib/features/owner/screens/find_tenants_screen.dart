import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../requests/repositories/request_repository.dart';
import '../../requests/models/request_model.dart';
import '../../reports/repositories/report_repository.dart';
import '../widgets/owner_filter_panel.dart';
import '../../notifications/widgets/notification_bell_icon.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/app_exceptions.dart';

const Color _blueDark = Color(0xFF1A237E);
const Color _blueLight = Color(0xFF3949AB);
const Color _bgColor = Color(0xFFF5F7F2);

class FindTenantsScreen extends StatefulWidget {
  const FindTenantsScreen({super.key});

  @override
  State<FindTenantsScreen> createState() => _FindTenantsScreenState();
}

class _FindTenantsScreenState extends State<FindTenantsScreen> {
  String _filterType = 'All Types';
  String _filterBudget = 'All Budgets';
  String _filterMoveIn = 'Any Move-in';
  bool _showFilters = false;
  String? userId;
  String _propertyKind = 'residential';

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
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        flexibleSpace: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [_blueDark, _blueLight]))),
        elevation: 0,
        title: const Text('Find Tenants',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (userId != null) NotificationBellIcon(userId: userId!),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.tune,
                color: const Color.fromARGB(255, 249, 248, 248)),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _propertyKind = 'residential';
                      _filterType = 'All Types';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _propertyKind == 'residential'
                            ? _blueDark
                            : Colors.white,
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(10)),
                        border: Border.all(color: _blueDark),
                      ),
                      child: Center(
                        child: Text('Residential',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _propertyKind == 'residential'
                                    ? Colors.white
                                    : _blueDark)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _propertyKind = 'commercial';
                      _filterType = 'All Types';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _propertyKind == 'commercial'
                            ? _blueDark
                            : Colors.white,
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(10)),
                        border: Border.all(color: _blueDark),
                      ),
                      child: Center(
                        child: Text('Commercial',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _propertyKind == 'commercial'
                                    ? Colors.white
                                    : _blueDark)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showFilters)
            OwnerFilterPanel(
              initialType: _filterType,
              initialBudget: _filterBudget,
              initialMoveIn: _filterMoveIn,
              propertyKind: _propertyKind,
              onApply: (type, budget, moveIn) {
                setState(() {
                  _filterType = type;
                  _filterBudget = budget;
                  _filterMoveIn = moveIn;
                  _showFilters = false;
                });
              },
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tenantProfiles')
                  .where('isProfileComplete', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _blueDark));
                }
                var docs = snapshot.data?.docs ?? [];

                docs = docs
                    .where((d) =>
                        ((d.data() as Map)['propertyKind'] ?? 'residential') ==
                        _propertyKind)
                    .toList();

                if (_filterType != 'All Types') {
                  docs = docs
                      .where(
                          (d) => (d.data() as Map)['tenantType'] == _filterType)
                      .toList();
                }
                if (_filterBudget != 'All Budgets') {
                  docs = docs
                      .where((d) =>
                          (d.data() as Map)['budgetRange'] == _filterBudget)
                      .toList();
                }
                if (_filterMoveIn != 'Any Move-in') {
                  docs = docs
                      .where((d) =>
                          (d.data() as Map)['moveInDate'] == _filterMoveIn)
                      .toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                      child: Text('Koi tenant match nahi hua.',
                          style: TextStyle(color: Colors.grey, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final tenantId = docs[index].id;
                    final tenantName = data['name'] ?? 'Unknown Tenant';
                    final timestamp = data['updatedAt'] as Timestamp?;
                    final timeString = timestamp != null
                        ? timestamp.toDate().toString().substring(0, 16)
                        : 'N/A';

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
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(tenantName,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: _blueDark),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: (data['propertyKind'] ==
                                                  'commercial')
                                              ? Colors.orange.shade50
                                              : Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(
                                          (data['propertyKind'] ??
                                                  'residential')
                                              .toString()
                                              .toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: (data['propertyKind'] ==
                                                      'commercial')
                                                  ? Colors.orange.shade800
                                                  : Colors.green.shade800)),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.flag_outlined,
                                        color: Colors.redAccent, size: 22),
                                    onPressed: () async {
                                      String? selectedReason;
                                      final confirm = await showDialog<String>(
                                          context: context,
                                          builder: (ctx) => StatefulBuilder(
                                              builder: (context,
                                                      setDialogState) =>
                                                  AlertDialog(
                                                    backgroundColor:
                                                        Colors.white,
                                                    surfaceTintColor:
                                                        Colors.white,
                                                    title: const Text(
                                                        'Report Agent?',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .redAccent,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    content:
                                                        SingleChildScrollView(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                              'Kya ye tenant ek broker/agent lag raha hai? Iski profile report karein.',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black87)),
                                                          const SizedBox(
                                                              height: 12),
                                                          RadioListTile<String>(
                                                              title: const Text(
                                                                  'Broker/Agent acting as Tenant',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .black87)),
                                                              value:
                                                                  'broker_acting_as_tenant',
                                                              groupValue:
                                                                  selectedReason,
                                                              activeColor:
                                                                  _blueDark,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              dense: true,
                                                              onChanged: (v) =>
                                                                  setDialogState(() =>
                                                                      selectedReason =
                                                                          v)),
                                                          RadioListTile<String>(
                                                              title: const Text(
                                                                  'Fake profile',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .black87)),
                                                              value:
                                                                  'fake_profile',
                                                              groupValue:
                                                                  selectedReason,
                                                              activeColor:
                                                                  _blueDark,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              dense: true,
                                                              onChanged: (v) =>
                                                                  setDialogState(() =>
                                                                      selectedReason =
                                                                          v)),
                                                          RadioListTile<String>(
                                                              title: const Text(
                                                                  'Scam or Fraud',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          13,
                                                                      color: Colors
                                                                          .black87)),
                                                              value: 'scam',
                                                              groupValue:
                                                                  selectedReason,
                                                              activeColor:
                                                                  _blueDark,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              dense: true,
                                                              onChanged: (v) =>
                                                                  setDialogState(() =>
                                                                      selectedReason =
                                                                          v)),
                                                        ],
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  ctx, null),
                                                          child: const Text(
                                                              'CANCEL',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .grey))),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .redAccent),
                                                        onPressed: () =>
                                                            Navigator.pop(ctx,
                                                                selectedReason),
                                                        child: const Text(
                                                            'REPORT',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white)),
                                                      ),
                                                    ],
                                                  )));

                                      if (confirm != null && userId != null) {
                                        await ReportRepository.submitReport(
                                            reporterId: userId!,
                                            reportedUserId: tenantId,
                                            reportType: confirm);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'Agent reported successfully!'),
                                                  backgroundColor:
                                                      Colors.redAccent));
                                        }
                                      }
                                    },
                                    tooltip: 'Report Agent',
                                  ),
                                  const Icon(Icons.verified_user_outlined,
                                      color: Color(0xFF1A237E), size: 20),
                                ],
                              )
                            ],
                          ),
                          Text('Active on: $timeString',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          const Divider(height: 24),
                          _buildInfoRow('Type:', data['tenantType'] ?? 'N/A'),
                          _buildInfoRow(
                              'Budget:', data['budgetRange'] ?? 'N/A'),
                          _buildInfoRow(
                              'Move In:', data['moveInDate'] ?? 'N/A'),
                          _buildInfoRow(
                              'Occupation:', data['occupation'] ?? 'N/A'),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    surfaceTintColor: Colors.white,
                                    title: const Text('Send Invitation?',
                                        style: TextStyle(
                                            color: Color(0xFF1A237E),
                                            fontWeight: FontWeight.bold)),
                                    content: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Your Contact number will be shared to Tenant. Are you sure you want to send invitation?',
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 14)),
                                        SizedBox(height: 16),
                                        Text('⚠️ BEWARE OF AGENT!',
                                            style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 255, 123, 0),
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            'If someone asks for commission, kindly report the account immediately.',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Color.fromARGB(
                                                    221, 255, 0, 43))),
                                        SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('🇮🇳',
                                                style: TextStyle(fontSize: 14)),
                                            SizedBox(width: 6),
                                            Expanded(
                                                child: Text(
                                                    'Agar koi commission maangta hai, toh turant us account ko report karein.',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Color.fromARGB(
                                                            221, 255, 0, 43),
                                                        fontWeight:
                                                            FontWeight.w500))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('NO',
                                              style: TextStyle(
                                                  color: Colors.grey))),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1A237E)),
                                        child: const Text('YES',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && userId != null) {
                                  try {
                                    final listingQuery = await FirebaseFirestore
                                        .instance
                                        .collection('listings')
                                        .where('ownerId', isEqualTo: userId)
                                        .limit(1)
                                        .get();
                                    if (listingQuery.docs.isEmpty) {
                                      if (context.mounted)
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Pehle ek room add kariye!')));
                                      return;
                                    }

                                    await RequestRepository()
                                        .sendRequest(RequestModel(
                                      tenantId: tenantId,
                                      tenantPhone: 'Hidden',
                                      listingId: listingQuery.docs.first.id,
                                      ownerId: userId!,
                                      area: listingQuery.docs.first
                                              .data()['area'] ??
                                          '',
                                      rent: listingQuery.docs.first
                                              .data()['rent'] ??
                                          0,
                                      senderType: 'owner',
                                    ));

                                    // NOTE: notification yahan client se nahi banate — index.js ka
                                    // onNewRequestCreated Cloud Function isse admin SDK se khud
                                    // handle karta hai jab request document create hota hai.

                                    if (context.mounted)
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Invitation Sent Successfully!'),
                                              backgroundColor: Colors.green));
                                  } catch (e, st) {
                                    AppLogger.error(
                                        'FindTenantsScreen.sendRoomInvite',
                                        e,
                                        st);
                                    if (context.mounted)
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(mapToAppException(e)
                                                  .message)));
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A237E),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8))),
                              child: const Text('Send Room Invite',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87))),
        ],
      ),
    );
  }
}
