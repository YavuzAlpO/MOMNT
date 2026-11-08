import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momnt/services/location_service.dart';

enum _Section {
  account('Hesap', 'Profil bilgilerin', Icons.person_outline),
  privacy('Gizlilik', 'İzinler ve engellenenler', Icons.shield_outlined),
  blocked('Engellenenler', 'Engellenen hesaplar', Icons.block_outlined),
  permissions('İzinler', 'Konum, kamera ve mikrofon', Icons.tune_outlined),
  membership('Üyelik', 'Plus seçenekleri', Icons.star_outline),
  support('Destek', 'Yardım ve sık sorulan sorular', Icons.help_outline);

  const _Section(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({
    super.key,
    required this.onEditProfile,
    this.locationService = const LocationService(),
  });

  final VoidCallback onEditProfile;
  final LocationService locationService;

  void _openSection(BuildContext context, _Section section) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => _SettingsPage(
          title: section.title,
          children: switch (section) {
            _Section.account => [
              _SettingsRow(
                title: 'Profili Düzenle',
                subtitle: 'Ad, kullanıcı adı ve biyografi',
                icon: Icons.edit_outlined,
                onTap: onEditProfile,
              ),
            ],
            _Section.privacy => [
              _SettingsRow(
                title: 'İzinler',
                subtitle: 'Cihaz erişimlerini kontrol et',
                icon: _Section.permissions.icon,
                onTap: () => _openSection(context, _Section.permissions),
              ),
              _SettingsRow(
                title: 'Engellenenler',
                subtitle: 'Engellenen hesapları yönet',
                icon: _Section.blocked.icon,
                onTap: () => _openSection(context, _Section.blocked),
              ),
            ],
            _Section.blocked => const [
              _SettingsMessage(
                icon: Icons.block_outlined,
                text: 'Engellenen hesapları yönetme henüz kullanılamıyor.',
              ),
            ],
            _Section.permissions => [
              _PermissionSettings(locationService: locationService),
            ],
            _Section.membership => const [
              _SettingsMessage(
                icon: Icons.star_outline,
                text: 'Plus üyelik seçenekleri henüz kullanılamıyor.',
              ),
            ],
            _Section.support => [
              _HelpQuestion(
                question: 'Check-in yapmak için ne kadar yakın olmalıyım?',
                answer:
                    'Konum izni açıkken mekâna en fazla '
                    '${MomntLocationRules.checkInProximityMeters.round()} metre '
                    'uzakta olmalısın.',
              ),
              _HelpQuestion(
                question: 'Check-in nasıl sona erer?',
                answer:
                    'Check-in’i kendin bitirebilirsin. Süre dolunca ya da '
                    'mekândan ${(MomntLocationRules.autoExitDistanceMeters / 1000).round()} '
                    'km’den fazla uzaklaştığın doğrulanınca oturum kapanır. '
                    'Bir oturum en fazla '
                    '${MomntLocationRules.sessionTimeout.inHours} saat sürer.',
              ),
              const _HelpQuestion(
                question: 'Konum iznini nereden kontrol edebilirim?',
                answer: 'Ayarlar ekranından İzinler bölümünü aç.',
              ),
            ],
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPage(
      title: 'Ayarlar',
      children: [
        for (final section in _Section.values)
          _SettingsRow(
            title: section.title,
            subtitle: section.subtitle,
            icon: section.icon,
            onTap: () => _openSection(context, section),
          ),
      ],
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsMessage extends StatelessWidget {
  const _SettingsMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(leading: Icon(icon), title: Text(text)),
    );
  }
}

class _PermissionSettings extends StatefulWidget {
  const _PermissionSettings({required this.locationService});

  final LocationService locationService;

  @override
  State<_PermissionSettings> createState() => _PermissionSettingsState();
}

class _PermissionSettingsState extends State<_PermissionSettings> {
  late Future<bool> _locationPermission;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _locationPermission = widget.locationService.hasLocationPermission();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  void _refresh() {
    setState(() {
      _locationPermission = widget.locationService.hasLocationPermission();
    });
  }

  Future<void> _openDeviceSettings() async {
    try {
      if (await Geolocator.openAppSettings()) return;
    } catch (_) {
      // Bazı cihazlar uygulama ayarlarına doğrudan geçişi desteklemez.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cihaz ayarlarından MOMNT’yi açabilirsin.')),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportsDeviceSettings =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          child: FutureBuilder<bool>(
            future: _locationPermission,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState != ConnectionState.done;
              return ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Konum'),
                subtitle: Text(
                  loading
                      ? 'İzin kontrol ediliyor…'
                      : snapshot.hasError
                      ? 'İzin durumu okunamadı.'
                      : snapshot.data == true
                      ? 'Konum izni açık'
                      : 'Konum izni verilmedi',
                ),
                trailing: IconButton(
                  tooltip: 'İzin durumunu yenile',
                  onPressed: loading ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                ),
              );
            },
          ),
        ),
        const _SettingsMessage(
          icon: Icons.camera_alt_outlined,
          text: 'Kamera izni, sohbette fotoğraf çekerken kullanılır.',
        ),
        const _SettingsMessage(
          icon: Icons.mic_none,
          text: 'Mikrofon izni, sohbette ses kaydederken kullanılır.',
        ),
        const SizedBox(height: 16),
        if (supportsDeviceSettings)
          OutlinedButton.icon(
            onPressed: _openDeviceSettings,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Cihaz ayarlarını aç'),
          )
        else
          Text(
            kIsWeb
                ? 'İzinleri tarayıcının adres çubuğundaki site ayarlarından değiştirebilirsin.'
                : 'İzinleri cihazının ayarlarından değiştirebilirsin.',
          ),
      ],
    );
  }
}

class _HelpQuestion extends StatelessWidget {
  const _HelpQuestion({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(question),
      expandedAlignment: Alignment.centerLeft,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [Text(answer)],
    );
  }
}
