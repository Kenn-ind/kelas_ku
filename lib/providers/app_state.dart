import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';

final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  return AppState();
});

class AppState extends ChangeNotifier {
  AppState() {
    _seedData();
  }

  late SchoolSettings settings;
  final List<AppUser> _users = [];
  final List<TaskItem> _tasks = [];
  final Map<String, List<ScheduleSlot>> _schedule = {};
  final Map<String, AttendanceStatus> _attendance = {};
  String _lastAttendanceResetKey = _dateKey(DateTime.now());

  List<AppUser> get users => List.unmodifiable(_users);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  Map<String, List<ScheduleSlot>> get schedule => _schedule.map((key, value) => MapEntry(key, List.unmodifiable(value)));
  Map<String, AttendanceStatus> get attendance => Map.unmodifiable(_attendance);

  static String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  void ensureDailyAttendanceReset() {
    final today = _dateKey(DateTime.now());
    if (today == _lastAttendanceResetKey) return;

    for (final teacher in teachers) {
      _attendance[teacher.email] = AttendanceStatus.unchecked;
    }
    _lastAttendanceResetKey = today;
    notifyListeners();
  }

  List<AppUser> get teachers => _users.where((u) => u.role == UserRole.teacher).toList();
  List<AppUser> get students => _users.where((u) => u.role == UserRole.student).toList();
  List<AppUser> get pendingUsers => _users.where((u) => u.role == UserRole.pending).toList();

  AppUser? findUserByEmail(String email) {
    try {
      return _users.firstWhere((u) => u.email.toLowerCase() == email.toLowerCase());
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

  void registerPending({
    required String name,
    required String username,
    required String email,
  }) {
    final existing = findUserByEmail(email);
    if (existing != null) return;

    _users.add(
      AppUser(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        username: username,
        email: email,
        role: UserRole.pending,
        classId: 'kelas-10a',
      ),
    );
    notifyListeners();
  }

  void approveUserAsStudent(String userId) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    _users[index] = _users[index].copyWith(role: UserRole.student);
    notifyListeners();
  }

  void approveUserAsTeacher(String userId) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    _users[index] = _users[index].copyWith(
      role: UserRole.teacher,
      needsTeacherProfile: true,
    );
    _attendance[_users[index].email] = AttendanceStatus.unchecked;
    notifyListeners();
  }

  void rejectUser(String userId) {
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
  }

  void saveTeacherProfile({
    required String userId,
    required String subject,
    required String nickname,
  }) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    _users[index] = _users[index].copyWith(
      subject: subject,
      nickname: nickname,
      needsTeacherProfile: false,
    );
    notifyListeners();
  }

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

  void addTask({
    required String title,
    required String subject,
    String? note,
    required DateTime deadline,
  }) {
    _tasks.insert(
      0,
      TaskItem(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        subject: subject,
        note: note,
        deadline: deadline,
      ),
    );
    notifyListeners();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  List<String> get weekdays => const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  void addScheduleEntry({
    required String day,
    required int slotIndex,
    required ScheduleEntry entry,
  }) {
    final slots = _schedule[day];
    if (slots == null || slotIndex >= slots.length) return;
    final current = List<ScheduleEntry>.from(slots[slotIndex].entries)..add(entry);
    slots[slotIndex] = slots[slotIndex].copyWith(entries: current);
    notifyListeners();
  }

  void deleteScheduleEntry({
    required String day,
    required int slotIndex,
    required int entryIndex,
  }) {
    final slots = _schedule[day];
    if (slots == null || slotIndex >= slots.length) return;
    final current = List<ScheduleEntry>.from(slots[slotIndex].entries);
    if (entryIndex < 0 || entryIndex >= current.length) return;
    current.removeAt(entryIndex);
    slots[slotIndex] = slots[slotIndex].copyWith(entries: current);
    notifyListeners();
  }

  ScheduleEntry? getCurrentTeachingEntry(DateTime now) {
    final day = _weekdayName(now.weekday);
    if (day == null) return null;
    final slots = _schedule[day] ?? [];
    final currentMinutes = now.hour * 60 + now.minute;

    for (final slot in slots) {
      final start = _parseMinutes(slot.start);
      final end = _parseMinutes(slot.end);
      if (currentMinutes >= start && currentMinutes < end && !slot.isBreak && slot.entries.isNotEmpty) {
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
      if (currentMinutes >= start && currentMinutes < end) {
        return phase;
      }
    }
    return null;
  }

  List<TaskItem> upcomingDeadlines() {
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: 2));
    return _tasks.where((task) {
      return !task.isCompleted && task.deadline.isAfter(now.subtract(const Duration(days: 1))) && task.deadline.isBefore(threshold);
    }).toList();
  }

  int presentTeacherCount() {
    ensureDailyAttendanceReset();
    return teachers.where((teacher) => _attendance[teacher.email] == AttendanceStatus.present).length;
  }

  AttendanceStatus statusOfTeacher(String email) {
    ensureDailyAttendanceReset();
    return _attendance[email] ?? AttendanceStatus.unchecked;
  }

  void updateOwnAttendance({
    required String email,
    required AttendanceStatus status,
  }) {
    ensureDailyAttendanceReset();
    _attendance[email] = status;
    notifyListeners();
  }

  void updateSchoolIdentity({
    required String schoolName,
    required String className,
  }) {
    settings = settings.copyWith(schoolName: schoolName, className: className);
    notifyListeners();
  }

  void addPhase({
    required String label,
    required String start,
    required String end,
  }) {
    final phases = List<SchoolPhase>.from(settings.phases)
      ..add(
        SchoolPhase(
          id: 'phase_${DateTime.now().millisecondsSinceEpoch}',
          label: label,
          start: start,
          end: end,
        ),
      );
    settings = settings.copyWith(phases: phases);
    notifyListeners();
  }

  void updatePhase({
    required String id,
    required String label,
    required String start,
    required String end,
  }) {
    final phases = List<SchoolPhase>.from(settings.phases);
    final index = phases.indexWhere((p) => p.id == id);
    if (index == -1) return;
    phases[index] = phases[index].copyWith(label: label, start: start, end: end);
    settings = settings.copyWith(phases: phases);
    notifyListeners();
  }

  void deletePhase(String id) {
    final phases = List<SchoolPhase>.from(settings.phases)..removeWhere((p) => p.id == id);
    settings = settings.copyWith(phases: phases);
    notifyListeners();
  }

  String? _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      default:
        return null;
    }
  }

  int _parseMinutes(String hhmm) {
    final parts = hhmm.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  void _seedData() {
    settings = const SchoolSettings(
      schoolName: 'SMA KelasKu',
      className: 'X IPA 1',
      phases: [
        SchoolPhase(id: 'p1', label: 'Masuk Kelas', start: '08:00', end: '09:00'),
        SchoolPhase(id: 'p2', label: 'Istirahat 1', start: '09:00', end: '09:30'),
        SchoolPhase(id: 'p3', label: 'Masuk Kelas', start: '09:30', end: '11:30'),
        SchoolPhase(id: 'p4', label: 'Istirahat 2', start: '11:30', end: '12:00'),
        SchoolPhase(id: 'p5', label: 'Masuk Kelas', start: '12:00', end: '15:00'),
      ],
    );

    _users.addAll([
      const AppUser(
        id: 'u1',
        name: 'Alya Admin',
        username: 'alya.admin',
        email: 'admin@kelasku.id',
        role: UserRole.admin,
        classId: 'kelas-10a',
      ),
      const AppUser(
        id: 'u2',
        name: 'Budi Santoso',
        username: 'budi.guru',
        email: 'guru@kelasku.id',
        role: UserRole.teacher,
        classId: 'kelas-10a',
        subject: 'Matematika',
        nickname: 'Pak Budi',
      ),
      const AppUser(
        id: 'u3',
        name: 'Siska Lestari',
        username: 'siska.guru',
        email: 'siska@kelasku.id',
        role: UserRole.teacher,
        classId: 'kelas-10a',
        subject: 'Bahasa Indonesia',
        nickname: 'Bu Siska',
      ),
      const AppUser(
        id: 'u4',
        name: 'Raka Pratama',
        username: 'raka.siswa',
        email: 'siswa@kelasku.id',
        role: UserRole.student,
        classId: 'kelas-10a',
      ),
      const AppUser(
        id: 'u5',
        name: 'Dina Kurnia',
        username: 'dina.user',
        email: 'dina@kelasku.id',
        role: UserRole.pending,
        classId: 'kelas-10a',
      ),
    ]);

    _tasks.addAll([
      TaskItem(
        id: 't1',
        title: 'Latihan Aljabar',
        subject: 'Matematika',
        note: 'Kerjakan nomor 1-10',
        deadline: DateTime.now().add(const Duration(days: 1)),
      ),
      TaskItem(
        id: 't2',
        title: 'Ringkasan Cerpen',
        subject: 'Bahasa Indonesia',
        note: 'Tulis minimal 2 paragraf',
        deadline: DateTime.now().add(const Duration(days: 2)),
      ),
      TaskItem(
        id: 't3',
        title: 'Kuis Pecahan',
        subject: 'Matematika',
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: true,
      ),
    ]);

    _attendance['guru@kelasku.id'] = AttendanceStatus.present;
    _attendance['siska@kelasku.id'] = AttendanceStatus.unchecked;

    for (final day in weekdays) {
      _schedule[day] = _generateDaySlots(day);
    }
  }

  List<ScheduleSlot> _generateDaySlots(String day) {
    final raw = <ScheduleSlot>[
      const ScheduleSlot(
        start: '08:00',
        end: '08:30',
        entries: [
          ScheduleEntry(subject: 'Matematika', teacherName: 'Pak Budi', teacherEmail: 'guru@kelasku.id'),
        ],
      ),
      const ScheduleSlot(
        start: '08:30',
        end: '09:00',
        entries: [
          ScheduleEntry(subject: 'Bahasa Indonesia', teacherName: 'Bu Siska', teacherEmail: 'siska@kelasku.id'),
        ],
      ),
      const ScheduleSlot(start: '09:00', end: '09:30', isBreak: true),
      const ScheduleSlot(
        start: '09:30',
        end: '10:00',
        entries: [
          ScheduleEntry(subject: 'Matematika', teacherName: 'Pak Budi', teacherEmail: 'guru@kelasku.id'),
          ScheduleEntry(subject: 'Bahasa Indonesia', teacherName: 'Bu Siska', teacherEmail: 'siska@kelasku.id'),
        ],
      ),
      const ScheduleSlot(
        start: '10:00',
        end: '10:30',
        entries: [
          ScheduleEntry(subject: 'Sejarah', teacherName: 'Pak Budi', teacherEmail: 'guru@kelasku.id'),
        ],
      ),
      const ScheduleSlot(
        start: '10:30',
        end: '11:00',
        entries: [
          ScheduleEntry(subject: 'Biologi', teacherName: 'Bu Siska', teacherEmail: 'siska@kelasku.id'),
        ],
      ),
      const ScheduleSlot(
        start: '11:00',
        end: '11:30',
        entries: [
          ScheduleEntry(subject: 'Seni Budaya', teacherName: 'Pak Budi', teacherEmail: 'guru@kelasku.id'),
        ],
      ),
      const ScheduleSlot(start: '11:30', end: '12:00', isBreak: true),
      const ScheduleSlot(
        start: '12:00',
        end: '12:30',
        entries: [
          ScheduleEntry(subject: 'Fisika', teacherName: 'Pak Budi', teacherEmail: 'guru@kelasku.id'),
        ],
      ),
      const ScheduleSlot(
        start: '12:30',
        end: '13:00',
        entries: [
          ScheduleEntry(subject: 'Bahasa Inggris', teacherName: 'Bu Siska', teacherEmail: 'siska@kelasku.id'),
        ],
      ),
      const ScheduleSlot(
        start: '13:00',
        end: '13:30',
        entries: [
          ScheduleEntry(subject: 'Kimia', teacherName: 'Pak Budi', teacherEmail: 'guru@kelasku.id'),
        ],
      ),
      const ScheduleSlot(
        start: '13:30',
        end: '14:00',
        entries: [
          ScheduleEntry(subject: 'Geografi', teacherName: 'Bu Siska', teacherEmail: 'siska@kelasku.id'),
        ],
      ),
      const ScheduleSlot(
        start: '14:00',
        end: '14:30',
        entries: [
          ScheduleEntry(subject: 'PPKn', teacherName: 'Pak Budi', teacherEmail: 'guru@kelasku.id'),
        ],
      ),
      const ScheduleSlot(
        start: '14:30',
        end: '15:00',
        entries: [
          ScheduleEntry(subject: 'Informatika', teacherName: 'Bu Siska', teacherEmail: 'siska@kelasku.id'),
        ],
      ),
    ];
    return List.from(raw);
  }
}
