class User{
  final int id;
  final String? profilePath;
  final String name;
  final String email;
  final DateTime? createAt;

  User({required this.id, this.profilePath, required this.name, required this.email, this.createAt});
  factory User.fromJson(Map<String, dynamic> json){
    return User(
      id: json['id'],
      profilePath: json['profile'],
      name: json['name'],
      email: json['email'],
      createAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null
    );
  }
}