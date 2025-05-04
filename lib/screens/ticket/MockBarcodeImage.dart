import 'package:flutter/material.dart';

class MockBarcodeImage extends StatelessWidget {
  final String code;
  final double height;
  
  const MockBarcodeImage({
    Key? key, 
    required this.code,
    this.height = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(maxWidth: 300),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildBarcodeLines(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBarcodeLines() {
    List<Widget> lines = [];
    
    // Chuyển mã code thành số nhị phân giả
    final binaryData = _generateBinaryFromString(code);
    
    // Giới hạn số lượng thanh để tránh tràn
    final maxLines = 100; // Giới hạn số lượng thanh
    final dataToShow = binaryData.length > maxLines ? binaryData.substring(0, maxLines) : binaryData;
    
    // Tạo các dòng barcode dựa trên dữ liệu nhị phân
    for (int i = 0; i < dataToShow.length; i++) {
      lines.add(Container(
        width: 2,
        color: dataToShow[i] == '1' ? Colors.black : Colors.white,
      ));
    }
    
    return lines;
  }

  String _generateBinaryFromString(String input) {
    // Đây là một thuật toán đơn giản để tạo mã barcode giả
    String result = '';
    
    // Giới hạn độ dài input để tránh tạo quá nhiều bit
    final limitedInput = input.length > 8 ? input.substring(0, 8) : input;
    
    for (int i = 0; i < limitedInput.length; i++) {
      final char = limitedInput.codeUnitAt(i);
      final binary = char.toRadixString(2).padLeft(8, '0');
      result += binary;
    }
    
    // Chỉ thêm vào số bit hợp lý
    return result.padRight(100, '1010');
  }
}
