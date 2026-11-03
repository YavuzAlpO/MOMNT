/// Karşılıklı takipleşilen kişinin kartta gösterilen profil bilgisi.
class MutualFollowProfile {
  const MutualFollowProfile({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
}
