import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _videos = [];

  static const String _apiKey = 'AIzaSyDtKhO_76CbjfriyC1iDjH-mKmrkNpTleE';

  Future<void> _searchSongs(String query) async {
    final Uri url = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search'
      '?part=snippet&type=video&maxResults=10&q=${Uri.encodeComponent('$query song')}&key=$_apiKey',
    );

    try {
      final response = await http.get(url);
      debugPrint('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'];

        final validVideos = items
            .where((item) =>
                item['id'] != null &&
                item['id']['videoId'] != null &&
                item['snippet'] != null)
            .toList();

        setState(() {
          _videos = validVideos;
        });
      } else {
        debugPrint('Error: ${response.body}');
        throw Exception('Failed to fetch songs');
      }
    } catch (e) {
      debugPrint('API call error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load songs')),
      );
    }
  }

  void _playVideo(String videoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubeVideoPlayer(videoId: videoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Songs'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _searchSongs(value.trim());
                }
              },
              decoration: InputDecoration(
                labelText: 'Search a song',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final query = _searchController.text.trim();
                    if (query.isNotEmpty) {
                      _searchSongs(query);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _videos.isEmpty
                ? const Center(child: Text('No songs found'))
                : ListView.builder(
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      final videoId = video['id']['videoId'];
                      final title = video['snippet']['title'];
                      final thumbnail =
                          video['snippet']['thumbnails']['default']['url'];

                      return ListTile(
                        leading: Image.network(thumbnail),
                        title: Text(title),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => _playVideo(videoId),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class YouTubeVideoPlayer extends StatefulWidget {
  final String videoId;

  const YouTubeVideoPlayer({super.key, required this.videoId});

  @override
  State<YouTubeVideoPlayer> createState() => _YouTubeVideoPlayerState();
}

class _YouTubeVideoPlayerState extends State<YouTubeVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    // Optional: print current player state
    _controller.addListener(() {
      debugPrint("Player state: ${_controller.value.playerState}");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playing Song'),
        backgroundColor: Colors.deepPurple,
      ),
      body: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.deepPurple,
      ),
    );
  }
}
