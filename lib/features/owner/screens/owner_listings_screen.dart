import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/repositories/listing_repository.dart';
import '../widgets/owner_listing_card.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/empty_state_view.dart';

const Color _blueDark = Color(0xFF1A237E);
const Color _blueLight = Color(0xFF3949AB);
const Color _bgColor = Color(0xFFF5F7F2);

class OwnerListingsScreen extends StatefulWidget {
  const OwnerListingsScreen({super.key});

  @override
  State<OwnerListingsScreen> createState() => _OwnerListingsScreenState();
}

class _OwnerListingsScreenState extends State<OwnerListingsScreen> {
  String? userId;
  Stream<List<ListingModel>>? _listingsStream;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedUserId = prefs.getString('userId');
    setState(() {
      userId = loadedUserId;
      if (loadedUserId != null) {
        _listingsStream = ListingRepository().getOwnerListings(loadedUserId);
      }
    });
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
        title: const Text('Meri Listings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: userId == null
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) => const AppSkeletonListingCard(),
            )
          : StreamBuilder<List<ListingModel>>(
              stream: _listingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) =>
                        const AppSkeletonListingCard(),
                  );
                }
                final listings = snapshot.data ?? [];

                if (listings.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.home_work_outlined,
                    title: 'Abhi koi listing nahi hai',
                    subtitle:
                        'Apna pehla kamra list karein aur verified tenants se direct judiye.',
                    buttonText: 'Naya Room Add Karein',
                    themeColor: _blueDark,
                    onButtonPressed: () => context.push('/add-listing'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (context, index) =>
                      OwnerFullListingCard(listing: listings[index]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-listing'),
        backgroundColor: _blueDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Room Add Karo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
