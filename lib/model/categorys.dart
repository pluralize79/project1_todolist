class Categorys {
  int? seq;
  String title;
  int customorder;

  Categorys(
    {
      this.seq,
      required this.title,
      required this.customorder
    }
  );

  Categorys.fromMap(Map<String, dynamic> res)
  : seq = res['seq'],
    title = res['title'],
    customorder = res['customorder'];
    
}