import 'package:cloud_firestore/cloud_firestore.dart';

enum OrgStatus { active, trial, suspended }
enum DeviceStatus { online, idle, syncing, offline }
enum CallType { incoming, outgoing, missed, rejected }

class AdminOrganization {
  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String email;
  final String connectCode;
  final String plan;
  final int employeeLimit;
  final int activeEmployeesCount;
  final int totalCallsSynced;
  OrgStatus status;
  final DateTime renewalDate;
  final DateTime createdAt;

  AdminOrganization({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.connectCode,
    required this.plan,
    required this.employeeLimit,
    required this.activeEmployeesCount,
    required this.totalCallsSynced,
    required this.status,
    required this.renewalDate,
    required this.createdAt,
  });

  factory AdminOrganization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is int) {
      created = DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int);
    }

    final rawStatus = (data['status'] ?? 'active').toString().toLowerCase();
    OrgStatus orgStatus = OrgStatus.active;
    if (rawStatus == 'suspended') {
      orgStatus = OrgStatus.suspended;
    } else if (rawStatus == 'trial' || rawStatus == 'pending') {
      orgStatus = OrgStatus.trial;
    }

    final empLimit = data['employeeLimit'] is int
        ? data['employeeLimit'] as int
        : int.tryParse(data['employeeLimit']?.toString() ?? '5') ?? 5;

    final calls = data['totalCallsSynced'] is int
        ? data['totalCallsSynced'] as int
        : int.tryParse(data['totalCallsSynced']?.toString() ?? '0') ?? 0;

    final activeEmp = data['activeEmployeesCount'] is int
        ? data['activeEmployeesCount'] as int
        : int.tryParse(data['activeEmployeesCount']?.toString() ?? '0') ?? 0;

    final name = (data['companyName'] ?? data['name'] ?? 'Organization').toString();
    final owner = (data['name'] ?? data['ownerName'] ?? 'Administrator').toString();
    final phone = (data['phone'] ?? '').toString();
    final email = (data['email'] ?? '${owner.toLowerCase().replaceAll(RegExp(r'\s+'), '')}@taksecall.in').toString();
    final code = (data['connectCode'] ?? doc.id).toString();
    final plan = (data['plan'] ?? data['teamSize'] ?? 'Starter Plan').toString();

    return AdminOrganization(
      id: doc.id,
      name: name,
      ownerName: owner,
      phone: phone,
      email: email,
      connectCode: code,
      plan: plan,
      employeeLimit: empLimit,
      activeEmployeesCount: activeEmp,
      totalCallsSynced: calls,
      status: orgStatus,
      renewalDate: created.add(const Duration(days: 30)),
      createdAt: created,
    );
  }

  AdminOrganization copyWith({
    String? name,
    String? ownerName,
    String? phone,
    String? email,
    String? plan,
    int? employeeLimit,
    int? activeEmployeesCount,
    int? totalCallsSynced,
    OrgStatus? status,
  }) {
    return AdminOrganization(
      id: id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      connectCode: connectCode,
      plan: plan ?? this.plan,
      employeeLimit: employeeLimit ?? this.employeeLimit,
      activeEmployeesCount: activeEmployeesCount ?? this.activeEmployeesCount,
      totalCallsSynced: totalCallsSynced ?? this.totalCallsSynced,
      status: status ?? this.status,
      renewalDate: renewalDate,
      createdAt: createdAt,
    );
  }
}

class AdminDevice {
  final String id;
  final String connectCode;
  final String agentName;
  final String organizationName;
  final String phone;
  final String deviceModel;
  final String appVersion;
  final DeviceStatus status;
  final DateTime lastSyncAt;
  final int totalCalls;
  final String simSlot;

  AdminDevice({
    required this.id,
    this.connectCode = '',
    required this.agentName,
    required this.organizationName,
    required this.phone,
    required this.deviceModel,
    required this.appVersion,
    required this.status,
    required this.lastSyncAt,
    required this.totalCalls,
    required this.simSlot,
  });

  factory AdminDevice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime lastSync = DateTime.now();
    if (data['lastSyncAt'] is Timestamp) {
      lastSync = (data['lastSyncAt'] as Timestamp).toDate();
    } else if (data['lastSyncAt'] is int) {
      lastSync = DateTime.fromMillisecondsSinceEpoch(data['lastSyncAt'] as int);
    }

    final rawStatus = (data['status'] ?? 'online').toString().toLowerCase();
    DeviceStatus devStatus = DeviceStatus.online;
    if (rawStatus == 'syncing') {
      devStatus = DeviceStatus.syncing;
    } else if (rawStatus == 'idle' || rawStatus == 'pending') {
      devStatus = DeviceStatus.idle;
    } else if (rawStatus == 'offline') {
      devStatus = DeviceStatus.offline;
    }

    final totalCalls = data['totalCallsCount'] is int
        ? data['totalCallsCount'] as int
        : (data['totalCalls'] is int
            ? data['totalCalls'] as int
            : int.tryParse(data['totalCallsCount']?.toString() ?? data['totalCalls']?.toString() ?? '0') ?? 0);

    return AdminDevice(
      id: doc.id,
      connectCode: (data['connectCode'] ?? doc.id).toString(),
      agentName: (data['userName'] ?? data['name'] ?? data['agentName'] ?? 'Agent').toString(),
      organizationName: (data['companyName'] ?? 'Takse Organization').toString(),
      phone: (data['userPhone'] ?? data['phone'] ?? '').toString(),
      deviceModel: (data['deviceModel'] ?? 'Android Device').toString(),
      appVersion: (data['appVersion'] ?? 'v2.17.2').toString(),
      status: devStatus,
      lastSyncAt: lastSync,
      totalCalls: totalCalls,
      simSlot: (data['simSlot'] ?? 'SIM 1').toString(),
    );
  }
}

class AdminCallLog {
  final String id;
  final String connectCode;
  final String orgName;
  final String agentName;
  final String agentPhone;
  final String clientName;
  final String clientNumber;
  final CallType type;
  final int durationSeconds;
  final DateTime timestamp;
  final String simSlot;
  final bool hasRecording;

  AdminCallLog({
    required this.id,
    this.connectCode = '',
    required this.orgName,
    required this.agentName,
    required this.agentPhone,
    required this.clientName,
    required this.clientNumber,
    required this.type,
    required this.durationSeconds,
    required this.timestamp,
    required this.simSlot,
    required this.hasRecording,
  });

  factory AdminCallLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime ts = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      ts = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
    } else if (data['timestamp'] != null) {
      final parsed = int.tryParse(data['timestamp'].toString());
      if (parsed != null) ts = DateTime.fromMillisecondsSinceEpoch(parsed);
    }

    final rawType = (data['type'] ?? 'incoming').toString().toLowerCase();
    CallType cType = CallType.incoming;
    if (rawType.contains('out')) {
      cType = CallType.outgoing;
    } else if (rawType.contains('miss')) {
      cType = CallType.missed;
    } else if (rawType.contains('reject')) {
      cType = CallType.rejected;
    }

    final duration = data['duration'] is int
        ? data['duration'] as int
        : (data['durationSeconds'] is int
            ? data['durationSeconds'] as int
            : int.tryParse(data['duration']?.toString() ?? '0') ?? 0);

    final hasRec = data['recordingUrl'] != null ||
        data['hasRecording'] == true ||
        (data['recordingPath'] != null && data['recordingPath'].toString().isNotEmpty);

    return AdminCallLog(
      id: doc.id,
      connectCode: (data['connectCode'] ?? '').toString(),
      orgName: (data['companyName'] ?? 'Takse Organization').toString(),
      agentName: (data['employeeName'] ?? data['agentName'] ?? 'Agent').toString(),
      agentPhone: (data['employeePhone'] ?? data['agentPhone'] ?? '').toString(),
      clientName: (data['name'] ?? data['clientName'] ?? data['number'] ?? 'Customer').toString(),
      clientNumber: (data['number'] ?? data['clientNumber'] ?? '').toString(),
      type: cType,
      durationSeconds: duration,
      timestamp: ts,
      simSlot: (data['simSlot'] ?? 'SIM 1').toString(),
      hasRecording: hasRec,
    );
  }
}

class AdminPlanTier {
  final String id;
  final String name;
  final int monthlyPrice;
  final int yearlyPrice;
  final int maxAgents;
  final String description;
  final int activeSubscribers;
  final bool isPopular;
  final List<String> features;

  AdminPlanTier({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxAgents,
    required this.description,
    required this.activeSubscribers,
    required this.isPopular,
    required this.features,
  });
}

class AdminLead {
  final String id;
  final String name;
  final String email;
  final String mobileNumber;
  final String regStatus;
  final String regFee;
  final String kycUpdated;
  final String status;
  final int referrals;
  final int orders;
  final String userType;
  final String state;
  final String district;
  final String block;
  final String village;
  final String pincode;
  final String shopName;
  final DateTime createdAt;
  final String assignedOrgId;
  final String assignedOrgName;
  final String assignedToUserId;
  final String assignedToUserName;
  final DateTime? assignedAt;
  final String assignmentStatus; // 'unassigned', 'assigned'
  final String source;

  bool get isAssigned => assignmentStatus.toLowerCase() == 'assigned' || assignedToUserId.isNotEmpty || assignedOrgId.isNotEmpty;

  bool get isWebhookSource {
    final s = source.toLowerCase();
    return s.contains('webhook') || s.contains('api') || s == 'takse_api';
  }

  bool get isSheetSource {
    final s = source.toLowerCase();
    return s.contains('sheet') || s.contains('excel') || s.contains('csv');
  }

  String get sourceDisplayName {
    if (isSheetSource) return 'Excel / Sheet';
    if (isWebhookSource) return 'Webhook / API';
    return source.isNotEmpty ? source : 'Webhook / API';
  }

  AdminLead({
    required this.id,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.regStatus,
    required this.regFee,
    required this.kycUpdated,
    required this.status,
    required this.referrals,
    required this.orders,
    required this.userType,
    required this.state,
    required this.district,
    required this.block,
    required this.village,
    required this.pincode,
    required this.shopName,
    required this.createdAt,
    this.assignedOrgId = '',
    this.assignedOrgName = '',
    this.assignedToUserId = '',
    this.assignedToUserName = '',
    this.assignedAt,
    this.assignmentStatus = 'unassigned',
    this.source = 'takse_api',
  });

  factory AdminLead.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['created_at'] is Timestamp) {
      created = (data['created_at'] as Timestamp).toDate();
    }

    DateTime? assignedDate;
    if (data['assignedAt'] is Timestamp) {
      assignedDate = (data['assignedAt'] as Timestamp).toDate();
    }

    final refCount = data['referrals'] is int
        ? data['referrals'] as int
        : int.tryParse(data['referrals']?.toString() ?? '0') ?? 0;

    final ordCount = data['orders'] is int
        ? data['orders'] as int
        : int.tryParse(data['orders']?.toString() ?? '0') ?? 0;

    final rawAssignedStatus = (data['assignmentStatus'] ?? '').toString();
    final orgId = (data['assignedOrgId'] ?? data['orgId'] ?? '').toString();
    final orgName = (data['assignedOrgName'] ?? data['orgName'] ?? '').toString();
    final userId = (data['assignedToUserId'] ?? data['userId'] ?? '').toString();
    final userName = (data['assignedToUserName'] ?? data['userName'] ?? '').toString();

    final statusDerived = rawAssignedStatus.isNotEmpty
        ? rawAssignedStatus
        : (userId.isNotEmpty || orgId.isNotEmpty ? 'assigned' : 'unassigned');

    return AdminLead(
      id: doc.id,
      name: (data['name'] ?? '').toString().trim(),
      email: (data['email'] ?? '').toString().trim(),
      mobileNumber: (data['mobile_number'] ?? data['mobileNumber'] ?? data['phone'] ?? '').toString().trim(),
      regStatus: (data['Reg Status'] ?? data['regStatus'] ?? data['reg_status'] ?? 'Completed').toString(),
      regFee: (data['Reg Fee'] ?? data['regFee'] ?? data['reg_fee'] ?? '0').toString(),
      kycUpdated: (data['KYC Updated'] ?? data['kycUpdated'] ?? data['kyc_status'] ?? 'pending').toString(),
      status: (data['Status'] ?? data['status'] ?? 'TRUE').toString(),
      referrals: refCount,
      orders: ordCount,
      userType: (data['User Type'] ?? data['userType'] ?? data['user_type'] ?? 'TSP').toString(),
      state: (data['State'] ?? data['state'] ?? '').toString().trim(),
      district: (data['District'] ?? data['district'] ?? '').toString().trim(),
      block: (data['Block'] ?? data['block'] ?? '').toString().trim(),
      village: (data['Village'] ?? data['village'] ?? '').toString().trim(),
      pincode: (data['Pincode'] ?? data['pincode'] ?? '').toString().trim(),
      shopName: (data['Shop Name'] ?? data['shopName'] ?? data['shop_name'] ?? '').toString().trim(),
      createdAt: created,
      assignedOrgId: orgId,
      assignedOrgName: orgName,
      assignedToUserId: userId,
      assignedToUserName: userName,
      assignedAt: assignedDate,
      assignmentStatus: statusDerived,
      source: (data['source'] ?? data['Source'] ?? 'takse_api').toString(),
    );
  }

  factory AdminLead.fromMap(Map<String, dynamic> map, {String? id}) {
    final refCount = map['referrals'] is int
        ? map['referrals'] as int
        : int.tryParse(map['referrals']?.toString() ?? '0') ?? 0;

    final ordCount = map['orders'] is int
        ? map['orders'] as int
        : int.tryParse(map['orders']?.toString() ?? '0') ?? 0;

    final phone = (map['mobile_number'] ?? map['mobileNumber'] ?? map['phone'] ?? '').toString().trim();

    return AdminLead(
      id: id ?? phone,
      name: (map['name'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim(),
      mobileNumber: phone,
      regStatus: (map['Reg Status'] ?? map['regStatus'] ?? map['reg_status'] ?? 'Completed').toString(),
      regFee: (map['Reg Fee'] ?? map['regFee'] ?? map['reg_fee'] ?? '0').toString(),
      kycUpdated: (map['KYC Updated'] ?? map['kycUpdated'] ?? dataFallback(map, 'kyc_status', 'pending')).toString(),
      status: (map['Status'] ?? map['status'] ?? 'TRUE').toString(),
      referrals: refCount,
      orders: ordCount,
      userType: (map['User Type'] ?? map['userType'] ?? map['user_type'] ?? 'TSP').toString(),
      state: (map['State'] ?? map['state'] ?? '').toString().trim(),
      district: (map['District'] ?? map['district'] ?? '').toString().trim(),
      block: (map['Block'] ?? map['block'] ?? '').toString().trim(),
      village: (map['Village'] ?? map['village'] ?? '').toString().trim(),
      pincode: (map['Pincode'] ?? map['pincode'] ?? '').toString().trim(),
      shopName: (map['Shop Name'] ?? map['shopName'] ?? map['shop_name'] ?? '').toString().trim(),
      createdAt: DateTime.now(),
      assignedOrgId: (map['assignedOrgId'] ?? '').toString(),
      assignedOrgName: (map['assignedOrgName'] ?? '').toString(),
      assignedToUserId: (map['assignedToUserId'] ?? '').toString(),
      assignedToUserName: (map['assignedToUserName'] ?? '').toString(),
      assignedAt: map['assignedAt'] is DateTime ? map['assignedAt'] as DateTime : null,
      assignmentStatus: (map['assignmentStatus'] ?? 'unassigned').toString(),
      source: (map['source'] ?? map['Source'] ?? 'takse_api').toString(),
    );
  }

  AdminLead copyWith({
    String? assignedOrgId,
    String? assignedOrgName,
    String? assignedToUserId,
    String? assignedToUserName,
    DateTime? assignedAt,
    String? assignmentStatus,
    String? source,
  }) {
    return AdminLead(
      id: id,
      name: name,
      email: email,
      mobileNumber: mobileNumber,
      regStatus: regStatus,
      regFee: regFee,
      kycUpdated: kycUpdated,
      status: status,
      referrals: referrals,
      orders: orders,
      userType: userType,
      state: state,
      district: district,
      block: block,
      village: village,
      pincode: pincode,
      shopName: shopName,
      createdAt: createdAt,
      assignedOrgId: assignedOrgId ?? this.assignedOrgId,
      assignedOrgName: assignedOrgName ?? this.assignedOrgName,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToUserName: assignedToUserName ?? this.assignedToUserName,
      assignedAt: assignedAt ?? this.assignedAt,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      source: source ?? this.source,
    );
  }

  static String dataFallback(Map<String, dynamic> map, String key, String fallback) {
    return (map[key] ?? fallback).toString();
  }
}

