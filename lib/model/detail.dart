class Detail {
  int? seq;
  int work_seq;
  int check;
  String content;
  int customorder;

  Detail(
    {
      this.seq,
      required this.work_seq,
      required this.check,
      required this.content,
      required this.customorder
    }
  );

  Detail.fromMap(Map<String, dynamic> res)
  : seq = res['seq'],
    work_seq = res['work_seq'],
    check = res['check'],
    content = res['content'],
    customorder = res['customorder'];
    
}