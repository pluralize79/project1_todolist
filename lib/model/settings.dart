class Settings {
  int themecolor;
  int darkmode;

  Settings(
    {
      required this.themecolor,
      required this.darkmode
    }
  );

  Settings.fromMap(Map<String,dynamic> res)
  : themecolor = res['themecolor'],
    darkmode = res['darkmode'];

}