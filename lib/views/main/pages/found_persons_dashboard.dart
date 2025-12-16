import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class FoundPersonsDashboard extends StatefulWidget {
  const FoundPersonsDashboard({super.key});

  @override
  State<FoundPersonsDashboard> createState() => _FoundPersonsDashboardState();
}

class _FoundPersonsDashboardState extends State<FoundPersonsDashboard> {
  // مراجع قاعدة البيانات
  final DatabaseReference _foundPersonsRef = FirebaseDatabase.instance.ref().child('FoundPersons');
  final DatabaseReference _reportsRef = FirebaseDatabase.instance.ref().child('Reports');
  
  // بيانات
  Map<dynamic, dynamic> _foundPersons = {};
  Map<dynamic, dynamic> _reports = {};
  bool _isLoading = true;
  
  // متغيرات البحث والفلترة
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all'; // all, active, resolved, pending
  String _selectedSort = 'newest'; // newest, oldest, name
  
  // ألوان التصميم
  final Color _primaryColor = Color(0xFF006400); // أخضر داكن
  final Color _accentColor = Color(0xFFCE1126); // أحمر
  final Color _backgroundColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF2E2E2E);
  final Color _hintColor = Color(0xFF6C757D);
  final Color _successColor = Color(0xFF28A745);
  final Color _warningColor = Color(0xFFFFC107);
  final Color _errorColor = Color(0xFFDC3545);
  final Color _infoColor = Color(0xFF17A2B8);

  // إحصائيات
  int _totalFoundPersons = 0;
  int _activeCases = 0;
  int _resolvedCases = 0;
  int _pendingVerification = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // تحميل البيانات الأولية
  Future<void> _loadData() async {
    try {
      final foundPersonsSnapshot = await _foundPersonsRef.once();
      final reportsSnapshot = await _reportsRef.once();

      setState(() {
        // إصلاح مشكلة النوع - تحويل Object إلى Map
        _foundPersons = _convertToMap(foundPersonsSnapshot.snapshot.value) ?? {};
        _reports = _convertToMap(reportsSnapshot.snapshot.value) ?? {};
        _isLoading = false;
      });
      
      _calculateStatistics();
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة مساعدة لتحويل Object إلى Map
  Map<dynamic, dynamic>? _convertToMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<dynamic, dynamic>) return value;
    return null;
  }

  // إعداد المستمعين في الوقت الحقيقي
  void _setupRealtimeListeners() {
    _foundPersonsRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _foundPersons = _convertToMap(event.snapshot.value) ?? {};
          _calculateStatistics();
        });
      }
    });
  }

  // حساب الإحصائيات
  void _calculateStatistics() {
    int total = 0;
    int active = 0;
    int resolved = 0;
    int pending = 0;

    if (_foundPersons is Map) {
      _foundPersons.forEach((userId, userFoundPersons) {
        if (userFoundPersons is Map) {
          userFoundPersons.forEach((foundId, foundData) {
            if (foundData is Map) {
              total++;
              final status = foundData['status']?.toString()?.toLowerCase() ?? 'active';
              
              switch (status) {
                case 'resolved':
                case 'مكتمل':
                  resolved++;
                  break;
                case 'pending':
                case 'قيد المراجعة':
                  pending++;
                  break;
                case 'active':
                case 'نشط':
                default:
                  active++;
              }
            }
          });
        }
      });
    }

    setState(() {
      _totalFoundPersons = total;
      _activeCases = active;
      _resolvedCases = resolved;
      _pendingVerification = pending;
    });
  }

  // الحصول على الأشخاص الموجودين المفلترين
  List<Map<String, dynamic>> _getFilteredFoundPersons() {
    List<Map<String, dynamic>> allFoundPersons = [];

    // تجميع جميع الأشخاص الموجودين
    if (_foundPersons is Map) {
      _foundPersons.forEach((userId, userFoundPersons) {
        if (userFoundPersons is Map) {
          userFoundPersons.forEach((foundId, foundData) {
            if (foundData is Map) {
              final foundPerson = Map<String, dynamic>.from(foundData);
              foundPerson['id'] = foundId.toString();
              foundPerson['userId'] = userId.toString();
              allFoundPersons.add(foundPerson);
            }
          });
        }
      });
    }

    // تطبيق الفلترة
    List<Map<String, dynamic>> filtered = allFoundPersons.where((person) {
      // فلترة الحالة
      if (_selectedFilter != 'all') {
        final status = person['status']?.toString()?.toLowerCase() ?? 'active';
        switch (_selectedFilter) {
          case 'active':
            if (status != 'active' && status != 'نشط') return false;
            break;
          case 'resolved':
            if (status != 'resolved' && status != 'مكتمل') return false;
            break;
          case 'pending':
            if (status != 'pending' && status != 'قيد المراجعة') return false;
            break;
        }
      }

      // فلترة البحث
      if (_searchController.text.isNotEmpty) {
        final searchText = _searchController.text.toLowerCase();
        final name = (person['name'] ?? '').toString().toLowerCase();
        final description = (person['description'] ?? '').toString().toLowerCase();
        final location = (person['locationName'] ?? '').toString().toLowerCase();
        final contact = (person['contact'] ?? '').toString().toLowerCase();

        if (!name.contains(searchText) &&
            !description.contains(searchText) &&
            !location.contains(searchText) &&
            !contact.contains(searchText)) {
          return false;
        }
      }

      return true;
    }).toList();

    // تطبيق الترتيب
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'newest':
          final dateA = a['reportedAt'] ?? 0;
          final dateB = b['reportedAt'] ?? 0;
          return dateB.compareTo(dateA);
        case 'oldest':
          final dateA = a['reportedAt'] ?? 0;
          final dateB = b['reportedAt'] ?? 0;
          return dateA.compareTo(dateB);
        case 'name':
          final nameA = (a['name'] ?? '').toString().toLowerCase();
          final nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        default:
          return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingView()
          : Column(
              children: [
                // إحصائيات سريعة
                _buildStatisticsRow(),
                
                // أدوات البحث والفلترة
                _buildSearchAndFilterBar(),
                
                // قائمة الأشخاص الموجودين
                Expanded(
                  child: _buildFoundPersonsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: _showAddFoundPersonDialog,
        child: Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  // بناء شريط التطبيق
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'لوحة إدارة الموجودين',
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Tajawal',
        ),
      ),
      backgroundColor: _cardColor,
      elevation: 2,
      iconTheme: IconThemeData(color: _primaryColor),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: 'تحديث البيانات',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            _handleAppBarAction(value);
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: _primaryColor),
                  SizedBox(width: 8),
                  Text('تصدير البيانات'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: _primaryColor),
                  SizedBox(width: 8),
                  Text('إعدادات الإدارة'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // بناء واجهة التحميل
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          SizedBox(height: 16),
          Text(
            'جاري تحميل البيانات...',
            style: TextStyle(
              fontSize: 16,
              color: _hintColor,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  // بناء صف الإحصائيات
  Widget _buildStatisticsRow() {
    return Container(
      padding: EdgeInsets.all(16),
      color: _cardColor,
      child: Row(
        children: [
          _buildStatCard('إجمالي الموجودين', _totalFoundPersons.toString(), _primaryColor, Icons.people),
          _buildStatCard('حالات نشطة', _activeCases.toString(), _infoColor, Icons.person_search),
          _buildStatCard('تم حلها', _resolvedCases.toString(), _successColor, Icons.check_circle),
          _buildStatCard('قيد المراجعة', _pendingVerification.toString(), _warningColor, Icons.schedule),
        ],
      ),
    );
  }

  // بناء بطاقة إحصائية
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Tajawal',
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // بناء شريط البحث والفلترة
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: _cardColor,
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم، الموقع، أو الوصف...',
              hintStyle: TextStyle(fontFamily: 'Tajawal'),
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          
          SizedBox(height: 12),
          
          // الفلترة والترتيب
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('جميع الحالات')),
                    DropdownMenuItem(value: 'active', child: Text('نشط')),
                    DropdownMenuItem(value: 'resolved', child: Text('تم الحل')),
                    DropdownMenuItem(value: 'pending', child: Text('قيد المراجعة')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'فلترة الحالة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSort,
                  items: [
                    DropdownMenuItem(value: 'newest', child: Text('الأحدث أولاً')),
                    DropdownMenuItem(value: 'oldest', child: Text('الأقدم أولاً')),
                    DropdownMenuItem(value: 'name', child: Text('حسب الاسم')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSort = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'ترتيب العرض',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء قائمة الأشخاص الموجودين
  Widget _buildFoundPersonsList() {
    final filteredFoundPersons = _getFilteredFoundPersons();
    
    if (filteredFoundPersons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 80, color: _hintColor),
            SizedBox(height: 16),
            Text(
              'لا توجد بيانات',
              style: TextStyle(
                fontSize: 18,
                color: _hintColor,
                fontFamily: 'Tajawal',
              ),
            ),
            Text(
              _searchController.text.isEmpty
                  ? 'لم يتم إضافة أي أشخاص موجودين بعد'
                  : 'لا توجد نتائج تطابق بحثك',
              style: TextStyle(
                fontSize: 14,
                color: _hintColor,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredFoundPersons.length,
      itemBuilder: (context, index) {
        final foundPerson = filteredFoundPersons[index];
        return _buildFoundPersonCard(foundPerson);
      },
    );
  }

  // بناء بطاقة الشخص الموجود
  Widget _buildFoundPersonCard(Map<String, dynamic> foundPerson) {
    final name = foundPerson['name'] ?? 'شخص مجهول';
    final location = foundPerson['locationName'] ?? foundPerson['location'] ?? 'موقع غير معروف';
    final dateFound = foundPerson['dateFound'] ?? 'تاريخ غير معروف';
    final status = foundPerson['status']?.toString()?.toLowerCase() ?? 'active';
    final description = foundPerson['description'] ?? '';
    final age = foundPerson['age'] ?? '';
    final contact = foundPerson['contact'] ?? '';
    final imageUrl = foundPerson['imageUrl'];
    
    // تحديد لون الحالة
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'resolved':
      case 'مكتمل':
        statusColor = _successColor;
        statusText = 'تم الحل';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
      case 'قيد المراجعة':
        statusColor = _warningColor;
        statusText = 'قيد المراجعة';
        statusIcon = Icons.schedule;
        break;
      case 'active':
      case 'نشط':
      default:
        statusColor = _infoColor;
        statusText = 'نشط';
        statusIcon = Icons.person_search;
    }
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              children: [
                // الصورة
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _hintColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person, color: _hintColor, size: 30),
                  ),
                
                SizedBox(width: 12),
                
                // المعلومات الأساسية
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 14,
                          color: _hintColor,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      if (age.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          'العمر: $age سنة',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hintColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // حالة التقرير
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // الوصف
            if (description.isNotEmpty)
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: _textColor,
                  fontFamily: 'Tajawal',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            
            SizedBox(height: 12),
            
            // المعلومات الإضافية
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: _hintColor),
                SizedBox(width: 4),
                Text(
                  'تم العثور: $dateFound',
                  style: TextStyle(
                    fontSize: 12,
                    color: _hintColor,
                    fontFamily: 'Tajawal',
                  ),
                ),
                
                Spacer(),
                
                if (contact.isNotEmpty) ...[
                  Icon(Icons.phone, size: 14, color: _hintColor),
                  SizedBox(width: 4),
                  Text(
                    contact,
                    style: TextStyle(
                      fontSize: 12,
                      color: _hintColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ],
            ),
            
            SizedBox(height: 12),
            
            // أزرار التحكم
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.remove_red_eye, size: 16),
                    label: Text('عرض التفاصيل'),
                    onPressed: () => _showFoundPersonDetails(foundPerson),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                
                SizedBox(width: 8),
                
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('تعديل'),
                    onPressed: () => _showEditFoundPersonDialog(foundPerson),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _warningColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                
                SizedBox(width: 8),
                
                IconButton(
                  icon: Icon(Icons.delete, color: _errorColor),
                  onPressed: () => _showDeleteConfirmation(foundPerson),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // معالجة إجراءات شريط التطبيق
  void _handleAppBarAction(String action) {
    switch (action) {
      case 'export':
        _exportData();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }

  // تصدير البيانات
  void _exportData() {
    // تنفيذ منطق تصدير البيانات
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري تصدير البيانات...'),
        backgroundColor: _infoColor,
      ),
    );
  }

  // إظهار إعدادات الإدارة
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إعدادات الإدارة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('الإشعارات'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: Icon(Icons.security),
              title: Text('صلاحيات المستخدمين'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.backup),
              title: Text('نسخ احتياطي'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // إظهار تفاصيل الشخص الموجود
  void _showFoundPersonDetails(Map<String, dynamic> foundPerson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تفاصيل الشخص الموجود'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (foundPerson['imageUrl'] != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(foundPerson['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              
              SizedBox(height: 16),
              
              _buildDetailRow('الاسم:', foundPerson['name'] ?? 'غير معروف'),
              _buildDetailRow('العمر:', foundPerson['age'] ?? 'غير معروف'),
              _buildDetailRow('موقع العثور:', foundPerson['locationName'] ?? foundPerson['location'] ?? 'غير معروف'),
              _buildDetailRow('تاريخ العثور:', foundPerson['dateFound'] ?? 'غير معروف'),
              _buildDetailRow('جهة الاتصال:', foundPerson['contact'] ?? 'غير معروف'),
              _buildDetailRow('الحالة:', _getStatusText(foundPerson['status'])),
              
              if (foundPerson['description'] != null) ...[
                SizedBox(height: 8),
                Text('الوصف:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(foundPerson['description']),
              ],
              
              SizedBox(height: 16),
              
              Text('معلومات الإبلاغ:', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildDetailRow('المبلغ:', foundPerson['reportedBy'] ?? 'غير معروف'),
              _buildDetailRow('تاريخ الإبلاغ:', _formatTimestamp(foundPerson['reportedAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () => _showEditFoundPersonDialog(foundPerson),
            child: Text('تعديل'),
          ),
        ],
      ),
    );
  }

  // بناء صف تفاصيل
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // الحصول على نص الحالة
  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
      case 'مكتمل':
        return 'تم الحل';
      case 'pending':
      case 'قيد المراجعة':
        return 'قيد المراجعة';
      case 'active':
      case 'نشط':
      default:
        return 'نشط';
    }
  }

  // تنسيق الطابع الزمني
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'غير معروف';
    
    try {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateFormat('yyyy/MM/dd - HH:mm').format(date);
      }
      return timestamp.toString();
    } catch (e) {
      return timestamp.toString();
    }
  }

  // إظهار حذف التأكيد
  void _showDeleteConfirmation(Map<String, dynamic> foundPerson) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف ${foundPerson['name'] ?? 'هذا الشخص'}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _errorColor),
            onPressed: () {
              Navigator.pop(context);
              _deleteFoundPerson(foundPerson);
            },
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  // حذف الشخص الموجود
  Future<void> _deleteFoundPerson(Map<String, dynamic> foundPerson) async {
    try {
      final userId = foundPerson['userId'];
      final foundId = foundPerson['id'];
      
      if (userId != null && foundId != null) {
        await _foundPersonsRef.child(userId).child(foundId).remove();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الشخص بنجاح'),
            backgroundColor: _successColor,
          ),
        );
      }
    } catch (e) {
      print('Error deleting found person: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحذف'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  // إظهار dialog إضافة شخص موجود
  void _showAddFoundPersonDialog() {
    showDialog(
      context: context,
      builder: (context) => FoundPersonFormDialog(
        onSave: _addFoundPerson,
      ),
    );
  }

  // إضافة شخص موجود
  Future<void> _addFoundPerson(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final foundPersonData = {
        ...data,
        'reportedBy': user.uid,
        'reportedAt': ServerValue.timestamp,
        'status': 'active',
      };

      await _foundPersonsRef.child(user.uid).push().set(foundPersonData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة الشخص بنجاح'),
          backgroundColor: _successColor,
        ),
      );
    } catch (e) {
      print('Error adding found person: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الإضافة'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  // إظهار dialog تعديل شخص موجود
  void _showEditFoundPersonDialog(Map<String, dynamic> foundPerson) {
    showDialog(
      context: context,
      builder: (context) => FoundPersonFormDialog(
        foundPerson: foundPerson,
        onSave: (data) => _updateFoundPerson(foundPerson, data),
      ),
    );
  }

  // تحديث الشخص الموجود
  Future<void> _updateFoundPerson(Map<String, dynamic> foundPerson, Map<String, dynamic> data) async {
    try {
      final userId = foundPerson['userId'];
      final foundId = foundPerson['id'];
      
      if (userId != null && foundId != null) {
        await _foundPersonsRef.child(userId).child(foundId).update(data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث البيانات بنجاح'),
            backgroundColor: _successColor,
          ),
        );
      }
    } catch (e) {
      print('Error updating found person: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التحديث'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }
}

// نموذج إدخال بيانات الشخص الموجود
class FoundPersonFormDialog extends StatefulWidget {
  final Map<String, dynamic>? foundPerson;
  final Function(Map<String, dynamic>) onSave;

  const FoundPersonFormDialog({
    super.key,
    this.foundPerson,
    required this.onSave,
  });

  @override
  State<FoundPersonFormDialog> createState() => _FoundPersonFormDialogState();
}

class _FoundPersonFormDialogState extends State<FoundPersonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  // عناصر التحكم
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  
  Uint8List? _imageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.foundPerson != null) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    final foundPerson = widget.foundPerson!;
    _nameController.text = foundPerson['name'] ?? '';
    _ageController.text = foundPerson['age'] ?? '';
    _locationController.text = foundPerson['locationName'] ?? foundPerson['location'] ?? '';
    _descriptionController.text = foundPerson['description'] ?? '';
    _contactController.text = foundPerson['contact'] ?? '';
    _statusController.text = foundPerson['status'] ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('found_persons')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putData(_imageBytes!);
      await uploadTask;
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrl = await _uploadImage();
      
      final data = {
        'name': _nameController.text,
        'age': _ageController.text,
        'location': _locationController.text,
        'locationName': _locationController.text,
        'description': _descriptionController.text,
        'contact': _contactController.text,
        'status': _statusController.text,
        'dateFound': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (widget.foundPerson == null) 'reportedAt': ServerValue.timestamp,
      };

      await widget.onSave(data);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error submitting form: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.foundPerson == null ? 'إضافة شخص موجود' : 'تعديل بيانات الشخص'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // صورة الشخص
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : widget.foundPerson?['imageUrl'] != null
                          ? Image.network(widget.foundPerson!['imageUrl'], fit: BoxFit.cover)
                          : Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                ),
              ),
              
              SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم الشخص',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسم الشخص';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 12),
              
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'العمر',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              
              SizedBox(height: 12),
              
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'موقع العثور',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال موقع العثور';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 12),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              
              SizedBox(height: 12),
              
              TextFormField(
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'جهة الاتصال',
                  border: OutlineInputBorder(),
                ),
              ),
              
              SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _statusController.text.isEmpty ? 'active' : _statusController.text,
                items: [
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'pending', child: Text('قيد المراجعة')),
                  DropdownMenuItem(value: 'resolved', child: Text('تم الحل')),
                ],
                onChanged: (value) {
                  _statusController.text = value!;
                },
                decoration: InputDecoration(
                  labelText: 'الحالة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitForm,
          child: _isLoading 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
              : Text(widget.foundPerson == null ? 'إضافة' : 'تحديث'),
        ),
      ],
    );
  }
}