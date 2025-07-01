import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:sworld_flutter/page/zoom_app.dart/zoom_api.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

class ZoomScreen extends StatefulWidget {
  static var routeName = '/zoom';

  const ZoomScreen({super.key});

  @override
  State<ZoomScreen> createState() => _ZoomManagerState();
}

class _ZoomManagerState extends State<ZoomScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> meetings = [];
  bool isLoading = false;
  bool isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _fetchMeetings();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (_showFab) {
          _showFab = false;
          _animationController.reverse();
        }
      } else if (_scrollController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (!_showFab) {
          _showFab = true;
          _animationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMeetings() async {
    if (!mounted) return;

    setState(() => isLoading = true);
    try {
      final data = await ZoomApiService.listMeetings();
      if (!mounted) return;
      setState(() {
        meetings = data['meetings'] ?? [];
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching meetings: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openAuthUrl() async {
    try {
      final url = await ZoomApiService.getAuthUrl();
      await FlutterWebBrowser.openWebPage(
          url: url,
          customTabsOptions: const CustomTabsOptions(
            colorScheme: CustomTabsColorScheme.dark,
            toolbarColor: Color(0xFF2D8CFF),
          ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error opening auth URL: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createMeeting() async {
    try {
      final meeting =
          await ZoomApiService.createMeeting(topic: "Flutter Meeting");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Meeting Created: ${meeting['id']}"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _fetchMeetings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error creating meeting: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _joinMeeting(String joinUrl) async {
    try {
      await FlutterWebBrowser.openWebPage(
          url: joinUrl,
          customTabsOptions: const CustomTabsOptions(
            colorScheme: CustomTabsColorScheme.dark,
            toolbarColor: Color(0xFF2D8CFF),
            // Removed unsupported safariVCOptions parameter
          ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error joining meeting: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateMeeting(String meetingId) async {
    try {
      await ZoomApiService.updateMeeting(
          meetingId, {"topic": "Updated by Flutter"});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Meeting updated"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _fetchMeetings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating meeting: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMeeting(String meetingId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Meeting"),
        content: const Text("Are you sure you want to delete this meeting?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await ZoomApiService.deleteMeeting(meetingId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Meeting deleted"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _fetchMeetings();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting meeting: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMeetingCard(dynamic meeting) {
    final startTime = meeting['start_time'] != null
        ? DateFormat('MMM dd, yyyy - hh:mm a')
            .format(DateTime.parse(meeting['start_time']))
        : 'Not scheduled';
    final duration = meeting['duration']?.toString() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMeetingDetails(meeting),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D8CFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/zoom_icon.svg',
                      width: 24,
                      height: 24,
                      color: const Color(0xFF2D8CFF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      meeting['topic'] ?? 'No topic',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.access_time, startTime),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.timer, '$duration minutes'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.videocam,
                    label: 'Join',
                    color: const Color(0xFF2D8CFF),
                    onPressed: () => _joinMeeting(meeting['join_url']),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    color: Colors.grey,
                    onPressed: () => _updateMeeting(meeting['id'].toString()),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    color: Colors.red,
                    onPressed: () => _deleteMeeting(meeting['id'].toString()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _showMeetingDetails(dynamic meeting) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              meeting['topic'] ?? 'No topic',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                        'Meeting ID', meeting['id']?.toString() ?? 'N/A'),
                    _buildDetailItem(
                        'Start Time',
                        meeting['start_time'] != null
                            ? DateFormat.yMMMMd()
                                .add_jm()
                                .format(DateTime.parse(meeting['start_time']))
                            : 'Not scheduled'),
                    _buildDetailItem('Duration',
                        '${meeting['duration']?.toString() ?? 'N/A'} minutes'),
                    _buildDetailItem(
                        'Type', meeting['type']?.toString() ?? 'N/A'),
                    _buildDetailItem(
                        'Status', meeting['status']?.toString() ?? 'N/A'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D8CFF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _joinMeeting(meeting['join_url']),
                        child: const Text(
                          'Join Meeting',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            height: 160,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }


Future<void> _showCreateMeetingDialog() async {
  final meeting = await ZoomApiService.createMeeting(topic: "New Meeting");
  if (!mounted) return;

  // Extract meeting details
  final joinUrl = meeting['join_url'] ?? '';
  final meetingId = meeting['id'] ?? '';
  final password = meeting['password'] ?? '';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Meeting Created"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCopyableField("Meeting URL", joinUrl),
          const SizedBox(height: 12),
          _buildCopyableField("Meeting ID", meetingId.toString()),
          const SizedBox(height: 12),
          _buildCopyableField("Password", password),
          const SizedBox(height: 16),
          const Text(
            "Share these details with participants",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D8CFF),
          ),
          onPressed: () => _joinMeeting(joinUrl),
          child: const Text("Join Now"),
        ),
      ],
    ),
  );
  _fetchMeetings();
}

Widget _buildCopyableField(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$label copied to clipboard"),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.copy, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Zoom Meetings",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 0,


        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isRefreshing = true);
              _fetchMeetings();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMeetings,
        child: isLoading && meetings.isEmpty
            ? _buildShimmerLoading()
            : meetings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/zoom_empty.svg',
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "No meetings scheduled",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _createMeeting,
                          child: const Text("Create your first meeting"),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: meetings.length,
                    itemBuilder: (context, index) =>
                        _buildMeetingCard(meetings[index]),
                  ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showCreateMeetingDialog,
          backgroundColor: const Color(0xFF2D8CFF),
          icon: const Icon(Icons.video_call),
          label: const Text("New Meeting"),
          elevation: 4,
        ),
      ),
    );
  }
}
