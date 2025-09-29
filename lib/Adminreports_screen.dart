import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Dummy Data
class Bin {
  String id;
  String company;
  bool isFull;
  Bin({required this.id, required this.company, required this.isFull});
}

class Sweeper {
  String name;
  int tasksCompleted;
  int tasksAssigned;
  Sweeper(
      {required this.name,
      required this.tasksCompleted,
      required this.tasksAssigned});
}

class Company {
  String name;
  int binsHandled;
  Company({required this.name, required this.binsHandled});
}

class Alert {
  String message;
  Alert({required this.message});
}

// Sample Data
List<Bin> bins = [
  Bin(id: 'B1', company: 'Evergreen', isFull: true),
  Bin(id: 'B2', company: 'UBIT', isFull: false),
  Bin(id: 'B3', company: 'Evergreen', isFull: true),
];

List<Sweeper> sweepers = [
  Sweeper(name: 'Mome', tasksCompleted: 10, tasksAssigned: 10),
  Sweeper(name: 'salman', tasksCompleted: 8, tasksAssigned: 10),
];

List<Company> companies = [
  Company(name: 'Evergreen', binsHandled: 15),
  Company(name: 'UBIT', binsHandled: 12),
];

List<Alert> alerts = [
  Alert(message: 'Area Jail expected overflow tomorrow'),
  Alert(message: 'Area Downtown bin full tomorrow'),
];

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int totalBins = bins.length;
    int totalSweepers = sweepers.length;
    int totalCompanies = companies.length;
    int totalAlerts = alerts.length;

    String textSummary = "Today: $totalBins bins monitored. "
        "$totalAlerts alerts generated. "
        "Top company: ${companies[0].name} handled ${companies[0].binsHandled} bins. "
        "Top sweeper: ${sweepers[0].name} completed ${sweepers[0].tasksCompleted}/${sweepers[0].tasksAssigned} tasks.";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryCard("Bins", totalBins),
              _summaryCard("Sweepers", totalSweepers),
              _summaryCard("Companies", totalCompanies),
              _summaryCard("Alerts", totalAlerts),
            ],
          ),
          const SizedBox(height: 20),
          // Text Summary
          const Text("AI Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(textSummary),
          const SizedBox(height: 20),
          // Charts Section
          const Text("Bins Distribution by Company",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 200, child: BinsPieChart()),

          const SizedBox(height: 20),
          const Text("Sweeper Performance",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 200, child: SweeperBarChart()),

          const SizedBox(height: 20),
          // Predicted Alerts
          const Text("Predicted Alerts",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...alerts.map((a) => Text("- ${a.message}")).toList(),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, int value) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 80,
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value.toString(),
                style: const TextStyle(fontSize: 20, color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}

// Pie Chart for Bins per Company
class BinsPieChart extends StatelessWidget {
  const BinsPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    final dataMap = <String, double>{};
    for (var c in companies) {
      double binsCount =
          bins.where((b) => b.company == c.name).length.toDouble();
      dataMap[c.name] = binsCount;
    }

    List<PieChartSectionData> sections = [];
    int i = 0;
    dataMap.forEach((company, value) {
      sections.add(PieChartSectionData(
        value: value,
        title: "$company\n${value.toInt()}",
        color: i == 0 ? Colors.blue : Colors.orange,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
      ));
      i++;
    });

    return PieChart(PieChartData(
      sections: sections,
      centerSpaceRadius: 20,
      sectionsSpace: 2,
    ));
  }
}

// Bar Chart for Sweeper Performance
class SweeperBarChart extends StatelessWidget {
  const SweeperBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: 10,
        barGroups: sweepers
            .asMap()
            .entries
            .map((entry) => BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.tasksCompleted.toDouble(),
                      color: Colors.green,
                      width: 15,
                      borderRadius: BorderRadius.circular(2),
                    )
                  ],
                ))
            .toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < sweepers.length) {
                  return Text(sweepers[index].name,
                      style: const TextStyle(fontSize: 12));
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fl_chart/fl_chart.dart';

// class AdminReportsScreen extends StatefulWidget {
//   const AdminReportsScreen({super.key});

//   @override
//   State<AdminReportsScreen> createState() => _AdminReportsScreenState();
// }

// class _AdminReportsScreenState extends State<AdminReportsScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Admin Reports",
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),

//           // 🔹 Summary Cards
//           StreamBuilder<QuerySnapshot>(
//             stream: _firestore.collection("bins").snapshots(),
//             builder: (context, binSnapshot) {
//               if (!binSnapshot.hasData) {
//                 return const CircularProgressIndicator();
//               }

//               int totalBins = binSnapshot.data!.docs.length;
//               int fullBins = binSnapshot.data!.docs
//                   .where((doc) => doc['status'] == 'full')
//                   .length;

//               return Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _summaryCard("Total Bins", totalBins.toString(), Colors.blue),
//                   _summaryCard("Full Bins", fullBins.toString(), Colors.red),
//                 ],
//               );
//             },
//           ),
//           const SizedBox(height: 20),

//           // 🔹 Bar Chart: Bins per Company
//           const Text(
//             "Bins per Company",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           SizedBox(
//             height: 200,
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection("bins").snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return const CircularProgressIndicator();

//                 // Count bins per company
//                 Map<String, int> companyBins = {};
//                 for (var doc in snapshot.data!.docs) {
//                   String company = doc['company'] ?? "Unknown";
//                   companyBins[company] = (companyBins[company] ?? 0) + 1;
//                 }

//                 List<BarChartGroupData> barGroups = [];
//                 int x = 0;
//                 companyBins.forEach((company, count) {
//                   barGroups.add(BarChartGroupData(
//                     x: x,
//                     barRods: [
//                       BarChartRodData(
//                         toY: count.toDouble(),
//                         color: Colors.blue,
//                         width: 18,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ],
//                   ));
//                   x++;
//                 });

//                 return BarChart(
//                   BarChartData(
//                     barGroups: barGroups,
//                     titlesData: FlTitlesData(
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           getTitlesWidget: (value, meta) {
//                             String company =
//                                 companyBins.keys.elementAt(value.toInt());
//                             return Text(company, style: const TextStyle(fontSize: 10));
//                           },
//                         ),
//                       ),
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(showTitles: true),
//                       ),
//                     ),
//                     borderData: FlBorderData(show: false),
//                   ),
//                 );
//               },
//             ),
//           ),

//           const SizedBox(height: 20),

//           // 🔹 Pie Chart: Full vs Empty Bins
//           const Text(
//             "Bin Status Distribution",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           SizedBox(
//             height: 200,
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection("bins").snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return const CircularProgressIndicator();

//                 int full = snapshot.data!.docs
//                     .where((doc) => doc['status'] == 'full')
//                     .length;
//                 int empty = snapshot.data!.docs
//                     .where((doc) => doc['status'] == 'empty')
//                     .length;

//                 return PieChart(
//                   PieChartData(
//                     sections: [
//                       PieChartSectionData(
//                         value: full.toDouble(),
//                         color: Colors.red,
//                         title: "Full $full",
//                         radius: 60,
//                         titleStyle: const TextStyle(
//                             fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
//                       ),
//                       PieChartSectionData(
//                         value: empty.toDouble(),
//                         color: Colors.green,
//                         title: "Empty $empty",
//                         radius: 60,
//                         titleStyle: const TextStyle(
//                             fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _summaryCard(String title, String value, Color color) {
//     return Container(
//       width: 160,
//       height: 80,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.85),
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(color: Colors.white, fontSize: 14),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             value,
//             style: const TextStyle(
//                 color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }
// }
