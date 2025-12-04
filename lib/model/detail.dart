class Detail {
  int? seq;
  int work_seq;
  int checked;
  String content;
  int customorder;

  Detail(
    {
      this.seq,
      required this.work_seq,
      required this.checked,
      required this.content,
      required this.customorder
    }
  );

  Detail.fromMap(Map<String, dynamic> res)
  : seq = res['seq'],
    work_seq = res['work_seq'],
    checked = res['checked'],
    content = res['content'],
    customorder = res['customorder'];
    
}