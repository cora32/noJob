class JobData {
  final int? id;
  final DateTime date;
  final String title;
  final String description;
  final String link;
  final String status;
  final String source;

  JobData({
    this.id,
    required this.date,
    required this.title,
    required this.description,
    required this.link,
    required this.status,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'description': description,
      'link': link,
      'status': status,
      'source': source,
    };
  }

  factory JobData.fromMap(Map<String, dynamic> map) {
    return JobData(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      title: map['title'] as String,
      description: map['description'] as String,
      link: (map['link'] as String?) ?? "",
      status: map['status'] as String,
      source: map['source'] as String,
    );
  }
}

class CountResult {
  final String type;
  final int count;

  CountResult({required this.type, required this.count});
}

abstract class IDBRepo {
  Future<List<JobData>> getData();

  Future<void> addJob(JobData job);

  Future<void> updateJobStatus(int id, String status);

  Future<void> deleteJob(int id);

  Future<int> getLastTimestamp();

  Future<List<CountResult>> countDistinctTypes();

  Future<int> countTotal();

  Future<List<JobData>> searchLogs(String query);
}

abstract class IJobRepo {
  Future<void> addJob(String title, String description, String link);

  Future<List<JobData>> getData();

  Future<void> updateJobStatus(int id, String status);

  Future<void> deleteJob(int id);

  Future<int> getLastTimestamp();

  Future<List<CountResult>> countDistinctTypes();

  Future<int> countTotal();

  Future<List<JobData>> searchLogs(String query);
}
