import 'package:flutter/material.dart';

class DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final Function(String) onChanged;
  final bool isEnabled;

  const DropdownField({
    Key? key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isEnabled) ...[
                SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: onChanged,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  itemBuilder: (context) => options.map((option) => 
                    PopupMenuItem<String>(
                      value: option,
                      child: Text(option),
                    )
                  ).toList(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}