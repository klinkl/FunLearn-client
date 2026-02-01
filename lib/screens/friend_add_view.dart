import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:funlearn_client/data/models/friendRequest.dart';
import 'package:funlearn_client/data/models/user.dart';
import 'package:funlearn_client/data/userController.dart';
import '../theme/customColors.dart';

class FriendAddView extends StatefulWidget {
  const FriendAddView({super.key});

  @override
  State<FriendAddView> createState() => _FriendAddViewState();
}

class _FriendAddViewState extends State<FriendAddView> {
  final TextEditingController _searchController = TextEditingController();
  final UserController userController = UserController.getInstance_();
  bool _searchLoading = false;
  Object? _searchError;
  User? _searchedUser;
  bool _listsLoading = true;
  Object? _listsError;
  List<FriendRequest> _sent = const [];
  List<FriendRequest> _received = const [];
  String? _myUserId;
  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() {
      _listsLoading = true;
      _listsError = null;
    });

    try {
      // ensure current user exists before list calls
      final user = await userController.getOrCreateUser();
      _myUserId = user.userId;
      final sent = await userController.getSent();
      final received = await userController.getReceived();

      if (!mounted) return;
      setState(() {
        _sent = sent!;
        _received = received!;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _listsError = e);
    } finally {
      if (!mounted) return;
      setState(() => _listsLoading = false);
    }
  }

  Future<void> _copyMyUserId() async {
    final id = _myUserId;
    if (id == null || id.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied userId')));
  }

  Future<void> _onSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) return;
    setState(() {
      _searchLoading = true;
      _searchError = null;
      _searchedUser = null;
    });

    try {
      final user = await userController.refreshFromServer(query)!;
      setState(() => _searchedUser = user);
    } catch (e) {
      setState(() => _searchError = e);
    } finally {
      setState(() => _searchLoading = false);
    }
  }

  Future<void> _addFriend(User user) async {
    var self = await userController.getOrCreateUser();
    await userController.sendFriendRequest(self, user);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Friend request sent')));
    if (!mounted) return;
    await _loadLists();
  }

  Future<void> _acceptFriend(FriendRequest request) async {
    await userController.acceptFriendRequest(
      FriendRequest(request.fromUser, request.toUser, true),
    );
    if (!mounted) return;
    await _loadLists();
  }

  Future<void> _declineReceived(FriendRequest request) async {
    await userController.declineFriendRequest(request);
    if (!mounted) return;
    await _loadLists();
  }

  Future<void> _deleteSent(FriendRequest request) async {
    await userController.declineFriendRequest(request);
    if (!mounted) return;
    await _loadLists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final customColors = Theme.of(context).extension<CustomColors>()!;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top search area
            Container(
              height: screenHeight * 0.33,
              padding: const EdgeInsets.all(16),
              color: cs.surface,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.badge),
                            title: const Text('Your userId'),
                            subtitle: Text(_myUserId ?? '...'),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: _myUserId == null
                                  ? null
                                  : _copyMyUserId,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _onSearch(),
                          decoration: InputDecoration(
                            hintText: 'Search users by userId',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _onSearch,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade300,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadLists,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Search result card
                    _buildSearchResult(cs),

                    const SizedBox(height: 16),

                    // Friend requests lists
                    _buildRequestsSection(cs),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult(ColorScheme cs) {
    if (_searchLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchError != null) {
      return Text(
        'Search failed: $_searchError',
        style: TextStyle(color: cs.error),
        textAlign: TextAlign.center,
      );
    }

    if (_searchedUser == null) {
      return const SizedBox.shrink();
    }

    final u = _searchedUser!;
    final displayName = (u.username.isNotEmpty ? u.username : u.userId)
        .toString();

    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(displayName),
        subtitle: Text(u.userId),
        trailing: ElevatedButton.icon(
          onPressed: () => _addFriend(u),
          icon: const Icon(Icons.person_add),
          label: const Text('Add'),
        ),
      ),
    );
  }

  Widget _buildRequestsSection(ColorScheme cs) {
    if (_listsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_listsError != null) {
      return Text(
        'Failed to load requests: $_listsError',
        style: TextStyle(color: cs.error),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Received requests',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_received.isEmpty)
          const Text(
            'No received requests.',
            style: TextStyle(color: Colors.grey),
          )
        else
          ..._received.map(
            (req) => Card(
              child: ListTile(
                leading: const Icon(Icons.mail),
                title: Text('From: ${req.fromUser}'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _acceptFriend(req),
                      child: const Text('Accept'),
                    ),
                    OutlinedButton(
                      onPressed: () => _declineReceived(req),
                      child: const Text('Decline'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(height: 16),

        Text('Sent requests', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_sent.isEmpty)
          const Text('No sent requests.', style: TextStyle(color: Colors.grey))
        else
          ..._sent.map(
            (req) => Card(
              child: ListTile(
                leading: const Icon(Icons.send),
                title: Text('To: ${req.toUser}'),
                subtitle: Text('From: ${req.fromUser}'),
                trailing: OutlinedButton.icon(
                  onPressed: () => _deleteSent(req),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
