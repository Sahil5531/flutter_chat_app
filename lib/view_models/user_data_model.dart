class UserDataModel {
  late String fullname;
  late String userId;
  late String phoneNumber;
  late String address;
  late int isActive;
  late String userImageUrl;
  late String createdAt;

  UserDataModel parseJsonData(dynamic json) {
    UserDataModel model = UserDataModel();
    model.userId = json['user_id'] ?? '';
    model.phoneNumber = json['phone_number'] ?? '';
    model.fullname = json['full_name'] ?? '';
    model.address = json['address'] ?? '';
    model.isActive = json['isActive'] ?? 0;
    model.userImageUrl = json['userImageUrl'] ?? '';
    model.createdAt = json['created_at'] ?? '';
    return model;
  }

  List<UserDataModel> parseJsonArray(List<dynamic> data) {
    List<UserDataModel> array = [];
    for (var json in data) {
      UserDataModel model = UserDataModel();
      model.userId = json['user_id'];
      model.phoneNumber = json['phone_number'];
      model.fullname = json['full_name'];
      model.address = json['address'];
      model.isActive = json['isActive'];
      model.userImageUrl = json['userImageUrl'];
      model.createdAt = json['created_at'];
      array.add(model);
    }
    return array;
  }
}
