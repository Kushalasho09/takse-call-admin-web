import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../models/admin_data_models.dart';

class AdminStateService extends ChangeNotifier {
  static final AdminStateService instance = AdminStateService._internal();

  AdminStateService._internal() {
    _initPlans();
  }

  // Theme Mode State
  // Default is true (Dark Mode - mobile app palette)
  // When false: Light Mode - customer web palette
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setThemeMode(bool dark) {
    _isDarkMode = dark;
    notifyListeners();
  }

  // Auth State
  bool _isAuthenticated = false;
  String _adminEmail = 'master.admin@taksecall.com';
  String _adminName = 'Super Admin';
  String _selectedSection = 'overview'; // 'overview', 'organizations', 'devices', 'plans', 'calls', 'settings'

  bool get isAuthenticated => _isAuthenticated;
  String get adminEmail => _adminEmail;
  String get adminName => _adminName;
  String get selectedSection => _selectedSection;

  void setSection(String section) {
    _selectedSection = section;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) return false;

    // Attempt live Firebase Authentication
    try {
      if (Firebase.apps.isNotEmpty) {
        final auth = FirebaseAuth.instance;
        final cred = await auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPass,
        );

        if (cred.user != null) {
          _isAuthenticated = true;
          _adminEmail = cleanEmail;
          _adminName = cred.user?.displayName ?? 'Master Super Admin';

          initFirebase();
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Firebase Auth attempt notice: $e');
      return false;
    }

    return false;
  }

  void logout() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}
    _isAuthenticated = false;
    notifyListeners();
  }

  List<AdminOrganization> _organizations = [];
  List<AdminDevice> _devices = [];
  List<AdminCallLog> _callLogs = [];
  List<AdminPlanTier> _plans = [];
  List<AdminLead> _leads = [];

  List<AdminOrganization> get organizations => _organizations;
  List<AdminDevice> get devices => _devices;
  List<AdminCallLog> get callLogs => _callLogs;
  List<AdminPlanTier> get plans => _plans;
  List<AdminLead> get leads => _leads;

  // Firebase Real-time Connection State (Lazy & Safe)
  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore? get firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return _firestoreInstance ??= FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore instance check notice: $e');
    }
    return null;
  }

  StreamSubscription? _usersSub;
  StreamSubscription? _devicesSub;
  StreamSubscription? _callLogsSub;
  StreamSubscription? _leadsSub;
  bool _isLiveConnected = false;
  bool get isLiveConnected => _isLiveConnected;
  int _firestoreSyncCount = 0;
  int get firestoreSyncCount => _firestoreSyncCount;

  // Dynamic Overview KPIs & Metrics
  int get totalOrganizations => _organizations.length;
  int get activeOrganizations => _organizations.where((o) => o.status == OrgStatus.active).length;
  int get newOrgsThisWeek {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return _organizations.where((o) => o.createdAt.isAfter(sevenDaysAgo)).length;
  }

  int get totalAgents => _devices.length;
  int get onlineAgentsNow => _devices.where((d) => d.status == DeviceStatus.online || d.status == DeviceStatus.syncing).length;
  int get newDevicesThisWeek {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return _devices.where((d) => d.lastSyncAt.isAfter(sevenDaysAgo)).length;
  }

  int get totalCallsToday {
    final now = DateTime.now();
    return _callLogs.where((c) {
      return c.timestamp.year == now.year && c.timestamp.month == now.month && c.timestamp.day == now.day;
    }).length;
  }

  int get totalCallsAllTime {
    if (_callLogs.isNotEmpty) return _callLogs.length;
    int sum = 0;
    for (final org in _organizations) {
      sum += org.totalCallsSynced;
    }
    return sum;
  }

  double get systemUptime => 99.98;

  List<AdminOrganization> get topOrganizations {
    final list = List<AdminOrganization>.from(_organizations);
    list.sort((a, b) {
      final compCalls = b.totalCallsSynced.compareTo(a.totalCallsSynced);
      if (compCalls != 0) return compCalls;
      return b.activeEmployeesCount.compareTo(a.activeEmployeesCount);
    });
    return list;
  }

  /// Called after Firebase.initializeApp() finishes in main()
  void initFirebase() {
    _checkPersistedAuth();
    _initFirestoreListeners();
    refreshFromFirestore();
  }

  void _checkPersistedAuth() {
    try {
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _isAuthenticated = true;
          _adminEmail = user.email ?? 'master.admin@taksecall.com';
          _adminName = user.displayName ?? 'Master Super Admin';
        }
      }
    } catch (e) {
      debugPrint('Persisted auth check notice: $e');
    }
  }

  void _initFirestoreListeners() {
    final fs = firestore;
    if (fs == null) {
      debugPrint('Firestore instance not available yet.');
      return;
    }

    _usersSub?.cancel();
    _devicesSub?.cancel();
    _callLogsSub?.cancel();
    _leadsSub?.cancel();

    try {
      // 1. Listen to users collection (Client Organizations)
      _usersSub = fs.collection('users').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final liveOrgs = snapshot.docs
                .where((doc) {
                  // Exclude root master admin doc or any doc with master root IDs
                  if (doc.id == 'admin_master' || doc.id == 'master_root' || doc.id.startsWith('admin_')) return false;
                  final data = doc.data();
                  final hasCompany = (data['companyName'] ?? '').toString().trim().isNotEmpty;
                  final hasCode = (data['connectCode'] ?? '').toString().trim().isNotEmpty;
                  final hasName = (data['name'] ?? '').toString().trim().isNotEmpty;
                  return hasCompany || hasCode || hasName || doc.id.startsWith('usr_');
                })
                .map((doc) => AdminOrganization.fromFirestore(doc))
                .toList();

            _organizations = liveOrgs;
            _recalculateOrgMetrics();
            _isLiveConnected = true;
            _firestoreSyncCount++;
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore users stream notice: $err');
        },
      );

      // 2. Listen to devices collection (Telecaller phone devices)
      _devicesSub = fs.collection('devices').snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final liveDevs = snapshot.docs.map((doc) => AdminDevice.fromFirestore(doc)).toList();
            _devices = liveDevs;
            _recalculateOrgMetrics();
            _isLiveConnected = true;
            _firestoreSyncCount++;
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore devices stream notice: $err');
        },
      );

      // 3. Listen to call_logs collection (limited to 150 latest calls to prevent web memory spikes)
      _callLogsSub = fs
          .collection('call_logs')
          .limit(150)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final liveLogs = snapshot.docs.map((doc) => AdminCallLog.fromFirestore(doc)).toList();
            liveLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            _callLogs = liveLogs;
            _recalculateOrgMetrics();
            _isLiveConnected = true;
            _firestoreSyncCount++;
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore call_logs stream notice: $err');
        },
      );

      // 4. Listen to leads collection (Takse Organization Leads Webhook / NodeJS integration)
      _leadsSub = fs
          .collection('leads')
          .limit(300)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final liveLeads = snapshot.docs.map((doc) => AdminLead.fromFirestore(doc)).toList();
            _leads = liveLeads;
            _isLiveConnected = true;
            _firestoreSyncCount++;
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore leads stream notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore init error: $e');
    }
  }

  void _recalculateOrgMetrics() {
    if (_organizations.isEmpty) return;

    final updatedOrgs = <AdminOrganization>[];

    for (final org in _organizations) {
      final normOrgCode = _normalizeKey(org.connectCode);
      final normOrgName = org.name.trim().toLowerCase();
      final normOrgPhone = org.phone.replaceAll(RegExp(r'[^0-9]'), '');

      // 1. Match devices
      final matchingDevices = _devices.where((d) {
        final normDevCode = _normalizeKey(d.connectCode);
        final normDevOrg = d.organizationName.trim().toLowerCase();
        final normDevPhone = d.phone.replaceAll(RegExp(r'[^0-9]'), '');

        final codeMatch = normOrgCode.isNotEmpty && normDevCode.isNotEmpty && (normOrgCode == normDevCode || normDevCode.contains(normOrgCode) || normOrgCode.contains(normDevCode));
        final nameMatch = normOrgName.isNotEmpty && (normDevOrg == normOrgName || normDevOrg.contains(normOrgName) || normOrgName.contains(normDevOrg));
        final phoneMatch = normOrgPhone.length >= 8 && normDevPhone.length >= 8 && (normOrgPhone.endsWith(normDevPhone) || normDevPhone.endsWith(normOrgPhone));

        return codeMatch || nameMatch || phoneMatch;
      }).toList();

      // 2. Match call logs
      final matchingLogs = _callLogs.where((l) {
        final normLogCode = _normalizeKey(l.connectCode);
        final normLogOrg = l.orgName.trim().toLowerCase();

        final codeMatch = normOrgCode.isNotEmpty && normLogCode.isNotEmpty && (normOrgCode == normLogCode || normLogCode.contains(normOrgCode) || normLogCode.contains(normLogCode));
        final nameMatch = normOrgName.isNotEmpty && (normLogOrg == normOrgName || normLogOrg.contains(normOrgName) || normLogOrg.contains(normLogOrg));

        return codeMatch || nameMatch;
      }).toList();

      // 3. Compute total calls: sum of device counts or total matched logs
      int callSumFromDevices = 0;
      for (final dev in matchingDevices) {
        callSumFromDevices += dev.totalCalls;
      }
      final computedCalls = max(callSumFromDevices, matchingLogs.length);

      updatedOrgs.add(org.copyWith(
        activeEmployeesCount: matchingDevices.length,
        totalCallsSynced: max(computedCalls, org.totalCallsSynced),
      ));
    }

    _organizations = updatedOrgs;
  }

  String _normalizeKey(String raw) {
    return raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '').trim();
  }

  Future<void> refreshFromFirestore() async {
    final fs = firestore;
    if (fs == null) return;

    try {
      final userSnap = await fs.collection('users').get();
      if (userSnap.docs.isNotEmpty) {
        final liveOrgs = userSnap.docs
            .where((doc) {
              if (doc.id == 'admin_master' || doc.id == 'master_root' || doc.id.startsWith('admin_')) return false;
              final data = doc.data();
              final hasCompany = (data['companyName'] ?? '').toString().trim().isNotEmpty;
              final hasCode = (data['connectCode'] ?? '').toString().trim().isNotEmpty;
              final hasName = (data['name'] ?? '').toString().trim().isNotEmpty;
              return hasCompany || hasCode || hasName || doc.id.startsWith('usr_');
            })
            .map((doc) => AdminOrganization.fromFirestore(doc))
            .toList();

        _organizations = liveOrgs;
      }

      final devSnap = await fs.collection('devices').get();
      if (devSnap.docs.isNotEmpty) {
        _devices = devSnap.docs.map((doc) => AdminDevice.fromFirestore(doc)).toList();
      }

      final callSnap = await fs.collection('call_logs').limit(150).get();
      if (callSnap.docs.isNotEmpty) {
        final liveLogs = callSnap.docs.map((doc) => AdminCallLog.fromFirestore(doc)).toList();
        liveLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _callLogs = liveLogs;
      }

      final leadSnap = await fs.collection('leads').limit(300).get();
      if (leadSnap.docs.isNotEmpty) {
        _leads = leadSnap.docs.map((doc) => AdminLead.fromFirestore(doc)).toList();
      }

      _recalculateOrgMetrics();
      _isLiveConnected = true;
      _firestoreSyncCount++;
      notifyListeners();
    } catch (e) {
      debugPrint('Error manually refreshing from Firestore: $e');
    }
  }

  /// Creates or updates a Super Admin record in Firestore (collection: 'users')
  Future<bool> createSuperAdminInFirestore({
    String email = 'master.admin@taksecall.com',
    String phone = '+91 99999 99999',
    String name = 'Super Admin',
  }) async {
    final fs = firestore;
    if (fs == null) return false;

    try {
      final now = FieldValue.serverTimestamp();
      final userRef = fs.collection('users').doc('admin_master');

      await userRef.set({
        'userId': 'admin_master',
        'name': name,
        'email': email,
        'phone': phone,
        'companyName': 'Takse Call HQ',
        'connectCode': 'TAK-0001-0001',
        'employeeLimit': 100,
        'plan': 'Enterprise VIP',
        'role': 'Super Admin',
        'status': 'active',
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      debugPrint('Super Admin document successfully created in Firestore users/admin_master');
      return true;
    } catch (e) {
      debugPrint('Error creating Super Admin in Firestore: $e');
      return false;
    }
  }

  void _initPlans() {
    _plans = [
      AdminPlanTier(
        id: 'plan_starter',
        name: 'Starter Plan',
        monthlyPrice: 999,
        yearlyPrice: 9990,
        maxAgents: 5,
        description: 'Ideal for small sales teams, local clinics, and boutique brokerages.',
        activeSubscribers: 8,
        isPopular: false,
        features: [
          'Up to 5 Telecallers',
          'Instant Device Connect Codes',
          'Real-time SIM Call Sync',
          'Standard Call Analytics & Reports',
          'CSV / Excel Export',
        ],
      ),
      AdminPlanTier(
        id: 'plan_growth',
        name: 'Growth Plan',
        monthlyPrice: 2499,
        yearlyPrice: 24990,
        maxAgents: 15,
        description: 'For growing sales agencies and distributed field teams.',
        activeSubscribers: 12,
        isPopular: true,
        features: [
          'Up to 15 Telecallers',
          'Everything in Starter',
          'Google Sheets Live Connector',
          'Auto Audio Call Recording Cloud Backup',
          'Lead Auto-Tagging & WhatsApp Templates',
          'Priority Email & Chat Support',
        ],
      ),
      AdminPlanTier(
        id: 'plan_scale',
        name: 'Scale Pro',
        monthlyPrice: 4999,
        yearlyPrice: 49990,
        maxAgents: 35,
        description: 'High-volume outbound calling teams and BPO operations.',
        activeSubscribers: 6,
        isPopular: false,
        features: [
          'Up to 35 Telecallers',
          'Everything in Growth',
          'Advanced Team Hierarchy & Branch Management',
          'Call Sentiment & Duration Heatmaps',
          'API Webhook Integration',
          'Dedicated Account Manager',
        ],
      ),
      AdminPlanTier(
        id: 'plan_enterprise',
        name: 'Enterprise VIP',
        monthlyPrice: 8999,
        yearlyPrice: 89990,
        maxAgents: 100,
        description: 'Custom setups for nationwide corporate operations.',
        activeSubscribers: 2,
        isPopular: false,
        features: [
          'Up to 100 Telecallers (Expandable)',
          'Custom SLA & 99.99% Uptime Guarantee',
          'Custom Cloud Firestore Cluster Isolation',
          'White-label Branding & Custom Domain',
          '24/7 Phone & Zoom Emergency Support',
        ],
      ),
    ];
  }

  // Mutations with Firestore live sync
  Future<void> addOrganization({
    required String name,
    required String ownerName,
    required String phone,
    required String email,
    required String plan,
    required int employeeLimit,
  }) async {
    final clean = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final prefix = clean.length >= 3 ? clean.substring(0, 3) : 'ORG';
    final random = Random();
    final code = '$prefix-${1000 + random.nextInt(9000)}-${1000 + random.nextInt(9000)}';
    final cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final docId = cleanDigits.isNotEmpty ? 'usr_$cleanDigits' : 'org_${DateTime.now().millisecondsSinceEpoch}';

    final newOrg = AdminOrganization(
      id: docId,
      name: name.trim(),
      ownerName: ownerName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      connectCode: code,
      plan: plan,
      employeeLimit: employeeLimit,
      activeEmployeesCount: 0,
      totalCallsSynced: 0,
      status: OrgStatus.active,
      renewalDate: DateTime.now().add(const Duration(days: 30)),
      createdAt: DateTime.now(),
    );

    _organizations.insert(0, newOrg);
    notifyListeners();

    // Write to Firebase Firestore if connected
    final fs = firestore;
    if (fs != null) {
      try {
        final now = FieldValue.serverTimestamp();
        final batch = fs.batch();

        final userRef = fs.collection('users').doc(docId);
        batch.set(userRef, {
          'userId': docId,
          'name': ownerName.trim(),
          'companyName': name.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'connectCode': code,
          'plan': plan,
          'employeeLimit': employeeLimit,
          'status': 'active',
          'role': 'CLIENT',
          'createdAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));

        final devRef = fs.collection('devices').doc(code);
        batch.set(devRef, {
          'connectCode': code,
          'userId': docId,
          'userName': ownerName.trim(),
          'userPhone': phone.trim(),
          'companyName': name.trim(),
          'status': 'pending',
          'deviceModel': null,
          'lastSyncAt': null,
          'totalCallsCount': 0,
          'createdAt': now,
        }, SetOptions(merge: true));

        await batch.commit();
        debugPrint('Successfully added organization to Firestore: $docId');
      } catch (e) {
        debugPrint('Error writing new organization to Firestore: $e');
      }
    }
  }

  Future<void> updateOrgLimit(String orgId, int newLimit, String newPlan) async {
    final index = _organizations.indexWhere((o) => o.id == orgId);
    if (index != -1) {
      _organizations[index] = _organizations[index].copyWith(
        employeeLimit: newLimit,
        plan: newPlan,
      );
      notifyListeners();

      final fs = firestore;
      if (fs != null) {
        try {
          await fs.collection('users').doc(orgId).set({
            'employeeLimit': newLimit,
            'plan': newPlan,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error updating org limit in Firestore: $e');
        }
      }
    }
  }

  Future<void> toggleOrgStatus(String orgId) async {
    final index = _organizations.indexWhere((o) => o.id == orgId);
    if (index != -1) {
      final current = _organizations[index].status;
      final next = current == OrgStatus.active ? OrgStatus.suspended : OrgStatus.active;
      _organizations[index] = _organizations[index].copyWith(status: next);
      notifyListeners();

      final fs = firestore;
      if (fs != null) {
        try {
          await fs.collection('users').doc(orgId).set({
            'status': next == OrgStatus.active ? 'active' : 'suspended',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error toggling org status in Firestore: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _devicesSub?.cancel();
    _callLogsSub?.cancel();
    _leadsSub?.cancel();
    super.dispose();
  }

  /// Populate sample leads from the user's Google Sheet into Firestore or memory
  Future<void> seedSampleLeadsFromSheet() async {
    final sampleData = [
      {
        'name': 'Debashis satpathy',
        'email': 'debashissatapathy96@gmail.com',
        'mobile_number': '7609975577',
        'Reg Status': 'Completed',
        'Reg Fee': '0',
        'KYC Updated': 'pending',
        'Status': 'TRUE',
        'referrals': 0,
        'orders': 0,
        'User Type': 'TSP',
        'State': 'ODISHA',
        'District': 'Khurda',
        'Block': 'Bhubaneswar',
        'Village': 'Patia',
        'Pincode': '751024',
        'Shop Name': 'Satpathy Telecom',
      },
      {
        'name': 'JM ELECTRONICS',
        'email': 'jmzubeen@gmail.com',
        'mobile_number': '9531044076',
        'Reg Status': 'Completed',
        'Reg Fee': '0',
        'KYC Updated': 'pending',
        'Status': 'TRUE',
        'referrals': 0,
        'orders': 0,
        'User Type': 'TSP',
        'State': 'ASSAM',
        'District': 'Kamrup',
        'Block': 'Guwahati',
        'Village': 'Dispur',
        'Pincode': '781005',
        'Shop Name': 'JM Electronics Hub',
      },
      {
        'name': 'SANTOSH KUMAR',
        'email': 'san2323st@gmail.com',
        'mobile_number': '8252314149',
        'Reg Status': 'Completed',
        'Reg Fee': '0',
        'KYC Updated': 'pending',
        'Status': 'TRUE',
        'referrals': 0,
        'orders': 0,
        'User Type': 'TSP',
        'State': 'BIHAR',
        'District': 'Patna',
        'Block': 'Danapur',
        'Village': 'Khagaul',
        'Pincode': '801105',
        'Shop Name': 'Santosh Mobile Gallery',
      },
      {
        'name': 'Zishan shaikh',
        'email': 'zishan6360@gmail.com',
        'mobile_number': '7208597335',
        'Reg Status': 'Completed',
        'Reg Fee': '0',
        'KYC Updated': 'pending',
        'Status': 'TRUE',
        'referrals': 0,
        'orders': 0,
        'User Type': 'TSP',
        'State': 'MAHARASHTRA',
        'District': 'Mumbai Suburban',
        'Block': 'Kurla',
        'Village': 'Bandra East',
        'Pincode': '400051',
        'Shop Name': 'Shaikh Enterprise',
      },
      {
        'name': 'Sudhanshu kumar',
        'email': 'SUDHANSHUKUM578@GMAIL.COM',
        'mobile_number': '6206759633',
        'Reg Status': 'Completed',
        'Reg Fee': '0',
        'KYC Updated': 'pending',
        'Status': 'TRUE',
        'referrals': 1,
        'orders': 0,
        'User Type': 'TSP',
        'State': 'BIHAR',
        'District': 'Gaya',
        'Block': 'Bodhyaga',
        'Village': 'Gaya Town',
        'Pincode': '823001',
        'Shop Name': 'Sudhanshu Infotech',
      },
      {
        'name': 'Manish Singh',
        'email': 'manishsingh817837@gmail.com',
        'mobile_number': '8178371279',
        'Reg Status': 'Completed',
        'Reg Fee': '0',
        'KYC Updated': 'pending',
        'Status': 'TRUE',
        'referrals': 0,
        'orders': 0,
        'User Type': 'TSP',
        'State': 'UTTAR PRADESH',
        'District': 'Lucknow',
        'Block': 'Chinhat',
        'Village': 'Gomti Nagar',
        'Pincode': '226010',
        'Shop Name': 'Manish Digital Services',
      },
      {
        'name': 'Debojit Debnath',
        'email': 'debojitdebnath763@gmail.com',
        'mobile_number': '7085313004',
        'Reg Status': 'Completed',
        'Reg Fee': '0',
        'KYC Updated': 'pending',
        'Status': 'TRUE',
        'referrals': 3,
        'orders': 0,
        'User Type': 'TSP',
        'State': 'TRIPURA',
        'District': 'West Tripura',
        'Block': 'Jirania',
        'Village': 'East Champamura',
        'Pincode': '799008',
        'Shop Name': 'Debnath Communication',
      },
      {
        'name': 'Kalpesh desai',
        'email': 'kidesai1972@gmail.com',
        'mobile_number': '9904446125',
        'Reg Status': 'Completed',
        'Reg Fee': '0',
        'KYC Updated': 'pending',
        'Status': 'TRUE',
        'referrals': 0,
        'orders': 0,
        'User Type': 'TSP',
        'State': 'GUJARAT',
        'District': 'Ahmedabad',
        'Block': 'Daskroi',
        'Village': 'Navrangpura',
        'Pincode': '380009',
        'Shop Name': 'Desai Care Center',
      },
      {
        'name': 'Dilip yadav',
        'email': 'dilipyadav56012k@gmail.com',
        'mobile_number': '8797844943',
        'Reg Status': 'Completed',
        'Reg Fee': '0',
        'KYC Updated': 'pending',
        'Status': 'TRUE',
        'referrals': 0,
        'orders': 0,
        'User Type': 'TSP',
        'State': 'BIHAR',
        'District': 'Sheohar',
        'Block': 'Sheohar',
        'Village': 'Nayagaon',
        'Pincode': '843329',
        'Shop Name': 'Yadav Store',
      },
    ];

    final fs = firestore;
    if (fs != null) {
      try {
        final batch = fs.batch();
        for (final item in sampleData) {
          final phone = item['mobile_number'] as String;
          final docRef = fs.collection('leads').doc(phone);
          batch.set(docRef, {
            ...item,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'source': 'Google Sheets / Takse Webhook',
          }, SetOptions(merge: true));
        }
        await batch.commit();
        debugPrint('Successfully seeded sample leads to Firestore leads collection!');
      } catch (e) {
        debugPrint('Firestore seed notice: $e');
      }
    }

    _leads = sampleData.map((m) => AdminLead.fromMap(m)).toList();
    notifyListeners();
  }

  // --- Lead Assignment & Distribution to Organizations ---
  int get unassignedLeadsCount => _leads.where((l) => !l.isAssigned).length;
  int get assignedLeadsCount => _leads.where((l) => l.isAssigned).length;
  List<AdminLead> get unassignedLeads => _leads.where((l) => !l.isAssigned).toList();
  List<AdminLead> get assignedLeads => _leads.where((l) => l.isAssigned).toList();

  /// Admin manually assigns leads to an Organization
  Future<bool> assignLeadsToOrganization({
    required List<String> leadIds,
    required String orgId,
    required String orgName,
    required String connectCode,
  }) async {
    if (leadIds.isEmpty) return false;
    final now = DateTime.now();
    final fs = firestore;

    const int batchLimit = 400;
    for (int b = 0; b < leadIds.length; b += batchLimit) {
      final chunk = leadIds.skip(b).take(batchLimit).toList();
      WriteBatch? batch = fs?.batch();

      for (final id in chunk) {
        final updateData = {
          'connectCode': connectCode.isNotEmpty ? connectCode : orgId,
          'assignedOrgId': orgId,
          'assignedOrgName': orgName,
          'assignedAt': FieldValue.serverTimestamp(),
          'assignmentStatus': 'assigned',
          'assignedTo': '',
          'assignedToPhone': '',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (batch != null && fs != null) {
          batch.set(fs.collection('leads').doc(id), updateData, SetOptions(merge: true));
        }

        final idx = _leads.indexWhere((l) => l.id == id || l.mobileNumber == id);
        if (idx != -1) {
          _leads[idx] = _leads[idx].copyWith(
            assignedOrgId: orgId,
            assignedOrgName: orgName,
            assignedToUserId: '',
            assignedToUserName: '',
            assignedAt: now,
            assignmentStatus: 'assigned',
          );
        }
      }

      if (batch != null) {
        try {
          await batch.commit();
        } catch (e) {
          debugPrint('Error assigning leads to org batch: $e');
        }
      }
    }

    notifyListeners();
    return true;
  }

  /// Admin auto-distributes leads equally among selected Organizations using fair round-robin
  Future<int> autoDistributeLeadsToOrganizations({
    required List<String> leadIds,
    required List<AdminOrganization> targetOrgs,
  }) async {
    if (leadIds.isEmpty || targetOrgs.isEmpty) return 0;

    final fs = firestore;
    final now = DateTime.now();
    int count = 0;

    const int batchLimit = 400;
    for (int b = 0; b < leadIds.length; b += batchLimit) {
      final chunk = leadIds.skip(b).take(batchLimit).toList();
      WriteBatch? batch = fs?.batch();

      for (int i = 0; i < chunk.length; i++) {
        final globalIndex = b + i;
        final leadId = chunk[i];
        final org = targetOrgs[globalIndex % targetOrgs.length];

        final updateData = {
          'connectCode': org.connectCode.isNotEmpty ? org.connectCode : org.id,
          'assignedOrgId': org.id,
          'assignedOrgName': org.name,
          'assignedAt': FieldValue.serverTimestamp(),
          'assignmentStatus': 'assigned',
          'assignedTo': '',
          'assignedToPhone': '',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (batch != null && fs != null) {
          batch.set(fs.collection('leads').doc(leadId), updateData, SetOptions(merge: true));
        }

        final idx = _leads.indexWhere((l) => l.id == leadId || l.mobileNumber == leadId);
        if (idx != -1) {
          _leads[idx] = _leads[idx].copyWith(
            assignedOrgId: org.id,
            assignedOrgName: org.name,
            assignedToUserId: '',
            assignedToUserName: '',
            assignedAt: now,
            assignmentStatus: 'assigned',
          );
        }
        count++;
      }

      if (batch != null) {
        try {
          await batch.commit();
        } catch (e) {
          debugPrint('Error committing org distribution batch: $e');
        }
      }
    }

    notifyListeners();
    return count;
  }

  /// Admin distributes custom quotas to specific organizations (e.g., Org A: 10, Org B: 5, Org C: 15)
  Future<int> distributeCustomQuotasToOrganizations(Map<String, int> orgQuotas) async {
    final availableLeads = unassignedLeads;
    if (availableLeads.isEmpty || orgQuotas.isEmpty) return 0;

    final fs = firestore;
    final now = DateTime.now();
    int leadPointer = 0;
    int totalAssigned = 0;

    final List<Map<String, dynamic>> assignments = [];

    for (final entry in orgQuotas.entries) {
      final orgId = entry.key;
      final quota = entry.value;
      if (quota <= 0) continue;

      final org = _organizations.firstWhere(
        (o) => o.id == orgId,
        orElse: () => AdminOrganization(
          id: orgId,
          name: orgId,
          ownerName: '',
          phone: '',
          email: '',
          connectCode: orgId,
          plan: 'Custom',
          employeeLimit: 10,
          activeEmployeesCount: 0,
          totalCallsSynced: 0,
          status: OrgStatus.active,
          renewalDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      for (int i = 0; i < quota && leadPointer < availableLeads.length; i++) {
        final lead = availableLeads[leadPointer++];
        assignments.add({
          'leadId': lead.id,
          'org': org,
        });
      }
    }

    if (assignments.isEmpty) return 0;

    const int batchLimit = 400;
    for (int b = 0; b < assignments.length; b += batchLimit) {
      final chunk = assignments.skip(b).take(batchLimit).toList();
      WriteBatch? batch = fs?.batch();

      for (final item in chunk) {
        final String leadId = item['leadId'];
        final AdminOrganization org = item['org'];

        final updateData = {
          'connectCode': org.connectCode.isNotEmpty ? org.connectCode : org.id,
          'assignedOrgId': org.id,
          'assignedOrgName': org.name,
          'assignedAt': FieldValue.serverTimestamp(),
          'assignmentStatus': 'assigned',
          'assignedTo': '',
          'assignedToPhone': '',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (batch != null && fs != null) {
          batch.set(fs.collection('leads').doc(leadId), updateData, SetOptions(merge: true));
        }

        final idx = _leads.indexWhere((l) => l.id == leadId || l.mobileNumber == leadId);
        if (idx != -1) {
          _leads[idx] = _leads[idx].copyWith(
            assignedOrgId: org.id,
            assignedOrgName: org.name,
            assignedToUserId: '',
            assignedToUserName: '',
            assignedAt: now,
            assignmentStatus: 'assigned',
          );
        }
        totalAssigned++;
      }

      if (batch != null) {
        try {
          await batch.commit();
        } catch (e) {
          debugPrint('Error committing custom quotas batch: $e');
        }
      }
    }

    notifyListeners();
    return totalAssigned;
  }

  /// Retrieve registered telecallers / devices under an organization
  List<AdminDevice> getDevicesForOrganization(AdminOrganization org) {
    final normOrgCode = _normalizeKey(org.connectCode);
    final normOrgName = org.name.trim().toLowerCase();
    final normOrgPhone = org.phone.replaceAll(RegExp(r'[^0-9]'), '');

    return _devices.where((d) {
      final normDevCode = _normalizeKey(d.connectCode);
      final normDevOrg = d.organizationName.trim().toLowerCase();
      final normDevPhone = d.phone.replaceAll(RegExp(r'[^0-9]'), '');

      final codeMatch = normOrgCode.isNotEmpty && normDevCode.isNotEmpty && (normOrgCode == normDevCode || normDevCode.contains(normOrgCode) || normOrgCode.contains(normDevCode));
      final nameMatch = normOrgName.isNotEmpty && (normDevOrg == normOrgName || normDevOrg.contains(normOrgName) || normOrgName.contains(normDevOrg));
      final phoneMatch = normOrgPhone.length >= 8 && normDevPhone.length >= 8 && (normOrgPhone.endsWith(normDevPhone) || normDevPhone.endsWith(normOrgPhone));

      return codeMatch || nameMatch || phoneMatch;
    }).toList();
  }

  /// Admin unassigns a lead from an organization back to the fresh pool
  Future<bool> unassignLeadFromOrganization(String leadId) async {
    final fs = firestore;
    if (fs != null) {
      try {
        await fs.collection('leads').doc(leadId).set({
          'connectCode': '',
          'assignedOrgId': '',
          'assignedOrgName': '',
          'assignedToUserId': '',
          'assignedToUserName': '',
          'assignedTo': '',
          'assignedToPhone': '',
          'assignedAt': null,
          'assignmentStatus': 'unassigned',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore unassignLead error: $e');
      }
    }

    final idx = _leads.indexWhere((l) => l.id == leadId || l.mobileNumber == leadId);
    if (idx != -1) {
      _leads[idx] = _leads[idx].copyWith(
        assignedOrgId: '',
        assignedOrgName: '',
        assignedToUserId: '',
        assignedToUserName: '',
        assignmentStatus: 'unassigned',
      );
      notifyListeners();
      return true;
    }
    return false;
  }
}
