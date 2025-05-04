import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/Combo.dart';
import '../../providers/ComboProvider.dart';
import '../payment/PaymentSandboxScreen.dart';

class ComboSelectionScreen extends StatefulWidget {
  final int showtimeId;
  final String movieTitle;
  final double seatTotalAmount;
  final List<String> selectedSeats;
  final String sessionId;

  const ComboSelectionScreen({
    Key? key,
    required this.showtimeId,
    required this.movieTitle,
    required this.seatTotalAmount,
    required this.selectedSeats,
    required this.sessionId,
  }) : super(key: key);

  @override
  _ComboSelectionScreenState createState() => _ComboSelectionScreenState();
}

class _ComboSelectionScreenState extends State<ComboSelectionScreen> {
  final moneyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ComboProvider>(context, listen: false).loadCombos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Chọn combo', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ComboProvider>(
        builder: (context, comboProvider, _) {
          if (comboProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          if (comboProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'Không thể tải danh sách combo',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    comboProvider.errorMessage!,
                    style: TextStyle(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => comboProvider.loadCombos(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Thông tin phim và ghế đã chọn
              _buildBookingSummary(),
              
              // Danh sách combo
              Expanded(
                child: _buildComboList(comboProvider),
              ),
              
              // Thanh thanh toán
              _buildCheckoutBar(comboProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.movieTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event_seat, color: Colors.grey[400], size: 16),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Ghế: ${widget.selectedSeats.join(", ")}',
                  style: TextStyle(color: Colors.grey[400]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.attach_money, color: Colors.grey[400], size: 16),
              SizedBox(width: 4),
              Text(
                'Tổng tiền ghế: ${moneyFormat.format(widget.seatTotalAmount)}',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComboList(ComboProvider comboProvider) {
    // Có 4 danh mục: combo, popcorn, drink, snack
    final categories = {
      'combo': 'Combo',
      'popcorn': 'Bắp rang',
      'drink': 'Đồ uống',
      'snack': 'Đồ ăn nhẹ'
    };

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị combo theo từng danh mục
          ...categories.entries.map((entry) {
            final category = entry.key;
            final categoryName = entry.value;
            final combosInCategory = comboProvider.getCombosInCategory(category);
            
            if (combosInCategory.isEmpty) return SizedBox(); // Skip if no combos in this category
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                  child: Row(
                    children: [
                      _getCategoryIcon(category),
                      SizedBox(width: 8),
                      Text(
                        categoryName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ...combosInCategory.map((combo) => _buildComboItem(combo, comboProvider)).toList(),
                SizedBox(height: 16),
                Divider(color: Colors.grey[800], height: 1, indent: 16, endIndent: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Icon _getCategoryIcon(String category) {
    switch (category) {
      case 'combo': return Icon(Icons.fastfood, color: Colors.amber);
      case 'popcorn': return Icon(Icons.local_dining, color: Colors.amber);
      case 'drink': return Icon(Icons.local_drink, color: Colors.amber);
      case 'snack': return Icon(Icons.restaurant, color: Colors.amber);
      default: return Icon(Icons.menu_book, color: Colors.amber);
    }
  }

  Widget _buildComboItem(Combo combo, ComboProvider comboProvider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon category
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(combo.categoryIcon, color: Colors.amber),
            ),
            SizedBox(width: 16),
            
            // Combo info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    combo.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    combo.description,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    moneyFormat.format(combo.price),
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity controls
            Column(
              children: [
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onTap: combo.quantity > 0 
                          ? () => comboProvider.decrementCombo(combo)
                          : null,
                      color: combo.quantity > 0 ? Colors.amber : Colors.grey[700]!,
                    ),
                    SizedBox(width: 12),
                    Text(
                      '${combo.quantity}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onTap: () => comboProvider.incrementCombo(combo),
                      color: Colors.amber,
                    ),
                  ],
                ),
                if (combo.quantity > 0) ...[
                  SizedBox(height: 8),
                  Text(
                    moneyFormat.format(combo.totalPrice),
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          color: Colors.black,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(ComboProvider comboProvider) {
    final totalComboAmount = comboProvider.totalAmount;
    final grandTotal = widget.seatTotalAmount + totalComboAmount;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (comboProvider.selectedCombos.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tiền ghế:',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          moneyFormat.format(widget.seatTotalAmount),
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tiền combo:',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          moneyFormat.format(totalComboAmount),
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey[800], height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng thanh toán:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          moneyFormat.format(grandTotal),
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],
            
            Row(
              children: [
                // Bỏ qua combo
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Chuyển đến màn hình thanh toán mà không có combo
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SandboxPaymentScreen(
                            bookingId: widget.showtimeId,
                            totalAmount: widget.seatTotalAmount,
                            movieTitle: widget.movieTitle,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Bỏ qua'),
                  ),
                ),
                SizedBox(width: 16),
                
                // Tiếp tục với combo đã chọn
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      // Chuyển đến màn hình thanh toán với combo đã chọn
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SandboxPaymentScreen(
                            bookingId: widget.showtimeId, // Sử dụng showtimeId tạm thời làm bookingId
                            totalAmount: grandTotal,
                            movieTitle: widget.movieTitle,
                          ),
                        ),
                      );
                      
                      // Lưu thông tin combo đã chọn nếu có
                      if (comboProvider.selectedCombos.isNotEmpty) {
                        comboProvider.saveSelectedCombos(widget.showtimeId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Tiếp tục thanh toán',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}