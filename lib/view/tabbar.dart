import 'package:flutter/material.dart';
import 'package:project1_todolist/view/calendar_page.dart';
import 'package:project1_todolist/view/list_work.dart';
import 'package:project1_todolist/view/mypage.dart';

class Tabbar extends StatefulWidget {
  const Tabbar({super.key});

  @override
  State<Tabbar> createState() => _TabbarState();
}

class _TabbarState extends State<Tabbar> with SingleTickerProviderStateMixin{
  late TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this); // 탭 컨트롤러
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: controller,
        children: [
          ListWork(),
          CalendarPage(),
          Mypage()
        ]
      ),
      bottomNavigationBar: TabBar(
        controller: controller,
        tabs: [
          Tab(
            text: '작업',
            icon: Icon(Icons.dns)
          ),
          Tab(
            text: '달력',
            icon: Icon(Icons.calendar_month)
          ),
          Tab(
            text: '마이페이지',
            icon: Icon(Icons.person)
          ),
        ]
      )
    );
  }
}