from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import login as auth_login, logout as auth_logout, authenticate
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import AuthenticationForm
from django.db.models import Count, Q, Avg
from django.contrib import messages
from django.utils import timezone
from datetime import datetime, date

# REST Framework imports
from rest_framework import viewsets, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken

# Local imports
from .models import Student, Task, Attendance, Grade, BehaviorRemark, Notice
from .serializers import (
    StudentSerializer, TaskSerializer, UserSerializer,
    AttendanceSerializer, GradeSerializer, BehaviorRemarkSerializer, NoticeSerializer
)

# ==========================================
# REST API VIEWS FOR FLUTTER APP
# ==========================================

class CustomObtainAuthToken(ObtainAuthToken):
    permission_classes = [permissions.AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = self.serializer_class(data=request.data,
                                           context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.validated_data['user']
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': UserSerializer(user).data
        })


class StudentViewSet(viewsets.ModelViewSet):
    serializer_class = StudentSerializer

    def get_queryset(self):
        if self.request.user.is_superuser or self.request.user.is_staff:
            return Student.objects.all()
        return Student.objects.filter(teacher=self.request.user)

    def perform_create(self, serializer):
        serializer.save(teacher=self.request.user)


class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer

    def get_queryset(self):
        if self.request.user.is_superuser or self.request.user.is_staff:
            return Task.objects.all()
        return Task.objects.filter(student__teacher=self.request.user)

    def perform_create(self, serializer):
        student = serializer.validated_data['student']
        if not (self.request.user.is_superuser or self.request.user.is_staff) and student.teacher != self.request.user:
            return Response({"error": "Unauthorized student select"}, status=status.HTTP_401_UNAUTHORIZED)
        serializer.save()


class AttendanceViewSet(viewsets.ModelViewSet):
    serializer_class = AttendanceSerializer

    def get_queryset(self):
        if self.request.user.is_superuser or self.request.user.is_staff:
            return Attendance.objects.all()
        return Attendance.objects.filter(student__teacher=self.request.user)

    @action(detail=False, methods=['post'], url_path='batch')
    def save_batch(self, request):
        """Save/Update daily attendance registers in batch."""
        target_date_str = request.data.get('date')
        records = request.data.get('records', [])

        if not target_date_str or not records:
            return Response({"error": "Missing date or records list"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            target_date = datetime.strptime(target_date_str, "%Y-%m-%d").date()
        except ValueError:
            return Response({"error": "Invalid date format, use YYYY-MM-DD"}, status=status.HTTP_400_BAD_REQUEST)

        saved_records = []
        for rec in records:
            student_id = rec.get('student')
            status_val = rec.get('status')
            remarks = rec.get('remarks', '')

            try:
                if request.user.is_superuser or request.user.is_staff:
                    student = Student.objects.get(id=student_id)
                else:
                    student = Student.objects.get(id=student_id, teacher=request.user)
                
                attendance, created = Attendance.objects.update_or_create(
                    student=student,
                    date=target_date,
                    defaults={'status': status_val, 'remarks': remarks}
                )
                saved_records.append(AttendanceSerializer(attendance).data)
            except Student.DoesNotExist:
                continue # Skip invalid students

        return Response({
            "message": f"Successfully updated {len(saved_records)} attendance logs.",
            "records": saved_records
        }, status=status.HTTP_200_OK)


class GradeViewSet(viewsets.ModelViewSet):
    serializer_class = GradeSerializer

    def get_queryset(self):
        if self.request.user.is_superuser or self.request.user.is_staff:
            return Grade.objects.all()
        return Grade.objects.filter(student__teacher=self.request.user)

    def perform_create(self, serializer):
        student = serializer.validated_data['student']
        if not (self.request.user.is_superuser or self.request.user.is_staff) and student.teacher != self.request.user:
            return Response({"error": "Unauthorized student select"}, status=status.HTTP_401_UNAUTHORIZED)
        serializer.save()


class BehaviorRemarkViewSet(viewsets.ModelViewSet):
    serializer_class = BehaviorRemarkSerializer

    def get_queryset(self):
        if self.request.user.is_superuser or self.request.user.is_staff:
            return BehaviorRemark.objects.all()
        return BehaviorRemark.objects.filter(student__teacher=self.request.user)

    def perform_create(self, serializer):
        student = serializer.validated_data['student']
        if not (self.request.user.is_superuser or self.request.user.is_staff) and student.teacher != self.request.user:
            return Response({"error": "Unauthorized student select"}, status=status.HTTP_401_UNAUTHORIZED)
        serializer.save()


class NoticeViewSet(viewsets.ModelViewSet):
    serializer_class = NoticeSerializer

    def get_queryset(self):
        if self.request.user.is_superuser or self.request.user.is_staff:
            return Notice.objects.all()
        return Notice.objects.filter(teacher=self.request.user)

    def perform_create(self, serializer):
        serializer.save(teacher=self.request.user)


class ApiDashboardStatsView(APIView):
    def get(self, request):
        teacher = request.user
        if request.user.is_superuser or request.user.is_staff:
            students = Student.objects.all()
            tasks = Task.objects.all()
            notices = Notice.objects.all()
            remarks = BehaviorRemark.objects.all()
        else:
            students = Student.objects.filter(teacher=teacher)
            tasks = Task.objects.filter(student__teacher=teacher)
            notices = Notice.objects.filter(teacher=teacher)
            remarks = BehaviorRemark.objects.filter(student__teacher=teacher)

        total_students = students.count()
        total_tasks = tasks.count()
        completed_tasks = tasks.filter(status='COMPLETED').count()
        pending_tasks = tasks.filter(status='PENDING').count()

        # Calculate Average Attendance
        student_serialized = StudentSerializer(students, many=True).data
        avg_att = 100.0
        if total_students > 0:
            avg_att = sum(s['attendance_percentage'] for s in student_serialized) / total_students
        
        # Calculate Average Grade
        avg_grd = 0.0
        graded_students = [s['average_grade'] for s in student_serialized if s['average_grade'] > 0]
        if graded_students:
            avg_grd = sum(graded_students) / len(graded_students)

        # Recent notices
        recent_notices = NoticeSerializer(notices[:5], many=True).data
        # Recent remarks
        recent_remarks = BehaviorRemarkSerializer(remarks[:5], many=True).data

        return Response({
            'total_students': total_students,
            'total_tasks': total_tasks,
            'completed_tasks': completed_tasks,
            'pending_tasks': pending_tasks,
            'average_attendance': round(avg_att, 1),
            'average_grade': round(avg_grd, 1),
            'recent_notices': recent_notices,
            'recent_remarks': recent_remarks
        })


from django.contrib.auth.models import User
from .models import TeacherProfile, TeacherDocument
from .serializers import TeacherProfileSerializer, TeacherDocumentSerializer
from rest_framework.parsers import MultiPartParser, FormParser

class ChangePasswordView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        user = request.user
        old_password = request.data.get("old_password")
        new_password = request.data.get("new_password")

        if not old_password or not new_password:
            return Response({"error": "Both old_password and new_password are required."}, status=status.HTTP_400_BAD_REQUEST)

        if not user.check_password(old_password):
            return Response({"error": "Incorrect old password."}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()
        return Response({"message": "Password changed successfully."})


class UserProfileDocumentsView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get(self, request):
        profile, created = TeacherProfile.objects.get_or_create(user=request.user)
        documents = profile.documents.all()
        serializer = TeacherDocumentSerializer(documents, many=True)
        return Response(serializer.data)

    def post(self, request):
        profile, created = TeacherProfile.objects.get_or_create(user=request.user)
        file_obj = request.FILES.get('file')
        name = request.data.get('name')
        if not file_obj:
            return Response({"error": "No file uploaded."}, status=status.HTTP_400_BAD_REQUEST)
        if not name:
            name = file_obj.name
        doc = TeacherDocument.objects.create(profile=profile, file=file_obj, name=name)
        return Response(TeacherDocumentSerializer(doc).data, status=status.HTTP_201_CREATED)


class UserProfileDocumentDetailView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, pk):
        try:
            if request.user.is_superuser or request.user.is_staff:
                doc = TeacherDocument.objects.get(pk=pk)
            else:
                doc = TeacherDocument.objects.get(pk=pk, profile=request.user.profile)
            doc.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
        except TeacherDocument.DoesNotExist:
            return Response({"error": "Document not found."}, status=status.HTTP_404_NOT_FOUND)


class UserProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def put(self, request):
        profile, created = TeacherProfile.objects.get_or_create(user=request.user)
        user = request.user
        if 'first_name' in request.data:
            user.first_name = request.data['first_name']
        if 'last_name' in request.data:
            user.last_name = request.data['last_name']
        if 'email' in request.data:
            user.email = request.data['email']
        user.save()

        serializer = TeacherProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(UserSerializer(user).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class TeacherViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserSerializer

    def get_queryset(self):
        if self.request.user.is_superuser or self.request.user.is_staff:
            return User.objects.all().order_by('username')
        return User.objects.filter(id=self.request.user.id)

    def update(self, request, *args, **kwargs):
        if not (request.user.is_superuser or request.user.is_staff):
            return Response({"detail": "Only Super Admins can update other teachers."}, status=status.HTTP_403_FORBIDDEN)
        
        user = self.get_object()
        profile, created = TeacherProfile.objects.get_or_create(user=user)
        
        if 'first_name' in request.data:
            user.first_name = request.data['first_name']
        if 'last_name' in request.data:
            user.last_name = request.data['last_name']
        if 'email' in request.data:
            user.email = request.data['email']
        if 'password' in request.data and request.data['password']:
            user.set_password(request.data['password'])
        user.save()

        serializer = TeacherProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(UserSerializer(user).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



# ==========================================
# WEB PORTAL VIEWS (HTML)
# ==========================================

def web_login(request):
    if request.user.is_authenticated:
        return redirect('dashboard')
        
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            username = form.cleaned_data.get('username')
            password = form.cleaned_data.get('password')
            user = authenticate(username=username, password=password)
            if user is not None:
                auth_login(request, user)
                messages.success(request, f"Welcome back, {username}!")
                return redirect('dashboard')
            else:
                messages.error(request, "Invalid username or password.")
        else:
            messages.error(request, "Invalid username or password.")
    else:
        form = AuthenticationForm()
        
    return render(request, 'core/login.html', {'form': form})


def web_logout(request):
    auth_logout(request)
    messages.info(request, "You have been logged out successfully.")
    return redirect('login')


@login_required
def web_dashboard(request):
    teacher = request.user
    if request.user.is_superuser or request.user.is_staff:
        students = Student.objects.all()
        tasks = Task.objects.all()
        notices = Notice.objects.all()
        remarks = BehaviorRemark.objects.all()
    else:
        students = Student.objects.filter(teacher=teacher)
        tasks = Task.objects.filter(student__teacher=teacher)
        notices = Notice.objects.filter(teacher=teacher)
        remarks = BehaviorRemark.objects.filter(student__teacher=teacher)
    
    total_students = students.count()
    total_tasks = tasks.count()
    completed_tasks = tasks.filter(status='COMPLETED').count()
    pending_tasks = tasks.filter(status='PENDING').count()
    
    completion_rate = 0
    if total_tasks > 0:
        completion_rate = round((completed_tasks / total_tasks) * 100)
        
    # Calculate Attendance Rate & Grade Average
    student_stats = []
    total_att_sum = 0
    graded_count = 0
    total_grd_sum = 0
    
    for s in students:
        # Attendance Percentage
        s_att_count = s.attendances.count()
        s_att_pct = 100.0
        if s_att_count > 0:
            s_present = s.attendances.filter(status__in=['PRESENT', 'LATE']).count()
            s_att_pct = (s_present / s_att_count) * 100.0
        total_att_sum += s_att_pct
        
        # Grade Average
        s_grades = s.grades.all()
        s_grd_pct = 0.0
        if s_grades.exists():
            s_grd_pct = sum(g.percentage for g in s_grades) / s_grades.count()
            total_grd_sum += s_grd_pct
            graded_count += 1
            
        student_stats.append({
            'student': s,
            'attendance': round(s_att_pct, 1),
            'grade': round(s_grd_pct, 1) if s_grades.exists() else None,
            'pending_tasks': s.tasks.filter(status='PENDING').count(),
            'total_tasks': s.tasks.count()
        })
        
    avg_attendance = round(total_att_sum / total_students, 1) if total_students > 0 else 100.0
    avg_grade = round(total_grd_sum / graded_count, 1) if graded_count > 0 else 0.0
    
    context = {
        'total_students': total_students,
        'total_tasks': total_tasks,
        'completed_tasks': completed_tasks,
        'pending_tasks': pending_tasks,
        'completion_rate': completion_rate,
        'avg_attendance': avg_attendance,
        'avg_grade': avg_grade,
        'student_stats': student_stats[:5],
        'recent_notices': notices[:3],
        'recent_remarks': remarks[:5],
        'active_tab': 'dashboard',
    }
    return render(request, 'core/dashboard.html', context)



@login_required
def web_students(request):
    teacher = request.user
    query = request.GET.get('q', '')
    
    if request.user.is_superuser or request.user.is_staff:
        students = Student.objects.all()
    else:
        students = Student.objects.filter(teacher=teacher)
        
    if query:
        students = students.filter(
            Q(name__icontains=query) | 
            Q(roll_number__icontains=query) | 
            Q(grade__icontains=query)
        )
        
    if request.method == 'POST':
        name = request.POST.get('name')
        roll_number = request.POST.get('roll_number')
        grade = request.POST.get('grade')
        email = request.POST.get('email')
        guardian_name = request.POST.get('guardian_name')
        guardian_phone = request.POST.get('guardian_phone')
        
        # Get assigned teacher
        teacher_id = request.POST.get('teacher_id')
        if (request.user.is_superuser or request.user.is_staff) and teacher_id:
            assigned_teacher = get_object_or_404(User, id=teacher_id)
        else:
            assigned_teacher = teacher
            
        if Student.objects.filter(teacher=assigned_teacher, roll_number=roll_number).exists():
            messages.error(request, f"Student with roll number {roll_number} already exists for this class!")
        else:
            Student.objects.create(
                teacher=assigned_teacher,
                name=name,
                roll_number=roll_number,
                grade=grade,
                email=email,
                guardian_name=guardian_name,
                guardian_phone=guardian_phone
            )
            messages.success(request, f"Student {name} added successfully!")
            return redirect('students')

    context = {
        'students': students,
        'query': query,
        'active_tab': 'students',
        'teachers': User.objects.filter(is_superuser=False) if (request.user.is_superuser or request.user.is_staff) else None
    }
    return render(request, 'core/students.html', context)



@login_required
def web_student_detail(request, pk):
    if request.user.is_superuser or request.user.is_staff:
        student = get_object_or_404(Student, pk=pk)
    else:
        student = get_object_or_404(Student, pk=pk, teacher=teacher)
    tasks = student.tasks.all()
    attendances = student.attendances.all()
    grades = student.grades.all()
    remarks = student.behavior_remarks.all()
    
    if request.method == 'POST':
        form_type = request.POST.get('form_type')
        
        if form_type == 'task':
            title = request.POST.get('title')
            description = request.POST.get('description')
            due_date = request.POST.get('due_date')
            if title and due_date:
                Task.objects.create(student=student, title=title, description=description, due_date=due_date)
                messages.success(request, f"Task '{title}' assigned successfully!")
            else:
                messages.error(request, "Task title and due date are required.")
                
        elif form_type == 'remark':
            remark_type = request.POST.get('type')
            title = request.POST.get('title')
            description = request.POST.get('description')
            if remark_type and title:
                BehaviorRemark.objects.create(student=student, type=remark_type, title=title, description=description)
                messages.success(request, f"Behavior remark '{title}' logged successfully!")
            else:
                messages.error(request, "Remark type and title are required.")
                
        elif form_type == 'grade':
            exam_name = request.POST.get('exam_name')
            subject = request.POST.get('subject')
            obtained = request.POST.get('marks_obtained')
            max_marks = request.POST.get('max_marks')
            rem = request.POST.get('remarks', '')
            if exam_name and subject and obtained and max_marks:
                Grade.objects.create(
                    student=student, exam_name=exam_name, subject=subject,
                    marks_obtained=float(obtained), max_marks=float(max_marks), remarks=rem
                )
                messages.success(request, f"Grade for {subject} logged successfully!")
            else:
                messages.error(request, "All grade fields are required.")
                
        return redirect('student_detail', pk=student.pk)
            
    context = {
        'student': student,
        'tasks': tasks,
        'attendances': attendances,
        'grades': grades,
        'remarks': remarks,
        'active_tab': 'students',
    }
    return render(request, 'core/student_detail.html', context)


@login_required
def web_tasks(request):
    teacher = request.user
    students = Student.objects.filter(teacher=teacher)
    tasks = Task.objects.filter(student__teacher=teacher)
    
    status_filter = request.GET.get('status', 'ALL')
    if status_filter in ['PENDING', 'COMPLETED']:
        tasks = tasks.filter(status=status_filter)
        
    if request.method == 'POST':
        student_id = request.POST.get('student_id')
        title = request.POST.get('title')
        description = request.POST.get('description')
        due_date = request.POST.get('due_date')
        
        if not student_id:
            messages.error(request, "Please select a student.")
        elif not title or not due_date:
            messages.error(request, "Task title and due date are required.")
        else:
            student = get_object_or_404(Student, pk=student_id, teacher=teacher)
            Task.objects.create(student=student, title=title, description=description, due_date=due_date)
            messages.success(request, f"Task '{title}' assigned to {student.name}!")
            return redirect('tasks')
            
    context = {
        'students': students,
        'tasks': tasks,
        'status_filter': status_filter,
        'active_tab': 'tasks',
    }
    return render(request, 'core/tasks.html', context)


@login_required
def web_attendance(request):
    teacher = request.user
    students = Student.objects.filter(teacher=teacher)
    
    # Get current date or query date
    date_str = request.GET.get('date', date.today().strftime('%Y-%m-%d'))
    try:
        selected_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        selected_date = date.today()
        date_str = selected_date.strftime('%Y-%m-%d')
        
    # Get existing attendances for this date
    existing_att = Attendance.objects.filter(student__teacher=teacher, date=selected_date)
    attendance_map = {att.student_id: att for att in existing_att}
    
    if request.method == 'POST':
        # Batch save attendance
        for student in students:
            status_val = request.POST.get(f'status_{student.id}')
            remarks_val = request.POST.get(f'remarks_{student.id}', '')
            if status_val:
                Attendance.objects.update_or_create(
                    student=student,
                    date=selected_date,
                    defaults={'status': status_val, 'remarks': remarks_val}
                )
        messages.success(request, f"Attendance register updated for {selected_date}!")
        return redirect(f"/attendance/?date={date_str}")
        
    student_records = []
    for s in students:
        att = attendance_map.get(s.id)
        student_records.append({
            'student': s,
            'status': att.status if att else 'PRESENT', # default present
            'remarks': att.remarks if att else ''
        })
        
    context = {
        'student_records': student_records,
        'selected_date': selected_date,
        'date_str': date_str,
        'active_tab': 'attendance',
    }
    return render(request, 'core/attendance.html', context)


@login_required
def web_gradebook(request):
    teacher = request.user
    students = Student.objects.filter(teacher=teacher)
    grades = Grade.objects.filter(student__teacher=teacher)
    
    # List of unique exams & subjects for headers/selection
    exams = grades.values('exam_name').distinct()
    subjects = grades.values('subject').distinct()
    
    # Filter by specific exam and subject for scoresheet entry
    selected_exam = request.GET.get('exam', '')
    selected_subject = request.GET.get('subject', '')
    
    students_scores = []
    if selected_exam and selected_subject:
        # Load marks for entry
        scores_map = {g.student_id: g for g in grades.filter(exam_name=selected_exam, subject=selected_subject)}
        for s in students:
            score = scores_map.get(s.id)
            students_scores.append({
                'student': s,
                'marks_obtained': score.marks_obtained if score else '',
                'max_marks': score.max_marks if score else 100.0,
                'remarks': score.remarks if score else ''
            })
            
    if request.method == 'POST':
        action = request.POST.get('action')
        
        if action == 'create_exam':
            # Fast assign placeholder marks to initialize exam subject
            exam_name = request.POST.get('exam_name')
            subject = request.POST.get('subject')
            max_marks = float(request.POST.get('max_marks', 100))
            
            if exam_name and subject:
                # Initialize with 0 marks
                for s in students:
                    Grade.objects.get_or_create(
                        student=s, exam_name=exam_name, subject=subject,
                        defaults={'marks_obtained': 0.0, 'max_marks': max_marks}
                    )
                messages.success(request, f"Scoresheet for {exam_name} ({subject}) initialized!")
                return redirect(f"/gradebook/?exam={exam_name}&subject={subject}")
                
        elif action == 'save_scores':
            exam = request.POST.get('exam')
            subject = request.POST.get('subject')
            max_marks = float(request.POST.get('max_marks', 100))
            
            for s in students:
                obtained = request.POST.get(f'marks_{s.id}')
                remarks = request.POST.get(f'remarks_{s.id}', '')
                if obtained != '' and obtained is not None:
                    Grade.objects.update_or_create(
                        student=s, exam_name=exam, subject=subject,
                        defaults={'marks_obtained': float(obtained), 'max_marks': max_marks, 'remarks': remarks}
                    )
            messages.success(request, "Gradebook scores updated successfully!")
            return redirect(f"/gradebook/?exam={exam}&subject={subject}")
            
    context = {
        'exams': exams,
        'subjects': subjects,
        'selected_exam': selected_exam,
        'selected_subject': selected_subject,
        'students_scores': students_scores,
        'active_tab': 'gradebook',
    }
    return render(request, 'core/gradebook.html', context)


@login_required
def web_notices(request):
    teacher = request.user
    notices = Notice.objects.filter(teacher=teacher)
    
    if request.method == 'POST':
        title = request.POST.get('title')
        content = request.POST.get('content')
        if title and content:
            Notice.objects.create(teacher=teacher, title=title, content=content)
            messages.success(request, "Announcement broadcasted successfully!")
            return redirect('notices')
        else:
            messages.error(request, "Title and announcement content are required.")
            
    context = {
        'notices': notices,
        'active_tab': 'notices',
    }
    return render(request, 'core/notices.html', context)


@login_required
def web_delete_notice(request, pk):
    teacher = request.user
    notice = get_object_or_404(Notice, pk=pk, teacher=teacher)
    notice.delete()
    messages.warning(request, "Announcement deleted successfully.")
    return redirect('notices')


@login_required
def web_complete_task(request, pk):
    teacher = request.user
    task = get_object_or_404(Task, pk=pk, student__teacher=teacher)
    task.status = 'COMPLETED'
    task.save()
    messages.success(request, f"Task '{task.title}' marked as completed!")
    
    next_url = request.GET.get('next', 'tasks')
    if next_url == 'student_detail':
        return redirect('student_detail', pk=task.student.pk)
    return redirect('tasks')


@login_required
def web_delete_student(request, pk):
    if request.user.is_superuser or request.user.is_staff:
        student = get_object_or_404(Student, pk=pk)
    else:
        student = get_object_or_404(Student, pk=pk, teacher=teacher)
    student.delete()
    messages.warning(request, f"Student {student.name} and their tasks have been removed.")
    return redirect('students')


@login_required
def web_profile(request):
    user = request.user
    profile, created = TeacherProfile.objects.get_or_create(user=user)
    
    if request.method == 'POST':
        # Update user fields
        user.first_name = request.POST.get('first_name', '')
        user.last_name = request.POST.get('last_name', '')
        user.email = request.POST.get('email', '')
        user.save()
        
        # Update profile fields
        profile.phone = request.POST.get('phone', '')
        profile.class_assigned = request.POST.get('class_assigned', '')
        profile.esic_id = request.POST.get('esic_id', '')
        profile.bank_account_number = request.POST.get('bank_account_number', '')
        profile.bank_name = request.POST.get('bank_name', '')
        profile.ifsc_code = request.POST.get('ifsc_code', '')
        
        if 'profile_picture' in request.FILES:
            profile.profile_picture = request.FILES['profile_picture']
        if 'document_file' in request.FILES:
            profile.document_file = request.FILES['document_file']
            
        profile.save()
        messages.success(request, "Your profile has been updated successfully!")
        return redirect('web_profile')
        
    context = {
        'profile': profile,
        'active_tab': 'profile',
    }
    return render(request, 'core/profile.html', context)


@login_required
def web_teachers(request):
    if not (request.user.is_superuser or request.user.is_staff):
        messages.error(request, "Only Super Admins can access this page.")
        return redirect('dashboard')
        
    teachers = User.objects.all().order_by('username')
    context = {
        'teachers': teachers,
        'active_tab': 'teachers',
    }
    return render(request, 'core/teachers.html', context)


@login_required
def web_teacher_detail(request, pk):
    if not (request.user.is_superuser or request.user.is_staff):
        messages.error(request, "Only Super Admins can access this page.")
        return redirect('dashboard')
        
    teacher_user = get_object_or_404(User, pk=pk)
    profile, created = TeacherProfile.objects.get_or_create(user=teacher_user)
    
    if request.method == 'POST':
        action = request.POST.get('action')
        if action == 'adjust_leaves':
            try:
                profile.total_leaves = int(request.POST.get('total_leaves', 15))
                profile.leaves_taken = int(request.POST.get('leaves_taken', 0))
                profile.save()
                messages.success(request, f"Leaves adjusted for {teacher_user.username} successfully!")
            except ValueError:
                messages.error(request, "Invalid leaves values entered.")
        elif action == 'assign_class':
            profile.class_assigned = request.POST.get('class_assigned', '')
            profile.save()
            messages.success(request, f"Class assigned for {teacher_user.username} updated!")
        return redirect('web_teacher_detail', pk=pk)
        
    context = {
        'teacher_user': teacher_user,
        'profile': profile,
        'active_tab': 'teachers',
        'students': Student.objects.filter(teacher=teacher_user)
    }
    return render(request, 'core/teacher_detail.html', context)

