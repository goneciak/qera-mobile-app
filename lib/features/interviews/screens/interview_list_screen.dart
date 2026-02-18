import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/interview_model.dart';
import '../providers/interviews_provider.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/offline_providers.dart';
import '../../../core/providers/providers.dart';

class InterviewListScreen extends ConsumerStatefulWidget {
  const InterviewListScreen({super.key});

  @override
  ConsumerState<InterviewListScreen> createState() => _InterviewListScreenState();
}

class _InterviewListScreenState extends ConsumerState<InterviewListScreen> {
  String _searchQuery = '';
  String? _statusFilter;
  DateTimeRange? _dateRange;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InterviewModel> _filterInterviews(List<InterviewModel> interviews) {
    var filtered = interviews;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((interview) {
        final query = _searchQuery.toLowerCase();
        
        // Search in town
        final town = interview.town?.toLowerCase() ?? '';
        
        // Search in owner data
        final ownerData = interview.ownerData ?? {};
        final firstName = ownerData['firstName']?.toString().toLowerCase() ?? '';
        final lastName = ownerData['lastName']?.toString().toLowerCase() ?? '';
        
        // Search in building address
        final address = interview.buildingAddress ?? {};
        final street = address['street']?.toString().toLowerCase() ?? '';
        final city = address['city']?.toString().toLowerCase() ?? '';
        
        return town.contains(query) ||
               firstName.contains(query) ||
               lastName.contains(query) ||
               street.contains(query) ||
               city.contains(query);
      }).toList();
    }

    // Status filter
    if (_statusFilter != null) {
      filtered = filtered.where((i) => i.status == _statusFilter).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((interview) {
        if (interview.visitDate == null) return false;
        return interview.visitDate!.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               interview.visitDate!.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _statusFilter = null;
      _dateRange = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final interviewState = ref.watch(interviewsProvider);
    final filteredInterviews = _filterInterviews(interviewState.interviews);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wywiady'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(interviewsProvider.notifier).fetchInterviews();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (!isOnline) const OfflineBanner(),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Szukaj po miejscowości, nazwisku, adresie...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Filters row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Status filter
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Wszystkie')),
                      DropdownMenuItem(value: 'DRAFT', child: Text('Szkic')),
                      DropdownMenuItem(value: 'SUBMITTED', child: Text('Wysłany')),
                      DropdownMenuItem(value: 'APPROVED', child: Text('Zatwierdzony')),
                      DropdownMenuItem(value: 'REJECTED', child: Text('Odrzucony')),
                      DropdownMenuItem(value: 'PDF_SENT', child: Text('PDF wysłany')),
                      DropdownMenuItem(value: 'SIGNED_AUTENTI', child: Text('Podpisano (e-sign)')),
                      DropdownMenuItem(value: 'SIGNED_MANUAL_UPLOAD', child: Text('Podpisano (skan)')),
                    ],
                    onChanged: (value) {
                      setState(() => _statusFilter = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                
                // Date range button
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 20),
                  label: Text(_dateRange == null ? 'Daty' : 'Zakres'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
                
                // Clear filters
                if (_searchQuery.isNotEmpty || _statusFilter != null || _dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off),
                    onPressed: _clearFilters,
                    tooltip: 'Wyczyść filtry',
                  ),
              ],
            ),
          ),

          // Active filters chips
          if (_statusFilter != null || _dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_statusFilter != null)
                    Chip(
                      label: Text('Status: $_statusFilter'),
                      onDeleted: () => setState(() => _statusFilter = null),
                    ),
                  if (_dateRange != null)
                    Chip(
                      label: Text(
                        'Daty: ${DateFormat('dd.MM').format(_dateRange!.start)} - ${DateFormat('dd.MM').format(_dateRange!.end)}',
                      ),
                      onDeleted: () => setState(() => _dateRange = null),
                    ),
                ],
              ),
            ),

          // Interview list
          Expanded(
            child: interviewState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : interviewState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Błąd: ${interviewState.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                ref.read(interviewsProvider.notifier).fetchInterviews();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Spróbuj ponownie'),
                            ),
                          ],
                        ),
                      )
                    : filteredInterviews.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  interviewState.interviews.isEmpty
                                      ? 'Brak wywiadów'
                                      : 'Brak wyników dla wybranych filtrów',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  interviewState.interviews.isEmpty
                                      ? 'Kliknij przycisk + aby utworzyć nowy'
                                      : 'Spróbuj zmienić filtry',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(interviewsProvider.notifier).fetchInterviews(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: filteredInterviews.length,
                              itemBuilder: (context, index) {
                                final interview = filteredInterviews[index];
                                return _buildInterviewCard(context, interview);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/interviews/create');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nowy wywiad'),
      ),
    );
  }

  Widget _buildInterviewCard(BuildContext context, InterviewModel interview) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    // Extract data from InterviewModel
    final ownerData = interview.ownerData ?? {};
    final firstName = ownerData['firstName']?.toString() ?? '';
    final lastName = ownerData['lastName']?.toString() ?? '';
    final ownerName = '$firstName $lastName'.trim();
    
    final address = interview.buildingAddress ?? {};
    final city = address['city']?.toString() ?? '';
    
    final displayLocation = interview.town ?? (city.isNotEmpty ? city : 'Brak miejscowości');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          context.push('/interviews/${interview.id}');
        },
        onLongPress: () => _showInterviewMenu(context, interview),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayLocation,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Use InterviewStatusBadge from common_widgets
                  InterviewStatusBadge(
                    status: interview.status,
                    compact: true,
                  ),
                ],
              ),
              if (ownerName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      ownerName,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              if (interview.visitDate != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Wizyta: ${dateFormat.format(interview.visitDate!)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Utworzono: ${dateFormat.format(interview.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInterviewMenu(BuildContext context, InterviewModel interview) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.blue),
              title: const Text('Duplikuj wywiad'),
              subtitle: const Text('Utwórz kopię jako szkic'),
              onTap: () {
                Navigator.pop(context);
                _duplicateInterview(interview);
              },
            ),
            if (interview.status == 'DRAFT')
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Usuń wywiad'),
                subtitle: const Text('Tylko szkice można usunąć'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteInterview(interview);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _duplicateInterview(InterviewModel interview) async {
    final ownerData = interview.ownerData ?? {};
    final displayName = interview.town ?? 
                       ownerData['firstName']?.toString() ?? 
                       'brak miejscowości';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplikuj wywiad'),
        content: Text(
          'Czy chcesz utworzyć kopię wywiadu dla: $displayName?\n\n'
          'Kopia zostanie utworzona jako szkic.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duplikuj'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final service = ref.read(interviewServiceProvider);
        final duplicated = await service.duplicateInterview(interview.id);
        
        if (mounted) {
          ref.read(interviewsProvider.notifier).fetchInterviews();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wywiad został zduplikowany jako szkic'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to duplicated interview
          context.push('/interviews/${duplicated.id}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd duplikacji: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteInterview(InterviewModel interview) async {
    final ownerData = interview.ownerData ?? {};
    final displayName = interview.town ?? 
                       ownerData['firstName']?.toString() ?? 
                       'brak miejscowości';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń wywiad'),
        content: Text(
          'Czy na pewno chcesz usunąć wywiad dla: $displayName?\n\n'
          'Ta operacja jest nieodwracalna.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final service = ref.read(interviewServiceProvider);
        await service.deleteInterview(interview.id);
        
        if (mounted) {
          ref.read(interviewsProvider.notifier).fetchInterviews();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wywiad został usunięty'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd usuwania: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
