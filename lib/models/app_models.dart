enum UserRole { admin, teacher, student, pending }

enum AttendanceStatus { present, absent, unchecked }

enum TaskFilter { all, pending, completed }

class AppUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final UserRole role;
  final String classId;
  final String? subject;
  final String? nickname;
  final bool needsTeacherProfile;

  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    required this.classId,
    this.subject,
    this.nickname,
    this.needsTeacherProfile = false,
  });

  bool get isTeacher => role == UserRole.teacher;

  String get displayTeacherName => nickname?.isNotEmpty == true ? nickname! : name;

  AppUser copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    UserRole? role,
    String? classId,
    String? subject,
    String? nickname,
    bool? needsTeacherProfile,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      classId: classId ?? this.classId,
      subject: subject ?? this.subject,
      nickname: nickname ?? this.nickname,
      needsTeacherProfile: needsTeacherProfile ?? this.needsTeacherProfile,
    );
  }
  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
  return AppUser(
    id: id,
    name: data['name'] ?? '',
    username: data['username'] ?? '',
    email: data['email'] ?? '',
    role: UserRole.values.firstWhere(
      (r) => r.name == data['role'],
      orElse: () => UserRole.pending,
    ),
    classId: data['classId'] ?? '',
    subject: data['subject'],
    nickname: data['nickname'],
    needsTeacherProfile: data['needsTeacherProfile'] ?? false,
  );
}
  Map<String, dynamic> toJson() => {
    'name': name,
    'username': username,
    'email': email,
    'role': role.name,
    'classId': classId,
    'subject': subject,
    'nickname': nickname,
    'needsTeacherProfile': needsTeacherProfile,
  };
}

class TaskItem {
  final String id;
  final String title;
  final String subject;
  final String? note;
  final DateTime deadline;
  final bool isCompleted;

  const TaskItem({
    required this.id,
    required this.title,
    required this.subject,
    this.note,
    required this.deadline,
    this.isCompleted = false,
  });

  TaskItem copyWith({
    String? id,
    String? title,
    String? subject,
    String? note,
    DateTime? deadline,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      note: note ?? this.note,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
  factory TaskItem.fromFirestore(Map<String, dynamic> data, String id) {
  return TaskItem(
    id: id,
    title: data['title'] ?? '',
    subject: data['subject'] ?? '',
    note: data['note'],
    deadline: DateTime.fromMillisecondsSinceEpoch(data['deadline']),
    isCompleted: data['isCompleted'] ?? false,
  );
}
  Map<String, dynamic> toJson() => {
    'title': title,
    'subject': subject,
    'note': note,
    'deadline': deadline.millisecondsSinceEpoch,
    'isCompleted': isCompleted,
  };
}

class ScheduleEntry {
  final String subject;
  final String teacherName;
  final String teacherEmail;

  const ScheduleEntry({
    required this.subject,
    required this.teacherName,
    required this.teacherEmail,
  });

  ScheduleEntry copyWith({
    String? subject,
    String? teacherName,
    String? teacherEmail,
  }) {
    return ScheduleEntry(
      subject: subject ?? this.subject,
      teacherName: teacherName ?? this.teacherName,
      teacherEmail: teacherEmail ?? this.teacherEmail,
    );
  }
  factory ScheduleEntry.fromMap(Map<String, dynamic> data) {
  return ScheduleEntry(
    subject: data['subject'] ?? '',
    teacherName: data['teacherName'] ?? '',
    teacherEmail: data['teacherEmail'] ?? '',
  );
}
  Map<String, dynamic> toMap() => {
    'subject': subject,
    'teacherName': teacherName,
    'teacherEmail': teacherEmail,
  };
}

class ScheduleSlot {
  final String start;
  final String end;
  final bool isBreak;
  final List<ScheduleEntry> entries;

  const ScheduleSlot({
    required this.start,
    required this.end,
    this.isBreak = false,
    this.entries = const [],
  });

  ScheduleSlot copyWith({
    String? start,
    String? end,
    bool? isBreak,
    List<ScheduleEntry>? entries,
  }) {
    return ScheduleSlot(
      start: start ?? this.start,
      end: end ?? this.end,
      isBreak: isBreak ?? this.isBreak,
      entries: entries ?? this.entries,
    );
  }
  factory ScheduleSlot.fromMap(Map<String, dynamic> data) {
  final entriesRaw = data['entries'] as List<dynamic>? ?? [];
  return ScheduleSlot(
    start: data['start'] ?? '',
    end: data['end'] ?? '',
    isBreak: data['isBreak'] ?? false,
    entries: entriesRaw
        .map((e) => ScheduleEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

  Map<String, dynamic> toMap() => {
    'start': start,
    'end': end,
    'isBreak': isBreak,
    'entries': entries.map((e) => e.toMap()).toList(),
  };
}

class SchoolPhase {
  final String id;
  final String label;
  final String start;
  final String end;

  const SchoolPhase({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
  });

  SchoolPhase copyWith({
    String? id,
    String? label,
    String? start,
    String? end,
  }) {
    return SchoolPhase(
      id: id ?? this.id,
      label: label ?? this.label,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
  factory SchoolPhase.fromMap(Map<String, dynamic> data) {
  return SchoolPhase(
    id: data['id'] ?? '',
    label: data['label'] ?? '',
    start: data['start'] ?? '',
    end: data['end'] ?? '',
  );
}

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'start': start,
    'end': end,
  };
}

class SchoolSettings {
  final String schoolName;
  final String className;
  final List<SchoolPhase> phases;

  const SchoolSettings({
    required this.schoolName,
    required this.className,
    required this.phases,
  });

  SchoolSettings copyWith({
    String? schoolName,
    String? className,
    List<SchoolPhase>? phases,
  }) {
    return SchoolSettings(
      schoolName: schoolName ?? this.schoolName,
      className: className ?? this.className,
      phases: phases ?? this.phases,
    );
  }
  factory SchoolSettings.fromFirestore(Map<String, dynamic> data) {
  final phasesRaw = data['phases'] as List<dynamic>? ?? [];
  return SchoolSettings(
    schoolName: data['schoolName'] ?? '',
    className: data['className'] ?? '',
    phases: phasesRaw
        .map((p) => SchoolPhase.fromMap(Map<String, dynamic>.from(p)))
        .toList(),
  );
}

  Map<String, dynamic> toJson() => {
    'schoolName': schoolName,
    'className': className,
    'phases': phases.map((p) => p.toMap()).toList(),
  };
}

class AttendanceRecord {
  final String teacherEmail;
  final AttendanceStatus status;

  const AttendanceRecord({
    required this.teacherEmail,
    required this.status,
  });

  AttendanceRecord copyWith({
    String? teacherEmail,
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      teacherEmail: teacherEmail ?? this.teacherEmail,
      status: status ?? this.status,
    );
  }
  factory AttendanceRecord.fromMap(Map<String, dynamic> data) {
  return AttendanceRecord(
    teacherEmail: data['teacherEmail'] ?? '',
    status: AttendanceStatus.values.firstWhere(
      (s) => s.name == data['status'],
      orElse: () => AttendanceStatus.unchecked,
    ),
  );
}

  Map<String, dynamic> toMap() => {
    'teacherEmail': teacherEmail,
    'status': status.name,
  };
}
