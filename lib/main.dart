import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/inventory_provider.dart';
import 'screens/history_page.dart';
import 'screens/inventory_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ต้อง initialize ข้อมูลวันที่ของ locale 'th' ก่อนใช้ DateFormat(..., 'th')
  // ไม่งั้นหน้าประวัติจะ throw LocaleDataException
  await initializeDateFormatting('th');
  runApp(const WaterWorldApp());
}

class WaterWorldApp extends StatelessWidget {
  const WaterWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider ต้องอยู่เหนือ MaterialApp เพื่อให้ทุก route ที่ push ใหม่เข้าถึงได้
    return ChangeNotifierProvider(
      create: (_) => InventoryProvider()..refresh(),
      child: MaterialApp(
        title: 'ร้านน้ำดื่ม',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF0288D1),
        ),
        home: const _Shell(),
      ),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [InventoryPage(), HistoryPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.warehouse_outlined),
              selectedIcon: Icon(Icons.warehouse),
              label: 'คลังสินค้า'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'ประวัติสต็อก'),
        ],
      ),
    );
  }
}
