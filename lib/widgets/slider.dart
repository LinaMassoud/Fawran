import 'dart:async';
import 'package:fawran/generated/app_localizations.dart';
import 'package:fawran/models/sliderItem.dart';
import 'package:fawran/route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Make sure to import routeObserver from where you defined it
// import 'path_to_route_observer.dart';

class MySliderWidget extends StatefulWidget {
  final AsyncValue<List<SliderItem>> sliderItemsAsync;
  final AppLocalizations loc;

  const MySliderWidget({
    Key? key,
    required this.sliderItemsAsync,
    required this.loc,
  }) : super(key: key);

  @override
  _MySliderWidgetState createState() => _MySliderWidgetState();
}

class _MySliderWidgetState extends State<MySliderWidget> with RouteAware {
  late PageController pageController;
  Timer? timer;
  final ValueNotifier<int> pageNotifier = ValueNotifier<int>(0);
  int currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    routeObserver.unsubscribe(this);
    pageController.dispose();
    pageNotifier.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Another screen pushed on top of this one — pause timer
    timer?.cancel();
  }

  @override
  void didPopNext() {
    // Back to this screen after popping the next — resume timer
    if (widget.sliderItemsAsync.asData != null) {
      startAutoSlide(widget.sliderItemsAsync.asData!.value.length);
    }
  }

  void startAutoSlide(int itemCount) {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;

      currentPage++;
      if (currentPage >= itemCount) currentPage = 0;

      pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      pageNotifier.value = currentPage;
    });
  }

  String getFullImageUrl(String imagePath) {
    String sanitizedPath = imagePath.replaceAll('\\', '/');
    String encodedPath = Uri.encodeFull(sanitizedPath);
    return "http://fawran.ddns.net:8080/$encodedPath";
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return widget.sliderItemsAsync.when(
      data: (items) {
        if (timer == null) {
          startAutoSlide(items.length);
        }
        return Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: 150,
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: items.length,
                    onPageChanged: (index) {
                      pageNotifier.value = index;
                      currentPage = index;
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final imageUrl = getFullImageUrl(item.imageUrl);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<int>(
                  valueListenable: pageNotifier,
                  builder: (context, value, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(items.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: value == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: value == index
                                ? Colors.blue.shade800
                                : Colors.blue.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
            Positioned(
              bottom: 40,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.loc.popular,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading slider: $e'),
    );
  }
}
