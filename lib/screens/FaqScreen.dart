import 'package:fawran/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  late Future<List<dynamic>> _faqFuture;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allFaqs = [];
  List<dynamic> _filteredFaqs = [];
  int? _expandedIndex; // Track which FAQ is expanded

  @override
  void initState() {
    super.initState();
    _faqFuture = ApiService.fetchFAQs();
    _loadFAQs();
  }

  void _loadFAQs() async {
    try {
      final faqs = await ApiService.fetchFAQs();
      setState(() {
        _allFaqs = faqs;
        _filteredFaqs = faqs;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _filterFAQs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = _allFaqs;
      } else {
        _filteredFaqs = _allFaqs.where((faq) {
          final question = faq['question'].toString().toLowerCase();
          final answer = faq['answer'].toString().toLowerCase();
          return question.contains(query.toLowerCase()) || 
                 answer.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 65,
        backgroundColor: Color(0xFF10295C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: EdgeInsets.all(8),
            child: Icon(
              isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: Color(0xFFFFA200),
              size: 20,
            ),
          ),
        ),
        title: Text(
          'FAQ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFA200),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _faqFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10295C)),
            ));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No FAQs available.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          // Use filtered FAQs if search is active, otherwise use all FAQs
          final faqs = _searchController.text.isNotEmpty ? _filteredFaqs : snapshot.data!;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFE6EFFF),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                    color: Color(0xFFD8DBDB), // Adding the border color
                    width: 1,
                  ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterFAQs,
                    decoration: InputDecoration(
                      hintText: 'Search FAQs',
                      hintStyle: TextStyle(
                        color: const Color(0xFF768090),
                        fontSize: 16,
                      ),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(15),
                        child: SvgPicture.asset(
                          'assets/icons/search.svg',
                          width: 20,
                          height: 20,
                          color: Colors.grey[500],
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                
                // Common Questions Section
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Common Questions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF091735),
                    ),
                  ),
                ),
                
                // FAQ List
                if (faqs.isEmpty && _searchController.text.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No FAQs found matching your search.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: faqs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final faq = faqs[index];
                      final isExpanded = _expandedIndex == index;
                      
                      return Container(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            childrenPadding: EdgeInsets.zero,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _expandedIndex = expanded ? index : null;
                              });
                            },
                            title: Text(
                              faq['question'],
                              style: TextStyle(
                                fontWeight: isExpanded ? FontWeight.w500 : FontWeight.w400,
                                fontSize: 16,
                                color: Color(0xFF091735),
                              ),
                            ),
                            trailing: Icon(
                              Icons.keyboard_arrow_right,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                                child: Text(
                                  faq['answer'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF768090),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}