import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plugless/features/friends/presentation/widgets/friends_list_tab.dart';
import 'package:plugless/features/friends/presentation/widgets/received_requests_tab.dart';
import 'package:plugless/features/friends/presentation/widgets/sent_requests_tab.dart';
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: Text(
          'Friends',
          style: GoogleFonts.inter(
            color: const Color(0xFFF2F3F5),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFB5BAC1)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2C6DFE),
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            labelColor: const Color(0xFFF2F3F5),
            unselectedLabelColor: const Color(0xFF7C7C82),
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
            tabs: const [
              Tab(text: 'RECEIVED'),
              Tab(text: 'SENT'),
              Tab(text: 'FRIENDS'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ReceivedRequestsTab(),
          SentRequestsTab(),
          FriendsListTab(),
        ],
      ),
    );
  }
}
