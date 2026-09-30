import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/models/my_tutorials.dart';
import 'package:gobuddy/utils/my_colors.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class MyTutorialsScreen extends StatefulWidget {
  const MyTutorialsScreen({super.key});

  @override
  State<MyTutorialsScreen> createState() => _MyTutorialsScreenState();
}

class _MyTutorialsScreenState extends State<MyTutorialsScreen> {
  GetTutorialsModel? tutorialsModel;
  bool isLoading = true;
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    _getTutorials();
  }

  Future<void> _getTutorials() async {
    if (!await UtilClass.checkInternet()) {
      UtilClass.showAlertDialog(
        context: context,
        message: "No Internet Connection",
      );
      return;
    }

    try {
      final response = await Dio().get(
        'https://dev.gobuddyindia.com/api/tutorial',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      final jsonResponse = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      tutorialsModel = GetTutorialsModel.fromJson(jsonResponse);
    } catch (e) {
      UtilClass.showAlertDialog(context: context, message: e.toString());
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutorials", style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.appThemeLight,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tutorialsModel!.tutorials.length,
              itemBuilder: (context, index) {
                final tutorial = tutorialsModel!.tutorials[index];
                final isOpen = expandedIndex == index;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Thumbnail + Overlay
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            expandedIndex = isOpen ? null : index;
                          });
                        },
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Image.asset(
                                'assets/images/gb.png',
                                height: 190,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              )
                           
                            ),
                            Positioned.fill(
                              child: Container(
                                alignment: Alignment.center,
                                color: Colors.black.withOpacity(0.25),
                                child: Icon(
                                  isOpen
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 Title Row (Green Tick)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tutorial.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                     

                      // 🔹 Description
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          tutorial.description,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 🔹 Inline Video Player
                      if (isOpen)
                        UniversalVideoPlayer(
                          videoUrl: tutorial.videoLink,
                        ),

                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
    );
  }
}



class UniversalVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const UniversalVideoPlayer({super.key, required this.videoUrl});

  @override
  State<UniversalVideoPlayer> createState() => _UniversalVideoPlayerState();
}

class _UniversalVideoPlayerState extends State<UniversalVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  String _formatVideoUrl(String raw) {
    raw = raw.trim();
    if (raw.isEmpty) return "";
    if (raw.startsWith("http://") || raw.startsWith("https://")) {
      return raw;
    }
    return "https://www.youtube.com/watch?v=$raw";
  }

  bool _isExternalOrYouTubeUrl(String url) {
    final lower = url.toLowerCase().trim();
    return lower.contains("youtube.com") ||
        lower.contains("youtu.be") ||
        (!lower.endsWith(".mp4") && !lower.endsWith(".m3u8") && !lower.endsWith(".webm") && !lower.endsWith(".mov"));
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    if (_isExternalOrYouTubeUrl(widget.videoUrl)) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    try {
      _controller = VideoPlayerController.network(widget.videoUrl)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _controller?.play();
          }
        }).catchError((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });

      _controller?.addListener(() {
        if (mounted) setState(() {});
      });
    } catch (_) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _time(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:"
      "${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final formattedUrl = _formatVideoUrl(widget.videoUrl);

    if (_hasError || _isExternalOrYouTubeUrl(widget.videoUrl)) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            const Icon(Icons.play_circle_outline, color: Colors.green, size: 48),
            const SizedBox(height: 8),
            const Text(
              "Watch this tutorial",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              formattedUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final uri = Uri.tryParse(formattedUrl);
                if (uri != null) {
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint("Error opening tutorial video: $e");
                  }
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text("Play Video"),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 10),
            Text("Loading video...", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    final controller = _controller!;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              if (!controller.value.isPlaying)
                GestureDetector(
                  onTap: () => setState(() => controller.play()),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
            ],
          ),
        ),

        // 🔹 Progress Bar
        Slider(
          min: 0,
          max: controller.value.duration.inMilliseconds.toDouble(),
          value: controller.value.position.inMilliseconds
              .clamp(0, controller.value.duration.inMilliseconds)
              .toDouble(),
          onChanged: (v) =>
              controller.seekTo(Duration(milliseconds: v.toInt())),
        ),

        // 🔹 Time Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_time(controller.value.position)),
              Text(_time(controller.value.duration)),
            ],
          ),
        ),
      ],
    );
  }
}
