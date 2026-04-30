import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';

final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  final state = AppState();
  state.init();
  return state;
});

class AppState extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Gunakan classId yang sama untuk semua user dalam satu kelas
  static const _classId = 'kelas-10a';

  SchoolSettings settings = const SchoolSettings(
    schoolName: 'SMA KelasKu',
    className: 'X IPA 1',
    phases: [],
  );

  List<AppUser> _users = [];
  List<TaskItem> _tasks = [];
  Map<String, List<ScheduleSlot>> _schedule = {};
  Map<String, AttendanceStatus> _attendance = {};
  String _lastAttendanceResetKey = _dateKey(DateTime.now());

  bool isLoading = true;

  List<AppUser> get users => List.unmodifiable(_users);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  Map<String, List<ScheduleSlot>> get schedule =>
      _schedule.map((k, v) => MapEntry(k, List.unmodifiable(v)));
  Map<String, AttendanceStatus> get attendance =>
      Map.unmodifiable(_attendance);

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  // ─── INIT ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await Future.wait([
      _loadSettings(),
      _loadUsers(),
      _loadTasks(),
      _loadSchedule(),
      _loadAttendance(),
    ]);
    isLoading = false;
    notifyListeners();
  }

  // ─── LOAD FROM FIRESTORE ───────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    final doc = await _db.collection('classes').doc(_classId).get();
    if (doc.exists) {
      settings = SchoolSettings.fromFirestore(doc.data()!);
    } else {
      // Buat default jika belum ada
      await _db.collection('classes').doc(_classId).set(settings.toJson());
    }
  }

  Future<void> _loadUsers() async {
    final snap = await _db
        .collection('users')
        .where('classId', isEqualTo: _classId)
        .get();
    _users = snap.docs
        .map((d) => AppUser.fromFirestore(d.data(), d.id))
        .toList();
  }

  Future<void> _loadTasks() async {
    final snap = await _db
        .collection('tasks')
        .where('classId', isEqualTo: _classId)
        .orderBy('createdAt', descending: true)
        .get();
    _tasks = snap.docs
        .map((d) => TaskItem.fromFirestore(d.data(), d.id))
        .toList();
  }

  Future<void> _loadSchedule() async {
    final snap = await _db
        .collection('schedules')
        .where('classId', isEqualTo: _classId)
        .get();
    _schedule = {};
    for (final doc in snap.docs) {
      final day = doc.data()['day'] as String;
      final slotsRaw = doc.data()['slots'] as List<dynamic>? ?? [];
      _schedule[day] = slotsRaw
          .map((s) => ScheduleSlot.fromMap(Map<String, dynamic>.from(s)))
          .toList();
    }
    // Isi hari yang kosong
    for (final day in weekdays) {
      _schedule.putIfAbsent(day, () => []);
    }
  }

  Future<void> _loadAttendance() async {
    final today = _dateKey(DateTime.now());
    final snap = await _db
        .collection('attendance')
        .where('classId', isEqualTo: _classId)
        .where('date', isEqualTo: today)
        .get();
    _attendance = {};
    for (final doc in snap.docs) {
      final email = doc.data()['teacherEmail'] as String;
      final status = AttendanceStatus.values.firstWhere(
        (s) => s.name == doc.data()['status'],
        orElse: () => AttendanceStatus.unchecked,
      );
      _attendance[email] = status;
    }
  }

  // ─── GETTERS ───────────────────────────────────────────────────────────────

  List<AppUser> get teachers =>
      _users.where((u) => u.role == UserRole.teacher).toList();
  List<AppUser> get students =>
      _users.where((u) => u.role == UserRole.student).toList();
  List<AppUser> get pendingUsers =>
      _users.where((u) => u.role == UserRole.pending).toList();

  List<String> get weekdays =>
      const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  AppUser? findUserByEmail(String email) {
    try {
      return _users.firstWhere(
          (u) => u.email.toLowerCase() == email.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  AppUser? findUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── USER MANAGEMENT ───────────────────────────────────────────────────────

  Future<void> approveUserAsStudent(String userId) async {
    await _db.collection('users').doc(userId).update({'role': 'student'});
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(role: UserRole.student);
      notifyListeners();
    }
  }

  Future<void> approveUserAsTeacher(String userId) async {
    await _db.collection('users').doc(userId).update({
      'role': 'teacher',
      'needsTeacherProfile': true,
    });
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(
        role: UserRole.teacher,
        needsTeacherProfile: true,
      );
      _attendance[_users[index].email] = AttendanceStatus.unchecked;
      notifyListeners();
    }
  }

  Future<void> rejectUser(String userId) async {
    // Hapus dari Firestore Auth tidak bisa langsung dari client,
    // cukup hapus dari collection users
    await _db.collection('users').doc(userId).delete();
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  Future<void> saveTeacherProfile({
    required String userId,
    required String subject,
    required String nickname,
  }) async {
    await _db.collection('users').doc(userId).update({
      'subject': subject,
      'nickname': nickname,
      'needsTeacherProfile': false,
    });
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(
        subject: subject,
        nickname: nickname,
        needsTeacherProfile: false,
      );
      notifyListeners();
    }
  }

  // ─── TASKS ─────────────────────────────────────────────────────────────────

  List<TaskItem> filteredTasks(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.pending:
        return _tasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        return _tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        return List.from(_tasks);
    }
  }

  Future<void> addTask({
    required String title,
    required String subject,
    String? note,
    required DateTime deadline,
  }) async {
    final ref = _db.collection('tasks').doc();
    final task = TaskItem(
      id: ref.id,
      title: title,
      subject: subject,
      note: note,
      deadline: deadline,
    );
    await ref.set({
      ...task.toJson(),
      'classId': _classId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _tasks.insert(0, task);
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final newValue = !_tasks[index].isCompleted;
    await _db.collection('tasks').doc(id).update({'isCompleted': newValue});
    _tasks[index] = _tasks[index].copyWith(isCompleted: newValue);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await _db.collection('tasks').doc(id).delete();
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // ─── SCHEDULE ──────────────────────────────────────────────────────────────

  Future<void> _saveScheduleDay(String day) async {
    final slots = _schedule[day] ?? [];
    await _db
        .collection('schedules')
        .doc('${_classId}_$day')
        .set({
      'classId': _classId,
      'day': day,
      'slots': slots.map((s) => s.toMap()).toList(),
    });
  }

  Future<void> addScheduleEntry({
    required String day,
    required int slotIndex,
    required ScheduleEntry entry,
  }) async {
    final slots = _schedule[day];
    if (slots == null || slotIndex >= slots.length) return;
    final current = List<ScheduleEntry>.from(slots[slotIndex].entries)
      ..add(entry);
    slots[slotIndex] = slots[slotIndex].copyWith(entries: current);
    await _saveScheduleDay(day);
    notifyListeners();
  }

  Future<void> updateScheduleEntry({
    required String day,
    required int slotIndex,
    required int entryIndex,
    required ScheduleEntry entry,
  }) async {
    final slots = _schedule[day];
    if (slots == null || slotIndex >= slots.length) return;
    final current = List<ScheduleEntry>.from(slots[slotIndex].entries);
    if (entryIndex < 0 || entryIndex >= current.length) return;
    current[entryIndex] = entry;
    slots[slotIndex] = slots[slotIndex].copyWith(entries: current);
    await _saveScheduleDay(day);
    notifyListeners();
  }

  Future<void> deleteScheduleEntry({
    required String day,
    required int slotIndex,
    required int entryIndex,
  }) async {
    final slots = _schedule[day];
    if (slots == null || slotIndex >= slots.length) return;
    final current = List<ScheduleEntry>.from(slots[slotIndex].entries);
    if (entryIndex < 0 || entryIndex >= current.length) return;
    current.removeAt(entryIndex);
    slots[slotIndex] = slots[slotIndex].copyWith(entries: current);
    await _saveScheduleDay(day);
    notifyListeners();
  }

  // ─── ATTENDANCE ────────────────────────────────────────────────────────────

  void ensureDailyAttendanceReset() {
    final today = _dateKey(DateTime.now());
    if (today == _lastAttendanceResetKey) return;
    for (final teacher in teachers) {
      _attendance[teacher.email] = AttendanceStatus.unchecked;
    }
    _lastAttendanceResetKey = today;
    notifyListeners();
  }

  int presentTeacherCount() {
    ensureDailyAttendanceReset();
    return teachers
        .where((t) => _attendance[t.email] == AttendanceStatus.present)
        .length;
  }

  AttendanceStatus statusOfTeacher(String email) {
    ensureDailyAttendanceReset();
    return _attendance[email] ?? AttendanceStatus.unchecked;
  }

  Future<void> updateOwnAttendance({
    required String email,
    required AttendanceStatus status,
  }) async {
    ensureDailyAttendanceReset();
    final today = _dateKey(DateTime.now());
    await _db
        .collection('attendance')
        .doc('${_classId}_${email}_$today')
        .set({
      'classId': _classId,
      'teacherEmail': email,
      'status': status.name,
      'date': today,
    });
    _attendance[email] = status;
    notifyListeners();
  }

  // ─── SETTINGS ──────────────────────────────────────────────────────────────

  Future<void> updateSchoolIdentity({
    required String schoolName,
    required String className,
  }) async {
    await _db.collection('classes').doc(_classId).update({
      'schoolName': schoolName,
      'className': className,
    });
    settings = settings.copyWith(schoolName: schoolName, className: className);
    notifyListeners();
  }

  Future<void> addPhase({
    required String label,
    required String start,
    required String end,
  }) async {
    final phase = SchoolPhase(
      id: 'phase_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      start: start,
      end: end,
    );
    final phases = List<SchoolPhase>.from(settings.phases)..add(phase);
    settings = settings.copyWith(phases: phases);
    await _db.collection('classes').doc(_classId).update({
      'phases': phases.map((p) => p.toMap()).toList(),
    });
    notifyListeners();
  }

  Future<void> updatePhase({
    required String id,
    required String label,
    required String start,
    required String end,
  }) async {
    final phases = List<SchoolPhase>.from(settings.phases);
    final index = phases.indexWhere((p) => p.id == id);
    if (index == -1) return;
    phases[index] = phases[index].copyWith(label: label, start: start, end: end);
    settings = settings.copyWith(phases: phases);
    await _db.collection('classes').doc(_classId).update({
      'phases': phases.map((p) => p.toMap()).toList(),
    });
    notifyListeners();
  }

  Future<void> deletePhase(String id) async {
    final phases = List<SchoolPhase>.from(settings.phases)
      ..removeWhere((p) => p.id == id);
    settings = settings.copyWith(phases: phases);
    await _db.collection('classes').doc(_classId).update({
      'phases': phases.map((p) => p.toMap()).toList(),
    });
    notifyListeners();
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  ScheduleEntry? getCurrentTeachingEntry(DateTime now) {
    final day = _weekdayName(now.weekday);
    if (day == null) return null;
    final slots = _schedule[day] ?? [];
    final currentMinutes = now.hour * 60 + now.minute;
    for (final slot in slots) {
      final start = _parseMinutes(slot.start);
      final end = _parseMinutes(slot.end);
      if (currentMinutes >= start &&
          currentMinutes < end &&
          !slot.isBreak &&
          slot.entries.isNotEmpty) {
        return slot.entries.first;
      }
    }
    return null;
  }

  SchoolPhase? getCurrentPhase(DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    for (final phase in settings.phases) {
      final start = _parseMinutes(phase.start);
      final end = _parseMinutes(phase.end);
      if (currentMinutes >= start && currentMinutes < end) return phase;
    }
    return null;
  }

  List<TaskItem> upcomingDeadlines() {
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 2));
    return _tasks.where((t) {
      return !t.isCompleted &&
          t.deadline.isAfter(now.subtract(const Duration(days: 1))) &&
          t.deadline.isBefore(threshold);
    }).toList();
  }

  String? _weekdayName(int weekday) {
    const map = {
      DateTime.monday: 'Senin',
      DateTime.tuesday: 'Selasa',
      DateTime.wednesday: 'Rabu',
      DateTime.thursday: 'Kamis',
      DateTime.friday: 'Jumat',
    };
    return map[weekday];
  }

  int _parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 +
        (int.tryParse(parts[1]) ?? 0);
  }
}