import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:videx/pages/result_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VideoPlayerController? _controller;
  File? _videoFile;
  bool isLoading = false; // To track the loading state
  Map<String, dynamic>? _matchResult;

  // Pick video from FilePicker
  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        final videoFile = File(filePath);

        // Temporarily initialize a controller to check duration
        VideoPlayerController tempController =
            VideoPlayerController.file(videoFile);
        await tempController.initialize();
        Duration videoDuration = tempController.value.duration;

        // Modify the duration check to ensure it's between 10 and 30 seconds
        if (videoDuration.inSeconds < 10 || videoDuration.inSeconds > 30) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please select a video between 10 and 30 seconds.',
              ),
            ),
          );
          tempController.dispose();
        } else {
          setState(() {
            _videoFile = videoFile;
            isLoading = true;
            _matchResult = null;                // clear previous result
            _controller = VideoPlayerController.file(videoFile)
              ..initialize().then((_) => setState(() {}));
          });
          // wait for the match call to finish before updating UI
          await matchClip(videoFile);

        }
      }
    }
  }

  // Remove the selected video
  void _removeVideo() {
    setState(() {
      _videoFile = null;
      _controller?.dispose();
      _controller = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a gradient background
      body: Stack(
        children: [
          // Gradient behind everything
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top section with the circular design + app name
                Expanded(
                  flex: 3, // adjust the flex to control height ratio
                  child: Container(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 100, // Adjust size as you like
                      backgroundColor: Colors.white.withOpacity(0.1),
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black26],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'VidEx',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom / video section
                Expanded(
                  flex: 4,
                  // Wrap this bottom area with a SingleChildScrollView
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          _buildVideoArea(),
                          const SizedBox(height: 24),
                          // Action buttons (Pick Video, Remove Video)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickVideo,
                                icon: const Icon(Icons.video_call),
                                label: const Text('Pick Video'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple.shade500,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed:
                                    (_videoFile == null) ? null : _removeVideo,
                                icon: const Icon(Icons.delete),
                                label: const Text('Remove Video'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                            
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_videoFile == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('No video selected', style: TextStyle(fontSize: 16)),
      );
    }
    if (_controller != null && _controller!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VideoPlayer(_controller!),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // Function to match the clip against stored movie embeddings
  Future<void> matchClip(File videoFile) async {
    final uri = Uri.parse('http://192.168.1.7:8000/match_clip/');
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', videoFile.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var data = json.decode(responseData);

    // 1) Update the loading state and save result
    setState(() {
      isLoading = false;
      if (response.statusCode == 200 && data['status'] == 'success') {
        _matchResult = data['data'];
      } else {
        _matchResult = null;
      }
    });

    // 2) If we got a match, navigate to the ResultPage
    if (_matchResult != null) {
      // ignore: use_build_context_synchronously
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultPage(result: _matchResult!),
        ),
      );
      // 3) When the user returns, reset everything
      setState(() {
        _videoFile = null;
        _controller?.dispose();
        _controller = null;
        _matchResult = null;
        isLoading = false;
      });
    }
  }
}

class VideoControls extends StatelessWidget {
  final VideoPlayerController controller;

  const VideoControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      height: 50.0,
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              controller.value.isPlaying
                  ? controller.pause()
                  : controller.play();
            },
          ),
        ],
      ),
    );
  }
}