class Alarm {
  int? seq;
  int work_seq;
  String alarmtime;

  Alarm(
    {
      this.seq,
      required this.work_seq,
      required this.alarmtime
    }
  );

  Alarm.fromMap(Map<String, dynamic> res)
  : seq = res['seq'],
    work_seq = res['work_seq'],
    alarmtime = res['alarmtime'];
    
}