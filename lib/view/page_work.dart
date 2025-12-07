import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1_todolist/model/detail.dart';
import 'package:project1_todolist/model/place.dart';
import 'package:project1_todolist/model/work.dart';
import 'package:project1_todolist/vm/database_handler.dart';

class PageWork extends StatefulWidget {
  const PageWork({super.key});

  @override
  State<PageWork> createState() => _PageWorkState();
}

class _PageWorkState extends State<PageWork> {
  late DatabaseHandler handler;
  late int workSeq;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    workSeq = Get.arguments as int;
  }

  // ✅ 페이지 전체 데이터 로드
  Future<({
    Work work,
    List<Detail> details,
    Place? place,
  })> loadPageData() async {
    final workList = await handler.listWork(0);
    final work = workList.firstWhere((e) => e.seq == workSeq);

    final details = await handler.listDetail(workSeq);
    final placeList = await handler.listPlace(workSeq);

    return (
      work: work,
      details: details,
      place: placeList.isEmpty ? null : placeList.first,
    );
  }

  // ✅ 이미지 전체보기 팝업
  void showImagePopup(Uint8List image) {
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.memory(
                image,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('작업 상세'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: loadPageData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final work = snapshot.data!.work;
          final details = snapshot.data!.details;
          final place = snapshot.data!.place;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// ✅ 내용
                Text(
                  work.content,
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 10),

                /// ✅ 날짜 / 시간
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 18),
                    const SizedBox(width: 6),
                    Text(work.duedate),
                    if (work.duetime != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 4),
                      Text(work.duetime!),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                /// ✅ 메모
                if (work.memo != null && work.memo!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(work.memo!),
                  ),

                const SizedBox(height: 20),

                /// ✅ 이미지 (클릭 → 팝업)
                if (work.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () {
                        showImagePopup(work.image as Uint8List);
                      },
                      child: Image.memory(
                        work.image as Uint8List,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                /// ✅ 장소 (지도)
                if (place != null) ...[
                  Text(
                    '장소',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(place.lat, place.lng),
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                            userAgentPackageName:
                                'com.project1.todolist',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(place.lat, place.lng),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.place,
                                  color: Colors.red,
                                  size: 36,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (place.name != null && place.name!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(place.name!),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],

                /// ✅ 하위 항목
                if (details.isNotEmpty) ...[
                  Text(
                    '하위 항목',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...details.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            e.checked == 1
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(e.content)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}