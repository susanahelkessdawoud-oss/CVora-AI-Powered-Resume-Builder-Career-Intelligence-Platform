class Resume {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String professionalTitle;
  final String professionalSummary;
  final String documentType; // 'cv' or 'resume'
  final String resumeType; // visual style: modern / professional / creative
  final String template;
  final List<Education> education;
  final List<Experience> experience;
  final List<String> skills;
  final List<Project> projects;
  final List<Achievement> achievements;
  final List<Certification> certifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  Resume({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    required this.professionalTitle,
    required this.professionalSummary,
    this.documentType = 'resume',
    required this.resumeType,
    required this.template,
    required this.education,
    required this.experience,
    required this.skills,
    required this.projects,
    required this.achievements,
    required this.certifications,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      professionalTitle: json['professionalTitle'] ?? '',
      professionalSummary: json['professionalSummary'] ?? '',
      documentType: json['documentType'] ?? 'resume',
      resumeType: json['resumeType'] ?? 'modern',
      template: json['template'] ?? 'template1',
      education:
          (json['education'] as List?)
              ?.map((e) => Education.fromJson(e))
              .toList() ??
          [],
      experience:
          (json['experience'] as List?)
              ?.map((e) => Experience.fromJson(e))
              .toList() ??
          [],
      skills: List<String>.from(json['skills'] ?? []),
      projects:
          (json['projects'] as List?)
              ?.map((p) => Project.fromJson(p))
              .toList() ??
          [],
      achievements:
          (json['achievements'] as List?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          [],
      certifications:
          (json['certifications'] as List?)
              ?.map((c) => Certification.fromJson(c))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'location': location,
      'professionalTitle': professionalTitle,
      'professionalSummary': professionalSummary,
      'documentType': documentType,
      'resumeType': resumeType,
      'template': template,
      'education': education.map((e) => e.toJson()).toList(),
      'experience': experience.map((e) => e.toJson()).toList(),
      'skills': skills,
      'projects': projects.map((p) => p.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Education {
  final String id;
  final String school;
  final String degree;
  final String fieldOfStudy;
  final String startDate;
  final String endDate;
  final String description;

  Education({
    required this.id,
    required this.school,
    required this.degree,
    required this.fieldOfStudy,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] ?? '',
      school: json['school'] ?? '',
      degree: json['degree'] ?? '',
      fieldOfStudy: json['fieldOfStudy'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school': school,
      'degree': degree,
      'fieldOfStudy': fieldOfStudy,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
  }
}

class Experience {
  final String id;
  final String jobTitle;
  final String company;
  final String startDate;
  final String endDate;
  final String description;
  final bool isCurrentJob;

  Experience({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.isCurrentJob,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      company: json['company'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      description: json['description'] ?? '',
      isCurrentJob: json['isCurrentJob'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobTitle': jobTitle,
      'company': company,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
      'isCurrentJob': isCurrentJob,
    };
  }
}

class Project {
  final String id;
  final String name;
  final String description;
  final String link;
  final String technologies;
  final String startDate;
  final String endDate;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.link,
    required this.technologies,
    required this.startDate,
    required this.endDate,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      technologies: json['technologies'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'link': link,
      'technologies': technologies,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String date;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'description': description, 'date': date};
  }
}

class Certification {
  final String id;
  final String name;
  final String issuedBy;
  final String issueDate;
  final String expiryDate;
  final String link;

  Certification({
    required this.id,
    required this.name,
    required this.issuedBy,
    required this.issueDate,
    required this.expiryDate,
    required this.link,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      issuedBy: json['issuedBy'] ?? '',
      issueDate: json['issueDate'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      link: json['link'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuedBy': issuedBy,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'link': link,
    };
  }
}

class User {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final DateTime createdAt;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
