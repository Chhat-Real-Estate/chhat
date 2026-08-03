import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/repositories/listing_repository.dart';
import '../widgets/owner_listing_card.dart';

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
          ? const Center(child: CircularProgressIndicator(color: _blueDark))
          : StreamBuilder<List<ListingModel>>(
              stream: _listingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _blueDark));
                }
                final listings = snapshot.data ?? [];

                if (listings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_outlined,
                            size: 80, color: Color(0xFFCCCCCC)),
                        SizedBox(height: 16),
                        Text('Abhi koi listing nahi hai',
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFF999999))),
                      ],
                    ),
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
