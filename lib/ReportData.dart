/// event : "1"
/// position : "1"
/// itemType : "1"
/// itemId : "1"
/// itemName : "1"
/// itemMark1 : "1"
/// itemMark2 : "1"

class ReportData {
  ReportData(
      String? event,
      String? position,
      String? itemType,
      String? itemId,
      String? itemName,
      String? itemMark1,
      String? itemMark2){
    _event = event;
    _position = position;
    _itemType = itemType;
    _itemId = itemId;
    _itemName = itemName;
    _itemMark1 = itemMark1;
    _itemMark2 = itemMark2;
}

  ReportData.fromJson(dynamic json) {
    _event = json['event'];
    _position = json['position'];
    _itemType = json['itemType'];
    _itemId = json['itemId'];
    _itemName = json['itemName'];
    _itemMark1 = json['itemMark1'];
    _itemMark2 = json['itemMark2'];
  }
  String? _event;
  String? _position;
  String? _itemType;
  String? _itemId;
  String? _itemName;
  String? _itemMark1;
  String? _itemMark2;

  String? get event => _event;
  String? get position => _position;
  String? get itemType => _itemType;
  String? get itemId => _itemId;
  String? get itemName => _itemName;
  String? get itemMark1 => _itemMark1;
  String? get itemMark2 => _itemMark2;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['event'] = _event;
    map['position'] = _position;
    map['itemType'] = _itemType;
    map['itemId'] = _itemId;
    map['itemName'] = _itemName;
    map['itemMark1'] = _itemMark1;
    map['itemMark2'] = _itemMark2;
    return map;
  }

}