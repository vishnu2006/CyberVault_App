import 'package:flutter/material.dart';

import '../services/master_key_service.dart';
import 'login_screen.dart';

/// Empty vault shown when duress PIN (9999) is used.
/// Same UI layout as VaultHome but always empty list — must navigate from duress PIN login.
class VaultHomeFakeScreen extends StatefulWidget {
  static const routeName = '/vault-home-fake';

  const VaultHomeFakeScreen({super.key});

  @override
  State<VaultHomeFakeScreen> createState() => _VaultHomeFakeScreenState();
}

class _VaultHomeFakeScreenState extends State<VaultHomeFakeScreen> {
  Future<void> _onRefresh() async {
    // Fake vault: no documents ever
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              MasterKeyService.instance.wipe();
              Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search documents...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 80,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.4),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Documents Found',
                              style:
                                  Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your vault is empty',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
