import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/portal_provider.dart';
import '../models/grade.dart';

class GradebookScreen extends StatefulWidget {
  const GradebookScreen({super.key});

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PortalProvider>(context, listen: false).refreshAll();
    });
  }

  void _showAddExamDialog(BuildContext context) {
    final examController = TextEditingController();
    final subjectController = TextEditingController();
    final maxMarksController = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF12131A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: Color(0xFF262938)),
        ),
        title: Text(
          'Initialize Scoresheet',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: examController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Exam Name (e.g. Unit Test 1)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: subjectController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Subject (e.g. Mathematics)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: maxMarksController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Maximum Marks'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid number' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              final provider = Provider.of<PortalProvider>(context, listen: false);
              final examName = examController.text.trim();
              final subject = subjectController.text.trim();
              final maxMarks = double.parse(maxMarksController.text);

              Navigator.pop(context); // close dialog

              // Initialize scoresheets by posting placeholders for each student
              bool success = true;
              provider.clearError();
              
              for (var student in provider.students) {
                final ok = await provider.addGrade(
                  studentId: student.id,
                  examName: examName,
                  subject: subject,
                  marksObtained: 0.0, // Initial default marks
                  maxMarks: maxMarks,
                  remarks: 'Initialized',
                );
                if (!ok) success = false;
              }

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Initialized scoresheet for $examName ($subject)!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
                // Open scoresheet directly
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExamScoresheetView(examName: examName, subject: subject),
                  ),
                );
              }
            },
            child: Text('Create', style: GoogleFonts.outfit(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF1A1C26),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF262938)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF6366F1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    
    // Group unique exam + subjects
    final Map<String, List<Grade>> groupedExams = {};
    for (var grade in provider.grades) {
      final key = "${grade.examName} (${grade.subject})";
      if (!groupedExams.containsKey(key)) {
        groupedExams[key] = [];
      }
      groupedExams[key]!.add(grade);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12131A),
        title: Text(
          'Gradebook',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: groupedExams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.book_outlined, size: 64, color: Color(0xFF262938)),
                  const SizedBox(height: 16),
                  Text(
                    'No scoresheets conducts initialized yet',
                    style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddExamDialog(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                    child: Text('Create First Scoresheet', style: GoogleFonts.outfit(color: Colors.white)),
                  )
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: groupedExams.keys.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final key = groupedExams.keys.elementAt(index);
                final examGrades = groupedExams[key]!;
                final firstGrade = examGrades[0];
                
                // Calculate average percentage
                double sum = 0.0;
                for (var g in examGrades) {
                  sum += g.percentage;
                }
                final avg = examGrades.isNotEmpty ? sum / examGrades.length : 0.0;

                return Card(
                  color: const Color(0xFF12131A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF262938)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    title: Text(
                      firstGrade.examName,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      'Subject: ${firstGrade.subject}  |  Marks: Out of ${firstGrade.maxMarks.round()}',
                      style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 13),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Avg: ${avg.round()}%',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExamScoresheetView(
                            examName: firstGrade.examName,
                            subject: firstGrade.subject,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExamDialog(context),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.playlist_add, color: Colors.white),
      ),
    );
  }
}

// Inner view for entering scores
class ExamScoresheetView extends StatefulWidget {
  final String examName;
  final String subject;

  const ExamScoresheetView({
    super.key,
    required this.examName,
    required this.subject,
  });

  @override
  State<ExamScoresheetView> createState() => _ExamScoresheetViewState();
}

class _ExamScoresheetViewState extends State<ExamScoresheetView> {
  Map<int, TextEditingController> _marksControllers = {};
  Map<int, TextEditingController> _remarksControllers = {};
  double _maxMarks = 100.0;
  bool _initialized = false;

  @override
  void dispose() {
    for (var c in _marksControllers.values) {
      c.dispose();
    }
    for (var c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFields() {
    final provider = Provider.of<PortalProvider>(context, listen: false);
    final examGrades = provider.grades.where(
      (g) => g.examName == widget.examName && g.subject == widget.subject,
    ).toList();

    _marksControllers.clear();
    _remarksControllers.clear();

    if (examGrades.isNotEmpty) {
      _maxMarks = examGrades[0].maxMarks;
    }

    for (var grade in examGrades) {
      _marksControllers[grade.student] = TextEditingController(text: grade.marksObtained.toString());
      _remarksControllers[grade.student] = TextEditingController(text: grade.remarks ?? '');
    }
    _initialized = true;
  }

  void _save() async {
    final provider = Provider.of<PortalProvider>(context, listen: false);
    final examGrades = provider.grades.where(
      (g) => g.examName == widget.examName && g.subject == widget.subject,
    ).toList();

    bool success = true;
    provider.clearError();

    for (var grade in examGrades) {
      final marksStr = _marksControllers[grade.student]?.text ?? '0';
      final rem = _remarksControllers[grade.student]?.text.trim() ?? '';
      final marks = double.tryParse(marksStr) ?? 0.0;

      final ok = await provider.addGrade(
        studentId: grade.student,
        examName: widget.examName,
        subject: widget.subject,
        marksObtained: marks,
        maxMarks: _maxMarks,
        remarks: rem,
      );
      if (!ok) success = false;
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examination scores saved successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save scoresheets'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortalProvider>(context);
    
    final examGrades = provider.grades.where(
      (g) => g.examName == widget.examName && g.subject == widget.subject,
    ).toList();

    if (!_initialized && examGrades.isNotEmpty) {
      _initFields();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12131A),
        title: Text(
          '${widget.examName} - ${widget.subject}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF6366F1)),
            onPressed: examGrades.isEmpty ? null : _save,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF12131A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maximum Marks Limit:',
                  style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 14),
                ),
                Container(
                  width: 80,
                  alignment: Alignment.centerRight,
                  child: TextFormField(
                    initialValue: _maxMarks.round().toString(),
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.all(6),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF262938))),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setState(() {
                          _maxMarks = parsed;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: examGrades.isEmpty
                ? const Center(child: Text('No student records found in scoresheet', style: TextStyle(color: Colors.white)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: examGrades.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final grade = examGrades[index];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12131A),
                          border: Border.all(color: const Color(0xFF262938)),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        grade.studentName,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Roll No: ${grade.studentRoll}',
                                        style: GoogleFonts.outfit(color: const Color(0xFF9CA3AF), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Marks input box
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _marksControllers[grade.student],
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    textAlign: TextAlign.center,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      suffixText: '/${_maxMarks.round()}',
                                      suffixStyle: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      filled: true,
                                      fillColor: const Color(0xFF1A1C26),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF262938)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            
                            // Score remarks input field
                            TextField(
                              controller: _remarksControllers[grade.student],
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Remarks (e.g. Excellent work!)',
                                hintStyle: GoogleFonts.outfit(color: const Color(0xFF6B7280), fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                filled: true,
                                fillColor: const Color(0xFF1A1C26),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF262938)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: examGrades.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xFF12131A),
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Save Scoresheet Marks',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
    );
  }
}
