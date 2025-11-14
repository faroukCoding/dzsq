import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'models.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final orders = appState.orders;
    final users = appState.users;
    final products = appState.products;
    final payouts = appState.payouts;

    final totalRevenue = orders
        .where((order) => order.status == 'delivered')
        .fold(0.0, (sum, order) => sum + order.productPrice);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        body: Column(
          children: [
            // Stats Grid
            _buildStatsGrid(orders.length, users.length, totalRevenue, products.length),
            SizedBox(height: 20),
            // Tabs
            Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A2E).withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TabBar(
                isScrollable: true,
                indicator: BoxDecoration(
                  color: Color(0xFF00ADB5),
                  borderRadius: BorderRadius.circular(10),
                ),
                tabs: [
                  _buildTab('جميع الطلبات'),
                  _buildTab('المنتجات'),
                  _buildTab('المستخدمين'),
                  _buildTab('طلبات السحب'),
                  _buildTab('التقارير'),
                  _buildTab('الإشعارات'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAllOrdersTab(orders),
                  _buildProductsTab(products),
                  _buildUsersTab(users),
                  _buildPayoutsTab(payouts),
                  _buildReportsTab(orders, users, products),
                  _buildNotificationsTab(appState.notifications),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildStatsGrid(int totalOrders, int totalUsers, double totalRevenue, int totalProducts) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      padding: EdgeInsets.all(20),
      children: [
        _buildStatCard('📦', '$totalOrders', 'إجمالي الطلبات'),
        _buildStatCard('👥', '$totalUsers', 'المستخدمين'),
        _buildStatCard('💵', '${totalRevenue.toStringAsFixed(2)} ريال', 'إجمالي الإيرادات'),
        _buildStatCard('🛍️', '$totalProducts', 'المنتجات'),
      ],
    );
  }

  Widget _buildStatCard(String icon, String value, String label) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E).withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFF00ADB5).withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: TextStyle(fontSize: 24)),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00ADB5),
            ),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text) {
    return Tab(
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildAllOrdersTab(List<Order> orders) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          if (orders.isEmpty)
            _buildEmptyState('📦', 'لا توجد طلبات')
          else
            ...orders.map((order) => _buildAdminOrderItem(order)).toList(),
        ],
      ),
    );
  }

  Widget _buildAdminOrderItem(Order order) {
    final user = Provider.of<AppState>(context).users
        .firstWhere((user) => user.id == order.userId, orElse: () => User(
          id: 'unknown',
          name: 'مستخدم غير معروف',
          email: '',
          role: '',
          phone: '',
        ));

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF16213E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border(right: BorderSide(color: Color(0xFF00ADB5), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'طلب #${order.id.substring(0, 8)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00ADB5),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'بواسطة: ${user.name}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor(order.status)),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildDetailItem('اسم الزبون', order.customerName),
              _buildDetailItem('رقم الهاتف', order.customerPhone),
              _buildDetailItem('المنتج', order.productName),
              _buildDetailItem('السعر', '${order.productPrice} ريال'),
              _buildDetailItem('العمولة', '${order.commission} ريال'),
              _buildDetailItem('التاريخ', _formatDate(order.createdAt)),
            ],
          ),
          SizedBox(height: 10),
          if (order.notes != null && order.notes!.isNotEmpty)
            _buildDetailItem('ملاحظات', order.notes!),
        ],
      ),
    );
  }

  Widget _buildProductsTab(List<Product> products) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          if (products.isEmpty)
            _buildEmptyState('🛍️', 'لا توجد منتجات')
          else
            ...products.map((product) => _buildProductItem(product)).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF16213E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border(right: BorderSide(color: Color(0xFF00ADB5), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00ADB5),
                  fontSize: 18,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: product.status == 'active' 
                    ? Color(0xFF27AE60).withOpacity(0.2)
                    : Color(0xFF95A5A6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: product.status == 'active' 
                      ? Color(0xFF27AE60)
                      : Color(0xFF95A5A6)
                  ),
                ),
                child: Text(
                  product.status == 'active' ? 'نشط' : 'غير نشط',
                  style: TextStyle(
                    color: product.status == 'active' 
                      ? Color(0xFF27AE60)
                      : Color(0xFF95A5A6),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildDetailItem('السعر', '${product.price} ريال'),
              _buildDetailItem('العمولة', '${product.commission} ريال'),
              _buildDetailItem('الفئة', product.category ?? 'غير محدد'),
              _buildDetailItem('تاريخ الإضافة', _formatDate(product.createdAt)),
            ],
          ),
          if (product.description != null && product.description!.isNotEmpty)
            SizedBox(height: 10),
            _buildDetailItem('الوصف', product.description!),
          SizedBox(height: 15),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  _toggleProductStatus(product);
                },
                style: ElevatedButton.styleFrom(
                  primary: product.status == 'active' ? Color(0xFFE74C3C) : Color(0xFF27AE60),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  product.status == 'active' ? '❌ تعطيل' : '✅ تفعيل',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  _editProduct(product);
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF3498DB),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  '✏️ تعديل',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(List<User> users) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          if (users.isEmpty)
            _buildEmptyState('👥', 'لا يوجد مستخدمين')
          else
            ...users.map((user) => _buildUserItem(user)).toList(),
        ],
      ),
    );
  }

  Widget _buildUserItem(User user) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF16213E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border(right: BorderSide(color: Color(0xFF00ADB5), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00ADB5),
                  fontSize: 18,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF27AE60).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF27AE60)),
                ),
                child: Text(
                  _getRoleText(user.role),
                  style: TextStyle(
                    color: Color(0xFF27AE60),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildDetailItem('البريد الإلكتروني', user.email),
              _buildDetailItem('رقم الهاتف', user.phone),
              _buildDetailItem('الدور', _getRoleText(user.role)),
              _buildDetailItem('تاريخ التسجيل', _formatDate(user.createdAt)),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  _toggleUserStatus(user);
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFFE74C3C),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  '❌ حذف',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutsTab(List<Payout> payouts) {
    final pendingPayouts = payouts.where((p) => p.payoutStatus == 'pending').toList();
    final processedPayouts = payouts.where((p) => p.payoutStatus != 'pending').toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(5),
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A2E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Color(0xFF00ADB5),
                borderRadius: BorderRadius.circular(10),
              ),
              tabs: [
                Tab(text: 'طلبات معلقة (${pendingPayouts.length})'),
                Tab(text: 'تم معالجتها (${processedPayouts.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPayoutsList(pendingPayouts, true),
                _buildPayoutsList(processedPayouts, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutsList(List<Payout> payouts, bool showActions) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          if (payouts.isEmpty)
            _buildEmptyState('💰', 'لا توجد طلبات سحب')
          else
            ...payouts.map((payout) => _buildPayoutItem(payout, showActions)).toList(),
        ],
      ),
    );
  }

  Widget _buildPayoutItem(Payout payout, bool showActions) {
    final user = Provider.of<AppState>(context).users
        .firstWhere((user) => user.id == payout.userId, orElse: () => User(
          id: 'unknown',
          name: 'مستخدم غير معروف',
          email: '',
          role: '',
          phone: '',
        ));

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF16213E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border(right: BorderSide(color: Color(0xFF00ADB5), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طلب سحب من ${user.name}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00ADB5),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: _getPayoutStatusColor(payout.payoutStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getPayoutStatusColor(payout.payoutStatus)),
                ),
                child: Text(
                  _getPayoutStatusText(payout.payoutStatus),
                  style: TextStyle(
                    color: _getPayoutStatusColor(payout.payoutStatus),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildDetailItem('المبلغ', '${payout.amount} ريال'),
              _buildDetailItem('تاريخ الطلب', _formatDate(payout.createdAt)),
              if (payout.adminNotes != null && payout.adminNotes!.isNotEmpty)
                _buildDetailItem('ملاحظات المدير', payout.adminNotes!),
            ],
          ),
          if (showActions)
            SizedBox(height: 15),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _approvePayout(payout.id);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF27AE60),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text('✅ موافقة'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _rejectPayout(payout.id);
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFFE74C3C),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text('❌ رفض'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildReportsTab(List<Order> orders, List<User> users, List<Product> products) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Report Filters
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A2E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'month',
                    decoration: InputDecoration(
                      labelText: 'الفترة الزمنية',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    items: [
                      DropdownMenuItem(value: 'day', child: Text('اليوم')),
                      DropdownMenuItem(value: 'week', child: Text('الأسبوع')),
                      DropdownMenuItem(value: 'month', child: Text('الشهر')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _exportReports,
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF6C7B7F),
                  ),
                  child: Text('📊 تصدير التقارير'),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Charts Grid
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildChartContainer('الطلبات حسب الحالة', _buildOrdersStatusChart(orders)),
              _buildChartContainer('أفضل المسوّقين', _buildTopAffiliatesChart(orders, users)),
              _buildChartContainer('العمولات الشهرية', _buildMonthlyCommissionsChart(orders)),
              _buildChartContainer('المنتجات الأكثر مبيعاً', _buildTopProductsChart(orders)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF16213E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF00ADB5).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Color(0xFF00ADB5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildOrdersStatusChart(List<Order> orders) {
    final statusCounts = {
      'pending': orders.where((o) => o.status == 'pending').length,
      'confirmed': orders.where((o) => o.status == 'confirmed').length,
      'delivered': orders.where((o) => o.status == 'delivered').length,
      'rejected': orders.where((o) => o.status == 'rejected').length,
    };

    return CustomPaint(
      // Implement custom chart painting
      size: Size(200, 150),
      painter: _OrdersStatusChartPainter(statusCounts),
    );
  }

  Widget _buildTopAffiliatesChart(List<Order> orders, List<User> users) {
    // Implementation for top affiliates chart
    return Container(
      child: Text('رسم بياني لأفضل المسوّقين', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildMonthlyCommissionsChart(List<Order> orders) {
    // Implementation for monthly commissions chart
    return Container(
      child: Text('رسم بياني للعمولات الشهرية', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildTopProductsChart(List<Order> orders) {
    // Implementation for top products chart
    return Container(
      child: Text('رسم بياني للمنتجات الأكثر مبيعاً', style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildNotificationsTab(List<Notification> notifications) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          if (notifications.isEmpty)
            _buildEmptyState('📢', 'لا توجد إشعارات')
          else
            ...notifications.map((notification) => _buildNotificationItem(notification)).toList(),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Notification notification) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF16213E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border(right: BorderSide(
          color: _getPriorityColor(notification.priority), 
          width: 4
        )),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                notification.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00ADB5),
                  fontSize: 18,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: _getPriorityColor(notification.priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getPriorityColor(notification.priority)),
                ),
                child: Text(
                  _getPriorityText(notification.priority),
                  style: TextStyle(
                    color: _getPriorityColor(notification.priority),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildDetailItem('الرسالة', notification.message),
              _buildDetailItem('المستهدفين', _getTargetText(notification.target)),
              _buildDetailItem('المرسل', notification.senderName),
              _buildDetailItem('تاريخ الإرسال', _formatDate(notification.createdAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _showFloatingActionMenu();
      },
      backgroundColor: Color(0xFF00ADB5),
      child: Icon(Icons.add),
    );
  }

  void _showFloatingActionMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.add_shopping_cart, color: Color(0xFF00ADB5)),
                title: Text('إضافة منتج جديد'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddProductModal();
                },
              ),
              ListTile(
                leading: Icon(Icons.person_add, color: Color(0xFF00ADB5)),
                title: Text('إضافة مستخدم جديد'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddUserModal();
                },
              ),
              ListTile(
                leading: Icon(Icons.notifications, color: Color(0xFF00ADB5)),
                title: Text('إرسال إشعار جديد'),
                onTap: () {
                  Navigator.pop(context);
                  _showSendNotificationModal();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods for status colors and texts
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Color(0xFFF1C40F);
      case 'confirmed': return Color(0xFF27AE60);
      case 'rejected': return Color(0xFFE74C3C);
      case 'delivered': return Color(0xFF00ADB5);
      default: return Color(0xFFF1C40F);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'معلق';
      case 'confirmed': return 'مؤكد';
      case 'rejected': return 'مرفوض';
      case 'delivered': return 'تم التسليم';
      default: return 'غير معروف';
    }
  }

  Color _getPayoutStatusColor(String status) {
    switch (status) {
      case 'pending': return Color(0xFFF1C40F);
      case 'approved': return Color(0xFF27AE60);
      case 'rejected': return Color(0xFFE74C3C);
      default: return Color(0xFFF1C40F);
    }
  }

  String _getPayoutStatusText(String status) {
    switch (status) {
      case 'pending': return 'في الانتظار';
      case 'approved': return 'تم التسليم';
      case 'rejected': return 'مرفوض';
      default: return 'غير معروف';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'normal': return Color(0xFF3498DB);
      case 'high': return Color(0xFFF1C40F);
      case 'urgent': return Color(0xFFE74C3C);
      default: return Color(0xFF3498DB);
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'normal': return 'عادية';
      case 'high': return 'عالية';
      case 'urgent': return 'عاجلة';
      default: return 'عادية';
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'affiliate': return 'مسوّق';
      case 'admin': return 'مدير';
      case 'assistant_admin': return 'مساعد إداري';
      case 'call_center': return 'مؤكد الطلبات';
      case 'driver': return 'سائق';
      default: return 'غير معروف';
    }
  }

  String _getTargetText(String target) {
    switch (target) {
      case 'all': return 'جميع المستخدمين';
      case 'affiliate': return 'المسوّقين';
      case 'call_center': return 'مؤكدي الطلبات';
      case 'driver': return 'السائقين';
      case 'assistant_admin': return 'المساعدين الإداريين';
      default: return 'غير محدد';
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String icon, String text) {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: 48)),
          SizedBox(height: 20),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Action methods
  void _toggleProductStatus(Product product) {
    // Implement product status toggle
  }

  void _editProduct(Product product) {
    // Implement product editing
  }

  void _toggleUserStatus(User user) {
    // Implement user status toggle
  }

  void _approvePayout(String payoutId) {
    // Implement payout approval
  }

  void _rejectPayout(String payoutId) {
    // Implement payout rejection
  }

  void _exportReports() {
    // Implement report export
  }

  void _showAddProductModal() {
    // Show add product modal
  }

  void _showAddUserModal() {
    // Show add user modal
  }

  void _showSendNotificationModal() {
    // Show send notification modal
  }
}

// Custom painter for charts
class _OrdersStatusChartPainter extends CustomPainter {
  final Map<String, int> statusCounts;

  _OrdersStatusChartPainter(this.statusCounts);

  @override
  void paint(Canvas canvas, Size size) {
    // Implement chart painting logic
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
