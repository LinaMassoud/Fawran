import 'package:fawran/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fawran/providers/localProvider.dart';
import 'package:fawran/generated/app_localizations.dart';

class FAQPage extends ConsumerStatefulWidget {
  const FAQPage({Key? key}) : super(key: key);

  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends ConsumerState<FAQPage> {
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
    final loc = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeNotifierProvider);
    final isArabic = currentLocale.languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
                Icons.arrow_back_ios,
                color: Color(0xFFFFA200),
                size: 20,
              ),
            ),
          ),
          title: Text(
            loc.faq, // Use localized text instead of hardcoded 'FAQ'
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
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  loc.noFaqsAvailable, // Use localized text
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
              );
            }

            // Use filtered FAQs if search is active, otherwise use all FAQs
            final faqs = _searchController.text.isNotEmpty ? _filteredFaqs : snapshot.data!;
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFE6EFFF),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Color(0xFFD8DBDB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Search icon with proper alignment
                        Align(
                          alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            child: SvgPicture.asset(
                              'assets/icons/search.svg',
                              width: 20,
                              height: 20,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        // Expanded TextField
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterFAQs,
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(
                              hintText: loc.searchFaqs,
                              hintStyle: TextStyle(
                                color: const Color(0xFF768090),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isArabic ? 5 : 5,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Common Questions Section
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        loc.commonQuestions, // Use localized text
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF091735),
                        ),
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ),
                  ),
                  
                  // FAQ List
                  if (faqs.isEmpty && _searchController.text.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          loc.noFaqsFoundMatching, // Use localized text
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                              tilePadding: EdgeInsets.symmetric(
                                horizontal: isArabic ? 0 : 4,
                                vertical: 6,
                              ).copyWith(
                                left: isArabic ? 4 : 4,
                                right: isArabic ? 4 : 4,
                              ),
                              childrenPadding: EdgeInsets.zero,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _expandedIndex = expanded ? index : null;
                                });
                              },
                              title: Align(
                                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                child: Text(
                                  faq['question'],
                                  style: TextStyle(
                                    fontWeight: isExpanded ? FontWeight.w500 : FontWeight.w400,
                                    fontSize: 16,
                                    color: Color(0xFF091735),
                                  ),
                                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                ),
                              ),
                              trailing: Transform.rotate(
                                angle: isArabic ? 3.14159 : 0, // 180 degrees for RTL
                                child: Icon(
                                  isExpanded 
                                    ? Icons.keyboard_arrow_down 
                                    : Icons.keyboard_arrow_right,
                                  color: Colors.grey[600],
                                  size: 24,
                                ),
                              ),
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.fromLTRB(
                                    isArabic ? 4 : 4,
                                    0,
                                    isArabic ? 4 : 4,
                                    16,
                                  ),
                                  child: Align(
                                    alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                                    child: Text(
                                      faq['answer'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF768090),
                                        height: 1.4,
                                      ),
                                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
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
      ),
    );
  }
}